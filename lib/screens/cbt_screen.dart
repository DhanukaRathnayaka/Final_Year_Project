import 'package:flutter/material.dart';
import '../services/exercise_service.dart';

class CBTExerciseScreen extends StatefulWidget {
  const CBTExerciseScreen({Key? key}) : super(key: key);

  @override
  State<CBTExerciseScreen> createState() => _CBTExerciseScreenState();
}

class _CBTExerciseScreenState extends State<CBTExerciseScreen> {
  late Future<List<Exercise>> _allExercisesFuture;
  Map<String, dynamic> _userStats = {
    'completed_today': 0,
    'total_duration': 0,
    'weekly_average': 0.0,
    'streak': 0,
  };

  @override
  void initState() {
    super.initState();
    _allExercisesFuture = _loadAllExercises();
    _loadUserStats();
  }

  Future<List<Exercise>> _loadAllExercises() async {
    // Fetch all exercises from all categories
    try {
      final categories = await ExerciseService.fetchCategories();
      List<Exercise> allExercises = [];

      for (var category in categories) {
        final exercises = await ExerciseService.fetchExercisesByCategory(
          category.id,
        );
        allExercises.addAll(exercises);
      }

      return allExercises;
    } catch (e) {
      print('Error loading exercises: $e');
      return [];
    }
  }

