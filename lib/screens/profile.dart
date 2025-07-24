import 'package:flutter/material.dart';
import 'package:safespace/authentication/auth_service.dart';




class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  Map<String, dynamic>? _userMetadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _userMetadata = _authService.getCurrentUserMetadata();
    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userMetadata?['avatar_url'] != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _userMetadata!['avatar_url'] as String,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: ${_authService.getCurrentUserEmail() ?? 'No email'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Name: ${_userMetadata?['name'] ?? 'No name'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${_authService.getCurrentUserId() ?? 'No ID'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _signOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}