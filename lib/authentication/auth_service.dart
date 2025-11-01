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
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'avatar_url': null, // Initialize as null
        },
      );

      // Assign patient role after successful signup
      if (response.user != null) {
        await _supabase.from('user_roles').insert({
          'user_id': response.user!.id,
          'role': 'patient', // Set role as patient
        });
      }

      return response;
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password - ONLY FOR PATIENTS
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // First, sign in with Supabase Auth
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if user has patient role
      if (response.user != null) {
        final roleResponse = await _supabase
            .from('user_roles')
            .select('role')
            .eq('user_id', response.user!.id)
            .single();

        final String userRole = roleResponse['role'] as String;
        
        // Only allow patients to login
        if (userRole != 'patient') {
          // Sign out non-patient users immediately
          await _supabase.auth.signOut();
          throw Exception('Access denied. Only patients can login through this app.');
        }
      }

      return response;
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

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if user has specific role
  Future<bool> hasRole(String role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  // Check if current user is patient
  Future<bool> isPatient() async {
    return await hasRole('patient');
  }
}