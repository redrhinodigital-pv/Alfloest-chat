-- ==============================================================================
-- ALFLOEST CHAT - SUPABASE SQL SCHEMA & RLS POLICIES
-- ==============================================================================
-- Run this entire script in your Supabase SQL Editor.
-- It creates the necessary tables, configures secure Row Level Security (RLS),
-- and enables Realtime WebSockets.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABLE CREATIONS
-- ------------------------------------------------------------------------------

-- USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username text,
    email text,
    "displayName" text,
    "photoUrl" text,
    "isOnline" boolean DEFAULT false,
    "lastSeen" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "updatedAt" timestamp with time zone DEFAULT timezone('utc'::text, now()),
    "blockedUsers" text[] DEFAULT '{}'::text[],
    "fcmToken" text
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
    "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- GROUPS TABLE
CREATE TABLE IF NOT EXISTS public.groups (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "groupName" text NOT NULL,
    "groupDescription" text,
    "createdBy" uuid REFERENCES public.users(id),
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
    "senderId" uuid REFERENCES public.users(id),
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
    mentions text[] DEFAULT '{}'::text[],
    "deletedFor" uuid[] DEFAULT '{}'::uuid[],
    "deletedForEveryone" boolean DEFAULT false,
    reactions jsonb DEFAULT '{}'::jsonb
);

-- ------------------------------------------------------------------------------
-- 2. ENABLE ROW LEVEL SECURITY (RLS)
-- ------------------------------------------------------------------------------

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 3. RLS POLICIES
-- ------------------------------------------------------------------------------

-- 
-- USERS POLICIES
--
-- Policy: Users can only read/write their own profiles.
-- (Note: If your app requires searching for other users to start chats, you may need to change 
-- the SELECT policy to allow authenticated users to read all profiles: `auth.role() = 'authenticated'`)
CREATE POLICY "Users can view their own profile" 
ON public.users FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid() = id);


-- 
-- CHATS POLICIES
--
-- Policy: Chat members only can read/update chats
CREATE POLICY "Users can view chats they belong to" 
ON public.chats FOR SELECT 
USING (auth.uid() = ANY(participants));

CREATE POLICY "Users can update chats they belong to" 
ON public.chats FOR UPDATE 
USING (auth.uid() = ANY(participants));

CREATE POLICY "Users can create chats if they are a participant" 
ON public.chats FOR INSERT 
WITH CHECK (auth.uid() = ANY(participants));


-- 
-- GROUPS POLICIES
--
-- Policy: Group members only can read/update groups
CREATE POLICY "Users can view groups they belong to" 
ON public.groups FOR SELECT 
USING (auth.uid() = ANY(members));

CREATE POLICY "Users can update groups they belong to" 
ON public.groups FOR UPDATE 
USING (auth.uid() = ANY(members));

CREATE POLICY "Users can create groups if they are a member" 
ON public.groups FOR INSERT 
WITH CHECK (auth.uid() = ANY(members));


-- 
-- MESSAGES POLICIES
--
-- Policy: Users can only read messages if they belong to the chat
-- This uses a subquery to check if the user is in the chats.participants or groups.members array
CREATE POLICY "Users can view messages in their chats" 
ON public.messages FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.chats WHERE id = "chatId" AND auth.uid() = ANY(participants)
  ) OR 
  EXISTS (
    SELECT 1 FROM public.groups WHERE id = "chatId" AND auth.uid() = ANY(members)
  )
);

-- Policy: Users can send messages only if they belong to the chat
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

-- Policy: Users can update their own messages (for reactions, deleting, editing)
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


-- ------------------------------------------------------------------------------
-- 4. ENABLE REALTIME
-- ------------------------------------------------------------------------------

-- Drop the publication if it already exists to avoid errors, then recreate
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

-- Add all tables to the realtime publication so WebSockets can broadcast changes
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.groups;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
