import 'dart:io';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/authentication/auth_service.dart';
import 'package:supabase/supabase.dart' as supabase;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userMetadata;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  bool _hideEmail = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _userMetadata = _authService.getCurrentUserMetadata();
      _avatarUrl = _userMetadata?['avatar_url'];
      _hideEmail = _userMetadata?['hide_email'] ?? false;

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      _showErrorSnackBar('Failed to load profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_isUpdating) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUpdating = true);

      // Upload to Supabase Storage
      final userId = _authService.getCurrentUserId();
      final fileExtension = image.name.split('.').last.toLowerCase();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = 'user_avatars/$userId/$fileName';

      final bytes = await image.readAsBytes();
      final contentType = 'image/$fileExtension';

      // Upload with upsert option
      await _supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: supabase.FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update user metadata
      final updatedMetadata = {...?_userMetadata, 'avatar_url': imageUrl};
      await _supabase.auth.updateUser(
        UserAttributes(data: updatedMetadata),
      );

      // Update local state immediately
      setState(() {
        _userMetadata = updatedMetadata;
        _avatarUrl = imageUrl;
      });

      _showSuccessSnackBar('Profile picture updated successfully!');
    } catch (e) {
      print('Profile picture upload error: $e');
      _showErrorSnackBar('Error updating profile picture: ${e.toString()}');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _showErrorSnackBar('Error signing out: $e');
    }
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController = TextEditingController(text: _userMetadata?['username'] ?? '');
    bool tempHideEmail = _hideEmail;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF4A9280)),
                  SizedBox(width: 8),
                  const Text('Edit Profile'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your display name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4A9280)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4A9280), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF4A9280)),
                      ),
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Hide Email'),
                      subtitle: const Text('Hide your email from public view'),
                      value: tempHideEmail,
                      onChanged: (value) {
                        setState(() {
                          tempHideEmail = value;
                        });
                      },
                      activeColor: const Color(0xFF4A9280),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) {
                      _showErrorSnackBar('Name cannot be empty');
                      return;
                    }

                    try {
                      setState(() => _isUpdating = true);
                      Navigator.of(context).pop();

                      // Update user metadata
                      await _supabase.auth.updateUser(
                        UserAttributes(data: {
                          ...?_userMetadata,
                          'username': newName,
                          'hide_email': tempHideEmail,
                        }),
                      );

                      // Update local state
                      setState(() {
                        _userMetadata = {
                          ...?_userMetadata,
                          'username': newName,
                          'hide_email': tempHideEmail,
                        };
                        _hideEmail = tempHideEmail;
                      });

                      _showSuccessSnackBar('Profile updated successfully!');
                    } catch (e) {
                      _showErrorSnackBar('Error updating profile: $e');
                    } finally {
                      setState(() => _isUpdating = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9280),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _maskEmail(String email) {
    if (email == 'No email' || !email.contains('@')) return email;
    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];
    final maskedUsername = username.length > 2
        ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
        : username;
    return '$maskedUsername@$domain';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _userMetadata?['username'] ?? 'User';
    final email = _authService.getCurrentUserEmail() ?? 'No email';
    final displayEmail = _hideEmail ? _maskEmail(email) : email;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fdfb),
      appBar: AppBar(
        title: Row(
          children: [
            if (_avatarUrl != null)
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4A9280).withOpacity(0.2),
                backgroundImage: NetworkImage(_avatarUrl!),
                onBackgroundImageError: (exception, stackTrace) {
                  // Fallback handled
                },
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9280).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LineIcons.user, color: Color(0xFF4A9280), size: 20),
              ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1a1a1a)),
                ),
                Text(
                  'Manage your account',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(username, displayEmail),
                      SizedBox(height: 24),
                      _buildProfileActions(),
                      SizedBox(height: 24),
                      _buildAccountInfo(username, displayEmail),
                      SizedBox(height: 24),
                      _buildSignOutButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(LineIcons.user, size: 48, color: Color(0xFF4A9280)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9280)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String username, String displayEmail) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile picture section
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A9280).withOpacity(0.08),
                  const Color(0xFFEAFBF5).withOpacity(0.4)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF4A9280).withOpacity(0.15),
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? const Icon(
                              LineIcons.user,
                              size: 60,
                              color: Color(0xFF4A9280),
                            )
                          : null,
                    ),
                    if (_isUpdating)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9280),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isUpdating ? null : _updateProfilePicture,
                          tooltip: 'Change profile picture',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            color: const Color(0xFF4A9280),
            onTap: _showEditProfileDialog,
          ),
          Divider(height: 1, indent: 56),
          _buildActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            color: const Color(0xFF4A9280),
            onTap: () {
              _showSuccessSnackBar('Notifications coming soon!');
            },
          ),
          Divider(height: 1, indent: 56),
          _buildActionTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            color: const Color(0xFF4A9280),
            onTap: () {
              _showSuccessSnackBar('Privacy settings coming soon!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAccountInfo(String username, String email) {
    final displayEmail = _hideEmail ? _maskEmail(email) : email;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF4A9280)),
              SizedBox(width: 8),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a1a1a),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow('Username', username),
          SizedBox(height: 12),
          _buildInfoRow('Email', displayEmail),
          SizedBox(height: 12),
          _buildInfoRow('Member Since', '2024'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A9280).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: Color(0xFF4A9280),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your account is verified and secure',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF4A9280).withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1a1a1a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        icon: Icon(Icons.logout, size: 20),
        label: Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
