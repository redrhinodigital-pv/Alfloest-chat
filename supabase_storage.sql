-- ==============================================================================
-- ALFLOEST CHAT - SUPABASE STORAGE POLICIES
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- It creates the `chat-media` bucket and applies strict RLS storage policies.
-- ==============================================================================

-- 1. Create storage buckets safely
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('chat-media', 'chat-media', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "Public Read Access for chat-media" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload media" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own media" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own media" ON storage.objects;

DROP POLICY IF EXISTS "Public Read Access for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- 3. Apply Storage RLS Policies

-- Policy: Public Read Access
CREATE POLICY "Public Read Access for chat-media"
ON storage.objects FOR SELECT USING (bucket_id = 'chat-media');

CREATE POLICY "Public Read Access for avatars"
ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- Policy: Authenticated Uploads
CREATE POLICY "Authenticated users can upload media"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'chat-media' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Policy: Update/Delete Own Files
CREATE POLICY "Users can update their own media"
ON storage.objects FOR UPDATE
USING (bucket_id = 'chat-media' AND auth.role() = 'authenticated' AND owner = auth.uid());

CREATE POLICY "Users can delete their own media"
ON storage.objects FOR DELETE
USING (bucket_id = 'chat-media' AND auth.role() = 'authenticated' AND owner = auth.uid());

CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated' AND owner = auth.uid());

CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated' AND owner = auth.uid());
