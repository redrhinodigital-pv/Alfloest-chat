import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print("Initializing Supabase...");
  await Supabase.initialize(
    url: 'https://kenhzjqhtronfnnppsei.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE',
  );
  
  final client = Supabase.instance.client;
  print("Supabase client initialized.");

  try {
    print("Fetching users...");
    final usersRes = await client.from('users').select().limit(5);
    print("Users table contents: $usersRes");
  } catch (e) {
    print("Error fetching users: $e");
  }

  try {
    print("Fetching profiles...");
    final profilesRes = await client.from('profiles').select().limit(5);
    print("Profiles table contents: $profilesRes");
  } catch (e) {
    print("Error fetching profiles: $e");
  }
}
