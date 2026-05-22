-- ==============================================================================
-- ALFLOEST CHAT - SUPABASE SQL SCHEMA & RLS POLICIES
-- ==============================================================================
-- Run this entire script in your Supabase SQL Editor.
-- It creates the necessary tables, configures secure Row Level Security (RLS),
-- and enables Realtime WebSockets.
-- ==============================================================================

-- 1. DROP THE LEGACY UNUSED TABLES AND CONSTRAINTS IF THEY EXIST
DROP TABLE IF EXISTS public.users CASCADE;

-- 2. PROFILES TABLE (Must exist before referenced by messages and groups)
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

-- CHATS TABLE (1-to-1)
CREATE TABLE IF NOT EXISTS public.chats (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    participants uuid[] NOT NULL,
    type text DEFAULT 'oneToOne',
    "lastMessage" text,
    "lastMessageTime" timestamp with time zone,
    "lastMessageSender" text,
    "unreadCount" jsonb DEFAULT '{}'::jsonb,
    "typingUsers" text[] DEFAULT '{}'::text[],
    "pinnedBy" text[] DEFAULT '{}'::text[],
    "archivedBy" text[] DEFAULT '{}'::text[],
    "favoriteBy" text[] DEFAULT '{}'::text[], -- tracks favorited chats
    "mutedBy" text[] DEFAULT '{}'::text[], -- tracks muted chats
    "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- GROUPS TABLE
CREATE TABLE IF NOT EXISTS public.groups (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "groupName" text NOT NULL,
    "groupDescription" text,
    "groupImage" text, -- Group avatar URL
    "createdBy" uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    admins uuid[] NOT NULL,
    members uuid[] NOT NULL,
    "lastMessage" text,
    "lastMessageTime" timestamp with time zone,
    "lastMessageSender" text,
    "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "chatId" uuid NOT NULL, -- Can refer to chats.id or groups.id
    "senderId" uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    "senderName" text,
    text text,
    "messageType" text DEFAULT 'text',
    status text DEFAULT 'sent',
    timestamp timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "replyTo" text,
    "replyToText" text,
    "replyToSender" text,
    "forwardedFrom" text,
    "voiceNoteUrl" text,
    "voiceNoteDuration" integer,
    "mediaUrl" text, -- Shared image, video, file URL
    "fileName" text, -- Shared file original name
    "fileSize" integer, -- Shared file size in bytes
    mentions text[] DEFAULT '{}'::text[],
    "deletedFor" uuid[] DEFAULT '{}'::uuid[],
    "deletedForEveryone" boolean DEFAULT false,
    reactions jsonb DEFAULT '{}'::jsonb
);

-- ------------------------------------------------------------------------------
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ------------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 4. RLS POLICIES
-- ------------------------------------------------------------------------------

-- PROFILES POLICIES
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON public.profiles FOR SELECT
USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- CHATS POLICIES
DROP POLICY IF EXISTS "Users can view chats they belong to" ON public.chats;
CREATE POLICY "Users can view chats they belong to" 
ON public.chats FOR SELECT 
USING (auth.uid() = ANY(participants));

DROP POLICY IF EXISTS "Users can update chats they belong to" ON public.chats;
CREATE POLICY "Users can update chats they belong to" 
ON public.chats FOR UPDATE 
USING (auth.uid() = ANY(participants));

DROP POLICY IF EXISTS "Users can create chats if they are a participant" ON public.chats;
CREATE POLICY "Users can create chats if they are a participant" 
ON public.chats FOR INSERT 
WITH CHECK (auth.uid() = ANY(participants));

-- GROUPS POLICIES
DROP POLICY IF EXISTS "Users can view groups they belong to" ON public.groups;
CREATE POLICY "Users can view groups they belong to" 
ON public.groups FOR SELECT 
USING (auth.uid() = ANY(members));

DROP POLICY IF EXISTS "Users can update groups they belong to" ON public.groups;
CREATE POLICY "Users can update groups they belong to" 
ON public.groups FOR UPDATE 
USING (auth.uid() = ANY(members));

DROP POLICY IF EXISTS "Users can create groups if they are a member" ON public.groups;
CREATE POLICY "Users can create groups if they are a member" 
ON public.groups FOR INSERT 
WITH CHECK (auth.uid() = ANY(members));

-- MESSAGES POLICIES
-- Fix Realtime Message Join Issue
-- Realtime cannot evaluate policies with subqueries/joins on tables.
-- We solve this using a Security Definer function to query membership.
CREATE OR REPLACE FUNCTION public.is_member_of_chat(chat_id uuid, user_id uuid)
RETURNS boolean
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.chats 
    WHERE id = chat_id AND user_id = ANY(participants)
  ) OR EXISTS (
    SELECT 1 FROM public.groups 
    WHERE id = chat_id AND user_id = ANY(members)
  );
END;
$$ LANGUAGE plpgsql;

DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
CREATE POLICY "Users can view messages in their chats" 
ON public.messages FOR SELECT 
USING (public.is_member_of_chat("chatId", auth.uid()));

DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
CREATE POLICY "Users can insert messages in their chats" 
ON public.messages FOR INSERT 
WITH CHECK (
  auth.uid() = "senderId" AND (
    EXISTS (
      SELECT 1 FROM public.chats WHERE id = "chatId" AND auth.uid() = ANY(participants)
    ) OR 
    EXISTS (
      SELECT 1 FROM public.groups WHERE id = "chatId" AND auth.uid() = ANY(members)
    )
  )
);

DROP POLICY IF EXISTS "Users can update messages in their chats" ON public.messages;
CREATE POLICY "Users can update messages in their chats" 
ON public.messages FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM public.chats WHERE id = "chatId" AND auth.uid() = ANY(participants)
  ) OR 
  EXISTS (
    SELECT 1 FROM public.groups WHERE id = "chatId" AND auth.uid() = ANY(members)
  )
);

-- 5. ENABLE REALTIME
-- ------------------------------------------------------------------------------

-- Safely add tables to publication ignoring "already member" errors
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore error if already a member
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore error if already a member
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.groups;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore error if already a member
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore error if already a member
  END;
END;
$$;

