import 'package:flutter/foundation.dart';

class Config {
  // Network IP for local network access
  static const String networkIp = 'localhost';
  static const String port = '8000';
  
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Web platform - try network IP first, fallback to localhost
      return 'http://$networkIp:$port';
    } else {
      // Mobile platforms - use conditional import for Platform
      return _getMobileApiUrl();
    }
  }

  // Alternative localhost URL for development
  static String get localhostApiUrl {
    if (kIsWeb) {
      return 'http://localhost:$port';
    } else {
      return _getMobileLocalhostUrl();
    }
  }

  static String _getMobileApiUrl() {
    // Use defaultTargetPlatform instead of Platform for better cross-platform support
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator/device - use network IP for real device, 10.0.2.2 for emulator
        return 'http://$networkIp:$port';
      case TargetPlatform.iOS:
        // iOS simulator/device - use network IP
        return 'http://$networkIp:$port';
      default:
        // Desktop or other platforms
        return 'http://$networkIp:$port';
    }
  }

  static String _getMobileLocalhostUrl() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator needs special localhost address
        return 'http://10.0.2.2:$port';
      case TargetPlatform.iOS:
        // iOS simulator can use localhost
        return 'http://localhost:$port';
      default:
        // Desktop or other platforms
        return 'http://localhost:$port';
    }
  }

  static const String supabaseUrl = 'https://cpuhivcyhvqayzgdvdaw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk';
}
