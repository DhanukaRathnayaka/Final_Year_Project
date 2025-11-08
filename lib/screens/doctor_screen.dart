import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _supabase = Supabase.instance.client;
  String? _userId;
  String? _dominantState;
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _matchingDoctors = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAndMentalState();
  }

  Future<void> _fetchUserAndMentalState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userId = user.id;
      });

      final mentalStateResponse = await _supabase
          .from('mental_state_reports')
          .select('dominant_state, confidence, created_at')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      if (mentalStateResponse != null) {
        setState(() {
          _dominantState = mentalStateResponse['dominant_state'];
        });

        await _fetchMatchingDoctors(_dominantState!);
      } else {
        setState(() {
          _errorMessage =
              'No mental state assessment found. Please complete your assessment first.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMatchingDoctors(String dominantState) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('*')
          .eq('dominant_state', dominantState)
          .order('name');

      setState(() {
        _matchingDoctors = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching doctors: $e';
      });
    }
  }

  bool _isDoctorOnline(Map<String, dynamic> doctor) {
    return doctor['avb_status'] == true;
  }

  Future<void> _startMeeting(String doctorName, String doctorId) async {
    // Simulate meeting start - you can integrate with your video call service
    final meetingUrl =
        'https://meet.jit.si/safespace-${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (await canLaunchUrl(Uri.parse(meetingUrl))) {
        await launchUrl(Uri.parse(meetingUrl));
      } else {
        _showSnackBar('Could not launch meeting', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error starting meeting: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _fetchUserAndMentalState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Your Specialist',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Personalized matches for you',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _buildDoctorsContent(),
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
            'Finding your perfect match...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Assessment Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('Check Again'),
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

  Widget _buildDoctorsContent() {
    final onlineDoctorsCount = _matchingDoctors
        .where((doctor) => _isDoctorOnline(doctor))
        .length;

    return Column(
      children: [
        // Header Card
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
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
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specialized Care',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$onlineDoctorsCount/${_matchingDoctors.length} specialists available now',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Online Status Info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Available now',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Currently unavailable',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Doctors List
        Expanded(
          child: _matchingDoctors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 16),
                  itemCount: _matchingDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _matchingDoctors[index];
                    final isOnline = _isDoctorOnline(doctor);

                    return _buildDoctorCard(doctor, isOnline);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No specialists available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please check back later for available specialists\nthat match your needs',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isOnline) {
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final email = doctor['email'] ?? 'N/A';
    final profilePicture = doctor['profilepicture'];
    final doctorId = doctor['id'].toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  backgroundImage:
                      profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture == null || profilePicture.isEmpty
                      ? Icon(
                          Icons.medical_services,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[900],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isOnline ? 'Available now' : 'Currently unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green[700] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onTap: () => _showDoctorDetails(doctor, isOnline),
          ),

          // Meeting Button for online doctors
          if (isOnline) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startMeeting(name, doctorId),
                  icon: Icon(Icons.video_call, size: 20),
                  label: Text('Start Meeting Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor, bool isOnline) {
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final email = doctor['email'] ?? 'N/A';
    final profilePicture = doctor['profilepicture'];
    final bio =
        doctor['bio'] ??
        'Specialized in providing personalized care and support.';
    final doctorId = doctor['id'].toString();

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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        backgroundImage:
                            profilePicture != null && profilePicture.isNotEmpty
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        isOnline
                            ? 'Available now - Ready for meeting'
                            : 'Currently unavailable',
                        style: TextStyle(
                          color: isOnline
                              ? Colors.green[700]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.email, color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Implement contact functionality
                        _showSnackBar('Contact feature coming soon!');
                      },
                      icon: Icon(Icons.message_outlined),
                      label: Text('Message'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isOnline
                          ? () {
                              Navigator.pop(context);
                              _startMeeting(name, doctorId);
                            }
                          : null,
                      icon: Icon(Icons.video_call),
                      label: Text(isOnline ? 'Meet Now' : 'Unavailable'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline
                            ? Colors.green[600]
                            : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
