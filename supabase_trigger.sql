-- ==============================================================================
-- ALFLOEST CHAT - AUTO PROFILE TRIGGER FOR USER SIGN-UP
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- It automatically provisions a record in the `profiles` table the moment 
-- a new user authenticates via Supabase Auth.
-- ==============================================================================

-- 1. Create the `profiles` table (if it doesn't exist already)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username text UNIQUE NOT null,
  email text NOT null,
  display_name text,
  avatar_url text,
  bio text DEFAULT '',
  is_online boolean DEFAULT false,
  last_seen timestamp with time zone DEFAULT timezone('utc'::text, now()),
  dark_mode boolean DEFAULT true,
  hide_online boolean DEFAULT false,
  hide_last_seen boolean DEFAULT false,
  hide_email boolean DEFAULT true,
  blocked_users text[] DEFAULT '{}'::text[],
  fcm_token text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT null,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT null
);

-- 2. Enable Row Level Security (RLS) on the profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for profiles
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON public.profiles FOR SELECT
USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- 4. Create the Trigger Function
-- This function extracts user metadata (like username, display_name and avatar_url) 
-- and auto-inserts them into our public.profiles table.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 1;
BEGIN
  -- Extract base username and force to lowercase
  base_username := LOWER(COALESCE(NEW.raw_user_meta_data->>'username', NEW.raw_user_meta_data->>'user_name', split_part(NEW.email, '@', 1)));
  -- Fallback if empty/null
  IF base_username IS NULL OR base_username = '' THEN
    base_username := 'user_' || SUBSTRING(NEW.id::TEXT, 1, 8);
  END IF;
  
  final_username := base_username;

  -- Resolve username conflicts by appending a counter
  WHILE EXISTS(SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
    final_username := base_username || counter::TEXT;
    counter := counter + 1;
  END LOOP;

  INSERT INTO public.profiles (id, username, email, display_name, avatar_url, hide_email)
  VALUES (
    NEW.id,
    final_username,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    true
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Safe guard: never crash the user signup transaction
  RETURN NEW;
END;
$$;

-- 5. Attach the Trigger to the `auth.users` table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
