import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email, password, and username
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username, // Stores username in user_metadata
        },
      );
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _supabase.auth.currentSession != null;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Get current user metadata
  Map<String, dynamic>? getCurrentUserMetadata() {
    return _supabase.auth.currentUser?.userMetadata;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw e; // Just rethrow the caught exception
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}