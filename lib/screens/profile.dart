import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/authentication/auth_service.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userMetadata;
  bool _isLoading = true;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _userMetadata = _authService.getCurrentUserMetadata();
    _avatarUrl = _userMetadata?['avatar_url'];
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      // Upload to Supabase Storage
      final userId = _authService.getCurrentUserId();
      final fileExtension = image.name.split('.').last;
      final filePath = 'profile_pictures/$userId/profile.$fileExtension';

      await _supabase.storage
          .from('avatars')
          .upload(filePath, (await image.readAsBytes()) as File);

      // Get public URL
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...?_userMetadata,
            'avatar_url': imageUrl,
          },
        ),
      );

      // Refresh UI
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _userMetadata?['username'] ?? 'User';
    final email = _authService.getCurrentUserEmail() ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false, // Removes back button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _updateProfilePicture,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? Text(
                                    username[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () {
                            // Handle invite a friend
                          },
                          child: const Text('Invite a friend'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Personal Information Section
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildListTile(
                    title: 'Mental Health Goals',
                    onTap: () {},
                  ),
                  _buildListTile(
                    title: 'Mood and Activity',
                    onTap: () {},
                  ),
                  _buildListTile(
                    title: 'Saved Resources',
                    onTap: () {},
                  ),
                  _buildListTile(
                    title: 'Help and Support',
                    onTap: () {},
                  ),
                  _buildListTile(
                    title: 'Logout',
                    onTap: _signOut,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildListTile({
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}