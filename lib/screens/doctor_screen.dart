import 'dart:convert';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? assignedDoctor;
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Add a small delay to ensure Supabase is initialized
    Future.delayed(Duration(milliseconds: 500), _fetchDoctor);
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

  Future<void> _fetchDoctor() async {
    if (isRefreshing) return;

    setState(() {
      if (!isLoading) isRefreshing = true;
      errorMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          assignedDoctor = null;
          errorMessage = '⚠️ Please log in to see your assigned doctor.';
          isLoading = false;
          isRefreshing = false;
        });
        return;
      }

      // Call your backend API
      final response = await http.post(
        Uri.parse("${Config.apiBaseUrl}/recommend"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${user.id}",
        },
        body: jsonEncode({"user_id": user.id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data["assigned_doctor"] != null) {
            assignedDoctor = data["assigned_doctor"];
            errorMessage = '';
          } else {
            assignedDoctor = null;
            errorMessage =
                data["error"] ??
                "No doctor assigned yet. This could be because your mental state assessment is pending or no matching doctor is available.";
          }
          isLoading = false;
          isRefreshing = false;
        });

        // Start animations if we have a doctor
        if (assignedDoctor != null) {
          _fadeController.forward();
          _slideController.forward();
        }
      } else {
        setState(() {
          assignedDoctor = null;
          errorMessage =
              "Failed to fetch doctor information (${response.statusCode}). Please check your internet connection and try again.";
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        assignedDoctor = null;
        errorMessage =
            "Connection error. Could not connect to the server. Please check your internet connection and try again.";
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_services,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Doctor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Professional care',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        actions: [
          IconButton(
            icon: isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: isRefreshing ? null : _fetchDoctor,
            tooltip: 'Refresh doctor info',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage.isNotEmpty
          ? _buildErrorState()
          : _buildDoctorInfo(),
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.medical_services,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Finding the right doctor for you...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No Doctor Assigned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDoctor,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Navigate to chatbot to start conversation
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: Icon(Icons.chat_bubble_outline),
              label: Text('Start Conversation'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    if (assignedDoctor == null) {
      return _buildErrorState();
    }

    final doctor = assignedDoctor!;
    final name = doctor['name'] ?? 'Dr. Unknown';
    final email = doctor['email'] ?? 'N/A';
    final phone = doctor['phone'] ?? 'N/A';
    final category = doctor['category'] ?? 'General';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Doctor Profile Card
              Container(
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
                    // Header with avatar
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.medical_services,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Mental Health Specialist',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contact Information
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildContactItem(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 16),
                          _buildContactItem(
                            icon: Icons.phone_outlined,
                            title: 'Phone',
                            value: phone,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _contactDoctor('email', email),
                                  icon: Icon(
                                    Icons.email,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  label: Text(
                                    'Send Email',
                                    style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.8)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _contactDoctor('phone', phone),
                                  icon: Icon(
                                    Icons.phone,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  label: Text(
                                    'Call',
                                    style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.8)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Additional Information
              Container(
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
                        Icon(Icons.info_outline, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Text(
                          'About Your Doctor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dr. $name is a qualified mental health professional. They have been carefully matched to your needs based on your mental state assessment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Feel free to reach out anytime. Your doctor is here to support your mental health journey.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _contactDoctor(String method, String contact) {
    if (contact == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contact information not available'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show a confirmation dialog for calm UX before taking action
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                method == 'email' ? Icons.email : Icons.phone,
                color: method == 'email' ? Colors.blue[600] : Colors.green[600],
              ),
              const SizedBox(width: 8),
              Text(method == 'email' ? 'Contact by Email' : 'Contact by Phone'),
            ],
          ),
          content: Text(
            method == 'email'
                ? 'Would you like to copy the email address to clipboard?'
                : 'Would you like to copy the phone number to clipboard?',
            style: const TextStyle(height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: method == 'email'
                    ? Colors.blue[600]
                    : Colors.green[600],
              ),
              child: const Text('Copy'),
              onPressed: () async {
                // Copy raw contact to clipboard
                await Clipboard.setData(ClipboardData(text: contact));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          method == 'email' ? Icons.email : Icons.phone,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            method == 'email'
                                ? 'Email copied to clipboard'
                                : 'Phone number copied to clipboard',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: method == 'email'
                        ? Colors.blue[600]
                        : Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}