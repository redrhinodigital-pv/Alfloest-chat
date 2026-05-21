# Alfloest Chat



1. C
   ```bash
   git clone https://github.com/redrhinodigital-pv/Alfloest-chat.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Alfloest-chat
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Database Setup

To ensure the authentication architecture and search functionality works perfectly, execute the following SQL in your Supabase SQL Editor to provision the required `profiles` table and its security policies:

```sql
-- Drop any old tables
drop table if exists public.profiles cascade;

-- Create the profiles table using 'id' as primary key
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text unique not null,
  email text not null,
  display_name text,
  phone text,
  avatar_url text,
  bio text,
  is_online boolean default false,
  last_seen timestamp with time zone,
  dark_mode boolean default true,
  hide_online boolean default false,
  hide_last_seen boolean default false,
  blocked_users text[] default '{}',
  fcm_token text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone." on public.profiles
  for select using (true);

create policy "Users can insert their own profile." on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on public.profiles
  for update using (auth.uid() = id);
```
