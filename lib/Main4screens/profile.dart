import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:safespace/Authentication/welcome_screen.dart'; // For storing images

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String? _profileImageUrl; // URL from Firebase Storage
  String? _username;
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc.data()?['username'] ?? 'User';
            _email = user.email; // Get email from Auth
            _profileImageUrl = userDoc.data()?['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _username = 'User';
            _email = user.email;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${user.uid}.jpg'); // Store with user ID

    try {
      await storageRef.putFile(_profileImage!);
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': downloadURL});

      setState(() {
        _profileImageUrl = downloadURL;
        _profileImage = null; // Clear local file
      });
    } catch (e) {
      print('Error uploading image: $e');
      // Handle error (e.g., show a snackbar)
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _username);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                onChanged: (value) {
                  _username = value; // Update locally
                },
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                enabled: false, // Typically you don't edit email here
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && _username != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'username': _username});
                  setState(() {}); // Rebuild to show updated username
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the welcome screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()), // Replace with your welcome screen
      );
    } catch (e) {
      print('Error signing out: $e');
      // Handle logout error (e.g., show a snackbar)
    }
  }

  void _showFullScreenPopup(String label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Here is the content related to $label.",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Info
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : const AssetImage('assets/profile.jpg'),
                          child: _profileImageUrl == null
                              ? const Icon(Icons.camera_alt,
                                  size: 30, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username ?? 'User',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              _email ?? 'No email',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _editProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.facebook, color: Colors.blue),
                      SizedBox(width: 10),
                      Icon(Icons.alternate_email, color: Colors.red),
                      SizedBox(width: 10),
                      Icon(Icons.g_mobiledata, color: Colors.blue),
                      SizedBox(width: 10),
                      Icon(Icons.apple, color: Colors.black),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Invite a friend'),
                  ),

                  const SizedBox(height: 20),

                  // Options list
                  Expanded(
                    child: ListView(
                      children: [
                        ProfileOptionTile(
                          icon: Icons.description,
                          label: 'Personal Information',
                          onTap: () =>
                              _showFullScreenPopup('Personal Information'),
                        ),
                        ProfileOptionTile(
                          icon: Icons.track_changes,
                          label: 'Mental Health Goals',
                          onTap: () =>
                              _showFullScreenPopup('Mental Health Goals'),
                        ),
                        ProfileOptionTile(
                          icon: Icons.mood,
                          label: 'Mood and Activity',
                          onTap: () => _showFullScreenPopup('Mood and Activity'),
                        ),
                        ProfileOptionTile(
                          icon: Icons.bookmark_added,
                          label: 'Saved Resources',
                          onTap: () =>
                              _showFullScreenPopup('Saved Resources'),
                        ),
                        ProfileOptionTile(
                          icon: Icons.support_agent,
                          label: 'Help and Support',
                          onTap: () => _showFullScreenPopup('Help and Support'),
                        ),
                        ProfileOptionTile(
                          icon: Icons.logout,
                          label: 'Logout',
                          isLogout: true,
                          onTap: _logout, // Call the logout function
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLogout;
  final VoidCallback onTap;

  const ProfileOptionTile({
    Key? key,
    required this.icon,
    required this.label,
    this.isLogout = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isLogout ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

