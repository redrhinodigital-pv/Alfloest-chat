import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/hive_service.dart';
import 'app.dart';

/// Entry point — initializes Supabase, Hive, and runs the app
Future<void> main() async {
  // Ensure Flutter bindings are initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kenhzjqhtronfnnppsei.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE',
  );

  // Initialize Hive local database for local caching (like dark theme)
  await HiveService.init();

  // Run the app wrapped in Riverpod's ProviderScope for state management
  runApp(const ProviderScope(child: AlfloestApp()));
}