  void _loadUserStats() async {
    // Replace 'user-id' with actual user ID from your auth system
    final stats = await ExerciseService.getUserStats('user-id');
    if (mounted) {
      setState(() {
        _userStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFB),
      body: SafeArea(
        child: FutureBuilder<List<Exercise>>(
          future: _allExercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final exercises = snapshot.data!;
            return Column(
              children: [
                // Header Section
                _buildHeaderSection(),

                // Quick Stats Bar
                _buildStatsSection(context),

                // Exercises List
                Expanded(child: _buildExercisesList(context, exercises)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4A9280).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Color(0xFF4A9280),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "All Exercises",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Browse all available wellness exercises",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        constraints: BoxConstraints(
          // Use a portion of screen height to avoid overflow on small devices
          maxHeight: MediaQuery.of(context).size.height * 0.17,
        ),
        // Make the container responsive — avoid fixed height to prevent
        // bottom overflow on small screens. The padding and content define
        // its size.
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A9280).withOpacity(0.08),
              const Color(0xFFE8F4F0).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4A9280).withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              '${_userStats['completed_today'] ?? 0}',
              'Completed Today',
              Icons.check_circle_outline,
              const Color(0xFF52B788),
            ),
            _buildStatCard(
              '${_userStats['total_duration'] ?? 0} min',
              'Total Duration',
              Icons.schedule,
              const Color(0xFF4A9280),
            ),
            _buildStatCard(
              '${(_userStats['weekly_average'] ?? 0.0).toStringAsFixed(1)}',
              'Avg/Week',
              Icons.trending_up,
              const Color(0xFFFFB703),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context, List<Exercise> exercises) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ListView.builder(
        // Add bottom padding so the list doesn't get covered or overflow
        // when additional content (e.g., bottom bar) is shown. We use a
        // context-aware bottom padding here so it's responsive to the
        // device's safe area (home indicator / gesture bar).
        padding: EdgeInsets.fromLTRB(
          16.0,
          0.0,
          16.0,
          16.0 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(context, exercise);
        },
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF2D2D2D)),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9280)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading exercises...',
            style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allExercisesFuture = _loadAllExercises();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9280),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Check if it's a URL or asset path
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4A9280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9280)),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }

    // Asset image
    return Image.asset(
      imagePath,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9280).withOpacity(0.2),
            const Color(0xFF4A9280).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.play_circle_outline,
        color: Color(0xFF4A9280),
        size: 28,
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseChatScreen(
              exercise: exercise,
              categoryName: exercise.category,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF0F8F5).withOpacity(0.4)],
          ),
          border: Border.all(
            color: const Color(0xFF4A9280).withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A9280).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildExerciseImage(exercise.categoryImagePath),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Duration and Category Row
                  Row(
                    children: [
                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9280).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF4A9280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              exercise.duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A9280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Category Badge
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              exercise.category,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getCategoryColor(exercise.category),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF4A9280).withOpacity(0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'relaxation':
        return const Color(0xFF4A9280);
      case 'sleep support':
        return const Color(0xFF6B5B95);
      case 'personal growth':
        return const Color(0xFF88D498);
      default:
        return const Color(0xFF4A9280);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No exercises available',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check back later',
            style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ExerciseChatScreen extends StatefulWidget {
  final Exercise exercise;
  final String categoryName;

  const ExerciseChatScreen({
    Key? key,
    required this.exercise,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ExerciseChatScreen> createState() => _ExerciseChatScreenState();
}

class _ExerciseChatScreenState extends State<ExerciseChatScreen> {
  final List<ChatMessage> _conversation = [];
  bool _exerciseCompleted = false;
  final ScrollController _scrollController = ScrollController();
  int _startTime = 0;
  int _currentStep = 0;
  int _totalSteps = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _initializeChat();
  }

  void _initializeChat() {
    // Set total steps from chat flow
    _totalSteps = widget.exercise.chatFlow.length;

    // Start with a welcoming introduction message
    setState(() {
      _conversation.add(
        ChatMessage(
          message:
              'Welcome to ${widget.exercise.name}! 🌟\n\nTake a deep breath and get comfortable. This exercise will guide you through simple, mindful steps to support your mental wellness.\n\nReady to begin?',
          isUser: false,
          options: ['Let\'s Start'],
        ),
      );
      _currentStep = 0;
    });
    _scrollToEnd();
  }

  void _onOptionSelected(String option) {
    setState(() {
      _conversation.add(
        ChatMessage(message: option, isUser: true, options: []),
      );
    });
    _scrollToEnd();

    // Show next step after typing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Handle "Let's Start" option to begin exercise
        if (option == 'Let\'s Start' && widget.exercise.chatFlow.isNotEmpty) {
          setState(() {
            _conversation.add(widget.exercise.chatFlow[0]);
            _currentStep = 1;
          });
          _scrollToEnd();
        }
        // Check if there are more steps in the chat flow
        else if (_currentStep < widget.exercise.chatFlow.length) {
          setState(() {
            _conversation.add(widget.exercise.chatFlow[_currentStep]);
            _currentStep++;
          });
          _scrollToEnd();
        } else {
          // Completed all messages
          if (!_exerciseCompleted &&
              option != 'Done' &&
              option != 'Exit' &&
              option != 'OK' &&
              option != 'Sleep') {
            _completeExercise();
          }
        }
      }
    });

    // Handle completion options
    if (option == 'Done' ||
        option == 'Exit' ||
        option == 'OK' ||
        option == 'Sleep' ||
        option == 'Finish' ||
        option == 'Complete') {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _completeExercise();
        }
      });
    }
  }

  void _completeExercise() {
    if (!_exerciseCompleted) {
      setState(() {
        _exerciseCompleted = true;
      });
      _logCompletion();
    }
  }

  void _logCompletion() {
    final duration =
        (DateTime.now().millisecondsSinceEpoch - _startTime) ~/ 1000;
    ExerciseService.logExerciseCompletion(
      userId: 'user-id', // Replace with actual user ID
      exerciseId: widget.exercise.id,
      duration: duration,
    );
  }

  void _scrollToEnd({Duration duration = const Duration(milliseconds: 300)}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4A9280).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF4A9280),
                size: 16,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF4A9280)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 10),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF4A9280),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A9280)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          if (!_exerciseCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of $_totalSteps',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4A9280).withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_currentStep / (_totalSteps > 0 ? _totalSteps : 1) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4A9280).withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalSteps > 0 ? _currentStep / _totalSteps : 0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF4A9280).withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A9280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_conversation[index]);
              },
            ),
          ),
          if (_exerciseCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF4A9280).withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF52B788),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Exercise Completed!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9280),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Back to Exercises'),
                    ),
                  ),
                ],
              ),
            )
          else if (_conversation.isNotEmpty &&
              _conversation.last.options.isNotEmpty)
            _buildOptions(_conversation.last.options)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildOptions(List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9280).withOpacity(0.08),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF4A9280).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _onOptionSelected(opt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A9280),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF4A9280),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
