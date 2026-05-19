-- ==============================================================================
-- ALFLOEST CHAT - SUPABASE STORAGE POLICIES
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- It creates the `chat-media` bucket and applies strict RLS storage policies.
-- ==============================================================================

-- 1. Create the bucket (or update it if it exists)
-- This automatically restricts uploads to specific image and audio MIME types
-- and sets the bucket to be publicly readable (for generating public URLs).
INSERT INTO storage.buckets (id, name, public, allowed_mime_types)
VALUES (
  'chat-media', 
  'chat-media', 
  true, 
  ARRAY[
    'image/jpeg', 
    'image/png', 
    'image/gif', 
    'image/webp', 
    'audio/aac', 
    'audio/mpeg', 
    'audio/mp4', 
    'audio/wav', 
    'audio/ogg'
  ]
)
ON CONFLICT (id) DO UPDATE SET 
  public = true, 
  allowed_mime_types = ARRAY[
    'image/jpeg', 
    'image/png', 
    'image/gif', 
    'image/webp', 
    'audio/aac', 
    'audio/mpeg', 
    'audio/mp4', 
    'audio/wav', 
    'audio/ogg'
  ];

-- 2. Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to prevent conflicts if re-running
DROP POLICY IF EXISTS "Public Read Access for chat-media" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload media" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own media" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own media" ON storage.objects;

-- 4. Create Policies

-- Policy: Public Read Access
-- Anyone can view/download media from the 'chat-media' bucket
CREATE POLICY "Public Read Access for chat-media"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat-media');

-- Policy: Authenticated Uploads
-- Only logged-in users can upload files. The owner is automatically bound to the user's UUID.
CREATE POLICY "Authenticated users can upload media"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-media' AND
  auth.role() = 'authenticated'
);

-- Policy: Update Own Media
-- Users can only modify/overwrite media files that they originally uploaded
CREATE POLICY "Users can update their own media"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'chat-media' AND
  auth.role() = 'authenticated' AND
  owner = auth.uid()
);

-- Policy: Delete Own Media
-- Users can only delete media files that they originally uploaded
CREATE POLICY "Users can delete their own media"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-media' AND
  auth.role() = 'authenticated' AND
  owner = auth.uid()
);
