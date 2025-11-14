import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  String? _userId;
  String? _dominantState;
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _matchingDoctors = [];
  bool _isRequestingMeeting = false;
  List<Map<String, dynamic>> _todaysAppointments = [];
  
  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserAndMentalState();
    _fetchTodaysAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _fetchTodaysAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayDate = today.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            doctors (name, category, profilepicture, email)
          ''')
          .eq('user_id', user.id)
          .eq('date', todayDate)
          .eq('status', 'confirmed')
          .order('time', ascending: true);

      setState(() {
        _todaysAppointments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  bool _isDoctorOnline(Map<String, dynamic> doctor) {
    return doctor['avb_status'] == true;
  }

  Future<void> _requestMeeting(String doctorName, String doctorId) async {
    print('=== MEETING REQUEST START ===');
    print('Doctor: $doctorName (ID: $doctorId)');
    print('User ID: $_userId');
    print('Is requesting: $_isRequestingMeeting');
    
    if (_isRequestingMeeting) {
      print('ALREADY REQUESTING - ABORTING');
      return;
    }

    setState(() {
      _isRequestingMeeting = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('NO USER LOGGED IN');
        throw Exception('No user logged in');
      }
      print('User found: ${user.email}');

      // Get username from metadata with fallback
      final userName = user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'User';
      print('Username: $userName');

      // Insert into call_requests table
      final response = await _supabase
          .from('call_requests')
          .insert({
            'doctor_id': int.parse(doctorId),
            'user_id': user.id,
            'email': user.email ?? 'user@example.com',
            'username': userName,
            'status': 'pending', // Default status as per new table
          })
          .select();
          
      print('Call request inserted successfully: $response');

      _showSnackBar('Call request sent to $doctorName. They will review your request.', isError: false);
      print('=== CALL REQUEST COMPLETE ===');
      
    } catch (e) {
      print('ERROR REQUESTING MEETING: $e');
      _showSnackBar('Failed to schedule meeting: $e', isError: true);
    } finally {
      setState(() {
        _isRequestingMeeting = false;
      });
    }
  }

  String _generateRoomName(String userName) {
    final sanitizedName = userName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, userName.length < 10 ? userName.length : 10);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$sanitizedName-$timestamp';
  }

  void _startJitsiMeeting(String doctorName, String meetingRoom) {
    print('=== JITSI MEETING START ===');
    print('Doctor name: $doctorName');
    print('Meeting room: $meetingRoom');
    print('User info: ${_supabase.auth.currentUser?.email}');
    print('Context available: ${context != null}');
    
    try {
      final jitsiMeet = JitsiMeet();
      print('Jitsi instance created successfully');
      
      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          print("CONFERENCE JOINED: $url");
          debugPrint("Conference joined: $url");
        },
        conferenceTerminated: (url, error) {
          print("CONFERENCE TERMINATED: $url, error: $error");
          debugPrint("Conference terminated: $url, error: $error");
          // Return to appointment screen when meeting ends
          Navigator.pop(context);
        },
        conferenceWillJoin: (url) {
          print("CONFERENCE WILL JOIN: $url");
          debugPrint("Conference will join: $url");
        },
        participantJoined: (email, name, role, participantId) {
          print("PARTICIPANT JOINED: $name ($email)");
          debugPrint("Participant joined: $name ($email)");
        },
        participantLeft: (participantId) {
          print("PARTICIPANT LEFT: $participantId");
          debugPrint("Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          print("AUDIO MUTED: $muted");
          debugPrint("Audio muted: $muted");
        },
        videoMutedChanged: (muted) {
          print("VIDEO MUTED: $muted");
          debugPrint("Video muted: $muted");
        },
        readyToClose: () {
          print("READY TO CLOSE");
          debugPrint("Ready to close");
          Navigator.pop(context);
        },
      );

      var options = JitsiMeetConferenceOptions(
        room: meetingRoom,
        serverURL: "https://meet.jit.si",
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Consultation with $doctorName",
          "prejoinPageEnabled": false,
          "disableModeratorIndicator": false,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "pip.enabled": true,
          "invite.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: _supabase.auth.currentUser?.userMetadata?['username'] ?? _supabase.auth.currentUser?.email?.split('@').first ?? 'Patient',
          email: _supabase.auth.currentUser?.email ?? 'patient@example.com',
        ),
      );
      
      print('Jitsi options configured:');
      print('- Room: ${options.room}');
      print('- Server URL: ${options.serverURL}');
      print('- Subject: ${options.configOverrides!['subject']}');
      print('- User: ${options.userInfo?.displayName ?? 'Unknown'}');
      
      print('Calling jitsiMeet.join()...');
      jitsiMeet.join(options, listener);
      print('JITSI MEETING JOIN CALLED SUCCESSFULLY');
      
    } catch (e, stackTrace) {
      print('ERROR STARTING JITSI MEETING: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting meeting: $e')),
      );
    }
  }

  Future<void> _joinMeeting(Map<String, dynamic> appointment) async {
    // Use the correct field name matching doctor side: 'meeting_room' instead of 'meeting_link'
    final meetingRoom = appointment['meeting_room'] ?? appointment['meeting_link']; // Fallback for compatibility
    final doctorName = appointment['doctors']?['name'] ?? 'Doctor';
    final appointmentTime = DateTime.parse('${appointment['date']} ${appointment['time']}');
    final now = DateTime.now();

    // COMPREHENSIVE DEBUG LOGGING
    print('=== MEETING JOIN DEBUG START ===');
    print('Current time (UTC): ${now.toUtc()}');
    print('Local time: $now');
    print('Appointment time: $appointmentTime');
    print('Meeting room: $meetingRoom');
    print('Doctor name: $doctorName');
    print('User timezone: ${now.timeZoneName} (offset: ${now.timeZoneOffset.inHours}h)');
    print('Raw time difference: ${appointmentTime.difference(now).inMinutes} minutes');
    print('Appointment date: ${appointment['date']}');
    print('Appointment time string: ${appointment['time']}');
    print('Status: ${appointment['status']}');
    print('=================================');

    // Use doctor side logic: check if meeting is ready (within 10 minutes)
    final timeDifference = appointmentTime.difference(now).inMinutes;
    final isReady = timeDifference.abs() <= 10; // Match doctor side logic
    
    if (!isReady) {
      print('BLOCKED: Meeting not ready yet (${timeDifference} minutes difference)');
      _showSnackBar('Meeting is scheduled for ${_formatDateTime(appointmentTime)}. You can join within 10 minutes of the scheduled time.', isError: true);
      return;
    }

    // Check if meeting has expired (more than 50 minutes after scheduled time)
    if (now.isAfter(appointmentTime.add(Duration(minutes: 50)))) {
      print('BLOCKED: Meeting has expired (more than 50 minutes after scheduled time)');
      _showSnackBar('This meeting has expired', isError: true);
      return;
    }

    print('APPROVED: Starting Jitsi meeting - Time difference: $timeDifference minutes');
    // Start Jitsi meeting immediately
    _startJitsiMeeting(doctorName, meetingRoom);
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({
            'status': 'cancelled',
          })
          .eq('id', appointmentId);

      _showSnackBar('Appointment cancelled', isError: false);
      await _fetchTodaysAppointments();
    } catch (e) {
      _showSnackBar('Failed to cancel appointment: $e', isError: true);
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
    await _fetchTodaysAppointments();
  }

  bool _isMeetingTimeReady(String date, String time) {
    try {
      final now = DateTime.now();
      final appointmentDateTime = DateTime.parse('$date $time');
      
      final difference = appointmentDateTime.difference(now).inMinutes;
      return difference.abs() <= 10;
    } catch (e) {
      return false;
    }
  }

  bool _isAppointmentExpired(String date, String time) {
    try {
      final now = DateTime.now();
      final appointmentDateTime = DateTime.parse('$date $time');
      
      return now.isAfter(appointmentDateTime.add(const Duration(minutes: 50)));
    } catch (e) {
      return true;
    }
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 20),
                  SizedBox(width: 8),
                  Text("Today's Meetings"),
                  if (_todaysAppointments.isNotEmpty) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _todaysAppointments.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services, size: 20),
                  SizedBox(width: 8),
                  Text('Find Doctors'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodaysMeetings(),
                _buildDoctorsContent(),
              ],
            ),
    );
  }

  Widget _buildTodaysMeetings() {
    if (_todaysAppointments.isEmpty) {
      return _buildEmptyMeetingsState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _todaysAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _todaysAppointments[index];
        final doctor = appointment['doctors'] as Map<String, dynamic>? ?? {};
        return _buildAppointmentCard(appointment, doctor);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, Map<String, dynamic> doctor) {
    final date = DateTime.parse(appointment['date']);
    final time = appointment['time'].toString().substring(0, 5);
    final status = appointment['status'] ?? 'confirmed';
    final meetingRoom = appointment['meeting_room'] ?? appointment['meeting_link'] ?? ''; // Support both field names
    final doctorName = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final profilePicture = doctor['profilepicture'];
    final appointmentId = appointment['id'];
    final appointmentDateTime = DateTime.parse('${appointment['date']} ${appointment['time']}');
    final now = DateTime.now();
    final isReady = _isMeetingTimeReady(appointment['date'], appointment['time']);
    final isExpired = _isAppointmentExpired(appointment['date'], appointment['time']);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null || profilePicture.isEmpty
                  ? Icon(Icons.medical_services, color: Theme.of(context).primaryColor)
                  : null,
            ),
            title: Text(
              doctorName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(category),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Today at $time',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      _getTimeStatus(appointmentDateTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isReady)
                  SizedBox(height: 8),
                if (isReady)
                  Text(
                    'Meeting ready to start',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 12),
                Row(
                  children: [
                    if (status == 'confirmed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointmentId),
                          icon: Icon(Icons.cancel, size: 16),
                          label: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (!isExpired && isReady) ? () => _joinMeeting(appointment) : null,
                          icon: Icon(Icons.video_call, size: 16),
                          label: Text(!isExpired && isReady ? 'Join Meeting' : (isExpired ? 'Meeting Expired' : 'Not Ready')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!isExpired && isReady) ? Colors.green[600] : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'cancelled') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.cancel, size: 16),
                          label: Text('Cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeStatus(DateTime appointmentTime) {
    final now = DateTime.now();
    final difference = appointmentTime.difference(now);
    
    if (difference.inMinutes < 0) {
      final hoursAgo = difference.inHours.abs();
      if (hoursAgo == 0) {
        return 'Started ${difference.inMinutes.abs()} minutes ago';
      } else {
        return 'Started $hoursAgo hours ago';
      }
    } else if (difference.inMinutes < 60) {
      return 'Starts in ${difference.inMinutes} minutes';
    } else {
      return 'Starts in ${difference.inHours} hours';
    }
  }

  Widget _buildEmptyMeetingsState() {
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
              Icons.schedule_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Meetings Today',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Your scheduled appointments for today will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1); // Switch to doctors tab
            },
            icon: Icon(Icons.medical_services),
            label: Text('Find Doctors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsContent() {
    final onlineDoctorsCount = _matchingDoctors
        .where((doctor) => _isDoctorOnline(doctor))
        .length;

    return Column(
      children: [
        // Header Card - Fixed height content
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

        // Online Status Info - Fixed height content
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

        // Doctors List - Expand to take remaining space and scroll
        Expanded(
          child: _matchingDoctors.isEmpty
              ? _buildEmptyDoctorsState()
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

  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isOnline) {
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
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
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture == null || profilePicture.isEmpty
                      ? Icon(Icons.medical_services, color: Theme.of(context).primaryColor)
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      isOnline ? 'Available now' : 'Currently unavailable',
                      style: TextStyle(fontSize: 12, color: isOnline ? Colors.green[700] : Colors.grey[500]),
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
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).primaryColor),
            ),
            onTap: () => _showDoctorDetails(doctor, isOnline),
          ),
          if (isOnline) ...[
            Divider(height: 1),
            _buildMeetingButton(isOnline, name, doctorId),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingButton(bool isOnline, String doctorName, String doctorId) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isOnline && !_isRequestingMeeting
              ? () => _requestMeeting(doctorName, doctorId)
              : null,
          icon: _isRequestingMeeting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Icon(Icons.schedule, size: 20),
          label: _isRequestingMeeting ? Text('Requesting...') : Text('Schedule Meeting'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isOnline && !_isRequestingMeeting ? Theme.of(context).primaryColor : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.psychology_outlined, size: 48, color: Colors.orange),
            ),
            SizedBox(height: 16),
            Text('Assessment Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('Check Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDoctorsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[400]),
          ),
          SizedBox(height: 16),
          Text('No specialists available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showDoctorDetails(Map<String, dynamic> doctor, bool isOnline) {
    final name = doctor['name'] ?? 'Dr. Unknown';
    final category = doctor['category'] ?? 'General';
    final email = doctor['email'] ?? 'N/A';
    final profilePicture = doctor['profilepicture'];
    final bio = doctor['bio'] ?? 'Specialized in providing personalized care and support.';
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
            // Header - Fixed height section
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor.withOpacity(0.1), Theme.of(context).primaryColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        backgroundImage: profilePicture != null && profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                        child: profilePicture == null || profilePicture.isEmpty
                            ? Icon(Icons.medical_services, size: 40, color: Theme.of(context).primaryColor)
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
                  Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(category, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        isOnline ? 'Available now' : 'Currently unavailable',
                        style: TextStyle(color: isOnline ? Colors.green[700] : Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(bio, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                    SizedBox(height: 24),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.email, color: Colors.blue, size: 20),
                      ),
                      title: Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      subtitle: Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[900], fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed action buttons section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSnackBar('Contact feature coming soon!'),
                      icon: Icon(Icons.message_outlined),
                      label: Text('Message'),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isOnline && !_isRequestingMeeting ? () {
                        Navigator.pop(context);
                        _requestMeeting(name, doctorId);
                      } : null,
                      icon: _isRequestingMeeting
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Icon(Icons.schedule),
                      label: _isRequestingMeeting ? Text('Requesting...') : Text('Schedule Meeting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline && !_isRequestingMeeting ? Theme.of(context).primaryColor : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}