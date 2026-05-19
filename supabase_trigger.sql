-- ==============================================================================
-- ALFLOEST CHAT - AUTO PROFILE TRIGGER FOR GOOGLE SIGN-IN
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- It automatically provisions a record in the `profiles` table the moment 
-- a new user authenticates via Supabase Auth (Google Sign-In).
-- ==============================================================================

-- 1. Create the `profiles` table (if it doesn't exist already)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username text,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2. Enable Row Level Security (RLS) on the new table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create generic RLS policies for profiles (Adjust if necessary)
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON public.profiles FOR SELECT
USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- 4. Create the Trigger Function
-- This function extracts the Google user metadata (like full_name and avatar_url) 
-- and auto-inserts them into our public.profiles table.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    -- Extract username from email (e.g. john.doe@gmail.com -> john.doe) if username isn't explicitly provided
    COALESCE(NEW.raw_user_meta_data->>'user_name', split_part(NEW.email, '@', 1)),
    -- Extract Google's full_name
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    -- Extract Google's avatar_url
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$;

-- 5. Attach the Trigger to the `auth.users` table
-- Ensure we don't duplicate the trigger if this script is run multiple times
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
