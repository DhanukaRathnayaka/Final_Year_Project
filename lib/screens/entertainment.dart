import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safespace/screens/cbt_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/screens/media_player_screen.dart';



class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen>
    with SingleTickerProviderStateMixin {
  // APP ACCENT COLOR: change this single constant to update the
  // primary/brand green used on this screen. Replacing Theme.of(context)
  // primaryColor usage with this makes the screen self-contained.
  // Pick any green you like (hex format 0xFFRRGGBB).
  static const Color kAccentGreen = Color(0xFF10A98E);

  List<Map<String, dynamic>> entertainmentItems = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meditation', 'Music Track', 'Video'];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ✅ 3 tabs now
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadData();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (_tabController.index == 0) {
      await fetchAllEntertainmentContent();
    } else if (_tabController.index == 1) {
      await fetchRecommendedEntertainmentContent();
    } else if (_tabController.index == 2) {
      // ✅ Navigate to CBT Exercise screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening CBT Exercises...'),
          duration: Duration(seconds: 1),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>  CBTExerciseScreen(),
        ),
      );

      // Optional: Reset back to "All Content" tab
      setState(() {
        _tabController.index = 0;
      });
    }
  }

  /// Fetch all entertainments
  Future<void> fetchAllEntertainmentContent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Please log in to see entertainment content.';
          isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('entertainments')
          .select()
          .order('title');

      if (response.isNotEmpty) {
        setState(() {
          entertainmentItems = List<Map<String, dynamic>>.from(response);
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          entertainmentItems = [];
          errorMessage = 'No entertainment content available.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading content: $e";
        isLoading = false;
      });
    }
  }

  /// Fetch recommended entertainments
  Future<void> fetchRecommendedEntertainmentContent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Please log in to see recommendations.';
          isLoading = false;
        });
        return;
      }

      // ✅ Call backend to trigger recommendation generation
      try {
        final baseUrl = Config.apiBaseUrl;
        final apiUrl =
            '$baseUrl/recommend_entertainment/api/suggestions/${user.id}';

        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          print('✅ Recommendations generated successfully');
        } else {
          print('⚠️ API call failed: ${response.statusCode}');
        }

        await Future.delayed(const Duration(seconds: 1));
      } catch (apiError) {
        print('⚠️ API call error (may be OK): $apiError');
      }

      // ✅ Fetch recommendations from Supabase
      final response = await Supabase.instance.client
          .from('recommended_entertainments')
          .select('entertainments(*), matched_state, recommended_at')
          .eq('user_id', user.id)
          .order('recommended_at', ascending: false);

      if (response.isNotEmpty) {
        final List<Map<String, dynamic>> items =
            response.map<Map<String, dynamic>>((item) {
          final entertainment = item['entertainments'] as Map<String, dynamic>;
          return {
            ...entertainment,
            'recommended_at': item['recommended_at'],
          };
        }).toList();

        // Remove duplicates
        final uniqueItems = <Map<String, dynamic>>[];
        final seenIds = <dynamic>{};

        for (final item in items) {
          final id = item['id'];
          if (id != null && !seenIds.contains(id)) {
            seenIds.add(id);
            uniqueItems.add(item);
          }
        }

        setState(() {
          entertainmentItems = uniqueItems;
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          entertainmentItems = [];
          errorMessage =
              'No recommendations available. Complete a mental health assessment first.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading recommendations: $e";
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') return entertainmentItems;
    return entertainmentItems
        .where((item) => item['type'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entertainment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        // Use the screen accent green for the TabBar indicator and selected
        // label color so active tabs match the app theme.
        bottom: TabBar(
          controller: _tabController,
          // active tab label color
          labelColor: kAccentGreen,
          // inactive label color
          unselectedLabelColor: Colors.grey.shade600,
          // underline indicator uses the same accent green
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: kAccentGreen, width: 3.0),
            insets: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          tabs: const [
            Tab(text: "All Content"),
            Tab(text: "For You"),
            Tab(text: "Exercises"), // ✅ Added new tab
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isLoading && errorMessage.isEmpty && _tabController.index == 0)
            _buildCategoryFilter(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _buildContentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              // Use the screen green for selected chip background so the filter
              // matches the accent used on the rest of the screen. Adjust
              // kAccentGreen at the top of the file to change this globally.
              selectedColor: kAccentGreen.withOpacity(0.12),
              labelStyle: TextStyle(
                color: isSelected ? kAccentGreen : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              // make the error icon match the app green accent so the screen
              // has a consistent theme; change kAccentGreen up above to alter
              // this color everywhere.
              Icons.error_outline,
              size: 50,
              color: kAccentGreen.withOpacity(0.85),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              // consistent green tint for empty-state icon
              Icons.search_off,
              size: 50,
              color: kAccentGreen.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No content found for $selectedCategory'
                  : 'No personalized recommendations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildEntertainmentItem(item);
      },
    );
  }

  Widget _buildEntertainmentItem(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Unknown Title';
    final type = item['type'] ?? 'Unknown Type';
    final coverImgUrl = item['cover_img_url'];
    final recommendedAt = item['recommended_at'];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: coverImgUrl != null
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(coverImgUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getMediaIcon(type),
                  color: Colors.grey[600],
                ),
              ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 14.0,
                // use a darker accent green instead of neutral grey so item
                // types read as part of the green theme
                color: kAccentGreen.withOpacity(0.9),
              ),
            ),
            if (recommendedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                "Recommended: ${_formatDate(recommendedAt)}",
                style: TextStyle(
                  fontSize: 11.0,
                  // subtle green tint for recommendation meta
                  color: kAccentGreen.withOpacity(0.85),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.play_circle_fill,
            // Use the screen accent green instead of Theme.primaryColor
            color: kAccentGreen,
            size: 30.0,
          ),
          onPressed: () {
            _navigateToPlayer(item);
          },
        ),
        onTap: () {
          _navigateToPlayer(item);
        },
      ),
    );
  }

  IconData _getMediaIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meditation':
        return Icons.self_improvement;
      case 'music track':
        return Icons.music_note;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.play_arrow;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _navigateToPlayer(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Unknown Title';
    final type = item['type'] ?? 'Unknown Type';
    final url = item['media_file_url'];
    final coverImgUrl = item['cover_img_url'];

    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaPlayerScreen(
            mediaUrl: url,
            title: title,
            mediaType: type,
            coverImgUrl: coverImgUrl,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media file not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
