import 'dart:convert';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? assignedDoctor;
  List<Map<String, dynamic>> allDoctors = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';
  Set<String> requestedAppointments = {};

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
    Future.delayed(Duration(milliseconds: 500), () {
      _fetchDoctor();
      _fetchAllDoctors();
      _fetchPendingAppointments();
    });
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
        });
      }
    } catch (e) {
      setState(() {
        assignedDoctor = null;
        errorMessage =
            "Connection error. Could not connect to the server. Please check your internet connection and try again.";
      });
    }
  }

  Future<void> _fetchAllDoctors() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch all doctors from Supabase
      final response = await Supabase.instance.client
          .from('doctors')
          .select('*')
          .order('name');

      if (response.isNotEmpty) {
        // Filter out doctors with invalid IDs (non-integer or null)
        final validDoctors = response.where((doctor) {
          final id = doctor['id'];
          final isValid = id != null && id is int;
          if (!isValid) {
            print('Found doctor with invalid ID: $id'); // Debug log
          }
          return isValid;
        }).toList();
        
        setState(() {
          allDoctors = List<Map<String, dynamic>>.from(validDoctors);
        });
      }
    } catch (e) {
      print('Error fetching all doctors: $e');
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _fetchPendingAppointments() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch user's pending appointments
      final response = await Supabase.instance.client
          .from('pending_appointments')
          .select('doctor_id')
          .eq('user_id', user.id)
          .eq('status', 'pending');

      if (response.isNotEmpty) {
        setState(() {
          requestedAppointments = Set<String>.from(
            response.map((appointment) => (appointment['doctor_id'] ?? '').toString()),
          ).where((id) => id.isNotEmpty).toSet();
        });
      }
    } catch (e) {
      print('Error fetching pending appointments: $e');
    }
  }

  Future<void> _requestAppointment(String doctorId, String doctorName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to request an appointment'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate doctor ID format
      final doctorIdInt = int.tryParse(doctorId);
      if (doctorIdInt == null) {
        print('Invalid integer ID format: $doctorId'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid doctor ID format. Please contact support.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Insert into pending_appointments table
      await Supabase.instance.client
          .from('pending_appointments')
          .insert({
        'user_id': user.id,
        'doctor_id': doctorId,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        requestedAppointments.add(doctorId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment requested with Dr. $doctorName'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error requesting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request appointment. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    await _fetchDoctor();
    await _fetchAllDoctors();
    await _fetchPendingAppointments();
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
            onPressed: isRefreshing ? null : _refreshData,
            tooltip: 'Refresh doctor info',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage.isNotEmpty && assignedDoctor == null
          ? _buildErrorState()
          : _buildDoctorContent(),
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
              onPressed: _refreshData,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorContent() {
    return Column(
      children: [
        // Recommended Doctor Section
        if (assignedDoctor != null) ...[
          _buildRecommendedDoctor(),
          Divider(height: 1, color: Colors.grey[300]),
        ],
        
        // All Doctors Section
        Expanded(
          child: _buildAllDoctors(),
        ),
      ],
    );
  }

  Widget _buildRecommendedDoctor() {
    final doctor = assignedDoctor!;
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final profilePicture = doctor['profilepicture'];
    final doctorId = doctor['id'].toString();
    final hasRequested = requestedAppointments.contains(doctorId);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recommended Doctor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : null,
                      child: profilePicture == null || profilePicture.isEmpty
                          ? Icon(
                              Icons.medical_services,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Best Match for You',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: hasRequested
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: Icon(Icons.check_circle, size: 20),
                            label: Text('Appointment Requested'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _requestAppointment(doctorId, name),
                            icon: Icon(Icons.calendar_today, size: 20),
                            label: Text('Request Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoctors() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: Colors.grey[700], size: 20),
              SizedBox(width: 8),
              Text(
                'All Available Doctors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              Spacer(),
              Text(
                '${allDoctors.length} doctors',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: allDoctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No doctors available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 16),
                  itemCount: allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = allDoctors[index];
                    final name = doctor['name'] ?? 'Dr. Unknown';
                    final category = doctor['category'] ?? 'General';
                    final profilePicture = doctor['profilepicture'];
                    final doctorId = doctor['id'].toString();
                    final isRecommended = assignedDoctor != null && 
                        assignedDoctor!['id'] == doctor['id'];
                    final hasRequested = requestedAppointments.contains(doctorId);

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: isRecommended
                            ? Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                width: 2,
                              )
                            : null,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                              ? NetworkImage(profilePicture)
                              : null,
                          child: profilePicture == null || profilePicture.isEmpty
                              ? Icon(
                                  Icons.medical_services,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                        subtitle: Text(
                          category,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: hasRequested
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  'Requested',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              )
                            : isRecommended
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber),
                                    ),
                                    child: Text(
                                      'Your Doctor',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                        onTap: () {
                          _showDoctorDetails(doctor);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final email = doctor['email'] ?? 'N/A';
    final phone = doctor['phone'] ?? 'N/A';
    final profilePicture = doctor['profilepicture'];
    final doctorId = doctor['id'].toString();
    final hasRequested = requestedAppointments.contains(doctorId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Header
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                        ? NetworkImage(profilePicture)
                        : null,
                    child: profilePicture == null || profilePicture.isEmpty
                        ? Icon(
                            Icons.medical_services,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
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
                ],
              ),
            ),

            // Contact Info
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: email,
                    ),
                    SizedBox(height: 16),
                    _buildDetailItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: phone,
                    ),
                    SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _contactDoctor('email', email),
                            icon: Icon(Icons.email, size: 20),
                            label: Text('Send Email'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: hasRequested
                              ? OutlinedButton.icon(
                                  onPressed: null,
                                  icon: Icon(Icons.check_circle, size: 20),
                                  label: Text('Appointment Requested'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _requestAppointment(doctorId, name);
                                  },
                                  icon: Icon(Icons.calendar_today, size: 20),
                                  label: Text('Request Appointment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
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
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
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

  void _contactDoctor(String method, String contact) async {
    if (method == 'email' && contact == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email not available for this doctor'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final Uri uri;
    if (method == 'email') {
      uri = Uri.parse('mailto:$contact');
    } else {
      uri = Uri.parse('https://meet.google.com');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  method == 'email' ? Icons.email : Icons.video_call,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    method == 'email'
                        ? 'Unable to open email app'
                        : 'Unable to open Google Meet',
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                method == 'email' ? Icons.email : Icons.video_call,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  method == 'email'
                      ? 'Unable to open email app'
                      : 'Unable to open Google Meet',
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
    }
  }
}