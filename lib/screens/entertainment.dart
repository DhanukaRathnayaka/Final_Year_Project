import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/screens/media_player_screen.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  List<Map<String, dynamic>> entertainmentItems = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meditation', 'Music Track', 'Video'];

  @override
  void initState() {
    super.initState();
    fetchEntertainmentContent();
  }

  Future<void> fetchEntertainmentContent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Please log in to see entertainment content.';
          isLoading = false;
        });
        return;
      }

      // Fetch entertainment items directly from Supabase
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
            onPressed: fetchEntertainmentContent,
          ),
        ],
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
            onPressed: fetchEntertainmentContent,
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
            
            // Title and type
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

  // In the _navigateToPlayer method, update to pass the cover image:
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