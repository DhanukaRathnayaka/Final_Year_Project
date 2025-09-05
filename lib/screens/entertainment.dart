import 'package:flutter/material.dart';
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

      if (response != null && response.isNotEmpty) {
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

      final response = await Supabase.instance.client
          .from('recommended_entertainments')
          .select('entertainments(*), matched_state, recommended_at')
          .eq('user_id', user.id)
          .order('recommended_at', ascending: false);

      if (response != null && response.isNotEmpty) {
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
          errorMessage = 'No recommendations available.';
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
            Tab(text: "All"),
            Tab(text: "Recommended"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isLoading && errorMessage.isEmpty) _buildCategoryFilter(),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text('No content found'),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMusicItem(item);
      },
    );
  }

  Widget _buildMusicItem(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Unknown Title';
    final type = item['type'] ?? 'Unknown Type';
    final coverImgUrl = item['cover_img_url'];
    final mediaUrl = item['media_file_url'];
    final matchedState = item['matched_state'];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Cover image
            if (coverImgUrl != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(coverImgUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.music_note),
              ),

            const SizedBox(width: 16.0),

            // Title, type, and matched state
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (matchedState != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      "Matched: $matchedState",
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16.0),

            // Play button
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 30.0),
              onPressed: () {
                _navigateToPlayer(item);
              },
            ),
          ],
        ),
      ),
    );
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
        ),
      );
    }
  }
}