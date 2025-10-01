import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/screens/media_player_screen.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> entertainmentItems = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meditation', 'Music Track', 'Video'];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadData();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (_tabController.index == 0) {
      await fetchAllEntertainmentContent();
    } else {
      await fetchRecommendedEntertainmentContent();
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

      // ✅ FIRST: Call the backend API to generate recommendations
      try {
        // Use dynamic backend URL from config
        final baseUrl = Config.apiBaseUrl;
        final apiUrl = '$baseUrl/recommend_entertainment/api/suggestions/${user.id}';
        
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          print('✅ Recommendations generated successfully');
        } else {
          print('⚠️ API call failed: ${response.statusCode}');
          // Continue anyway - recommendations might already exist
        }
        
        // Wait a bit for the backend to process and store recommendations
        await Future.delayed(const Duration(seconds: 1));
        
      } catch (apiError) {
        print('⚠️ API call error (may be OK): $apiError');
        // Continue anyway - recommendations might already exist
      }

      // ✅ THEN: Fetch the stored recommendations from database
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
            'matched_state': item['matched_state'],
            'recommended_at': item['recommended_at'],
          };
        }).toList();

        setState(() {
          entertainmentItems = items;
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          entertainmentItems = [];
          errorMessage = 'No recommendations available. Complete a mental health assessment first.';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "All Content"),
            Tab(text: "For You"),
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
              Icons.error_outline,
              size: 50,
              color: Colors.grey[400],
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
              Icons.search_off,
              size: 50,
              color: Colors.grey[300],
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
    final matchedState = item['matched_state'];
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
                color: Colors.grey[600],
              ),
            ),
            if (matchedState != null) ...[
              const SizedBox(height: 2),
              Text(
                "Matches your: $matchedState",
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.green,
                ),
              ),
            ],
            if (recommendedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                "Recommended: ${_formatDate(recommendedAt)}",
                style: const TextStyle(
                  fontSize: 11.0,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.play_circle_fill,
            color: Theme.of(context).primaryColor,
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