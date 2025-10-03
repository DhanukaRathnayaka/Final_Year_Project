import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendedSuggestionsWidget extends StatefulWidget {
  final String userId;
  
  const RecommendedSuggestionsWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<RecommendedSuggestionsWidget> createState() => RecommendedSuggestionsWidgetState();
}

class RecommendedSuggestionsWidgetState extends State<RecommendedSuggestionsWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  String? _error;
  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    _initializeRealtimeSubscription();
    _fetchRecommendedSuggestions();
  }

  void _initializeRealtimeSubscription() {
    // Subscribe to realtime changes on the recommended_suggestions table for this user
    _subscription = _supabase
        .channel('recommended_suggestions_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'recommended_suggestions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            print('Realtime update received: $payload');
            _handleRealtimeUpdate(payload);
          },
        )
        .subscribe((status, err) {
          if (err != null) {
            print('Realtime subscription error: $err');
          } else {
            print('Realtime subscription status: $status');
          }
        });
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    // Handle different types of changes
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload);
        break;
      case PostgresChangeEvent.update:
        _handleUpdate(payload);
        break;
      case PostgresChangeEvent.delete:
        _handleDelete(payload);
        break;
      default:
        break;
    }
  }

  void _handleInsert(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    if (newRecord != null) {
      // Fetch the complete data with join
      _fetchNewSuggestionDetails(newRecord['id']);
    }
  }

  void _handleUpdate(PostgresChangePayload payload) {
    final updatedRecord = payload.newRecord;
    if (updatedRecord != null) {
      setState(() {
        final index = _suggestions.indexWhere(
          (item) => item['id'] == updatedRecord['id']
        );
        if (index != -1) {
          // Update existing record
          _suggestions[index] = {
            ..._suggestions[index],
            ...updatedRecord,
          };
        }
      });
    }
  }

  void _handleDelete(PostgresChangePayload payload) {
    final oldRecord = payload.oldRecord;
    if (oldRecord != null) {
      setState(() {
        _suggestions.removeWhere((item) => item['id'] == oldRecord['id']);
      });
    }
  }

  Future<void> _fetchNewSuggestionDetails(String suggestionId) async {
    try {
      final response = await _supabase
          .from('recommended_suggestions')
          .select('''
            id,
            dominant_state,
            recommended_at,
            suggestions (
              id,
              logo,
              suggestion,
              description,
              category
            )
          ''')
          .eq('id', suggestionId)
          .single();

      if (response != null) {
        setState(() {
          _suggestions.insert(0, response); // Add to top
        });
      }
    } catch (e) {
      print('Error fetching new suggestion details: $e');
    }
  }

  Future<void> _fetchRecommendedSuggestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabase
          .from('recommended_suggestions')
          .select('''
            id,
            dominant_state,
            recommended_at,
            created_at,
            suggestions (
              id,
              logo,
              suggestion,
              description,
              category
            )
          ''')
          .eq('user_id', widget.userId)
          .order('recommended_at', ascending: false);

      if (response != null && response is List) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print('Error fetching suggestions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuggestionDetail(Map<String, dynamic> suggestionData) {
    final suggestion = suggestionData['suggestions'] as Map<String, dynamic>?;
    
    if (suggestion == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          suggestion['logo'] ?? '💡',
                          style: const TextStyle(fontSize: 32),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      suggestion['suggestion'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      suggestion['description'] ?? 'No description available',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            suggestion['category'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getCategoryColor(suggestion['category']),
                        ),
                        Chip(
                          label: Text(
                            suggestionData['dominant_state'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blue[800],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (suggestionData['recommended_at'] != null)
                      Text(
                        'Recommended on ${_formatDate(suggestionData['recommended_at'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
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

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'happy/positive':
        return Colors.green;
      case 'stressed/anxious':
        return Colors.orange;
      case 'depressed/sad':
        return Colors.blue;
      case 'angry/frustrated':
        return Colors.red;
      case 'neutral/calm':
        return Colors.grey;
      case 'confused/uncertain':
        return Colors.purple;
      case 'excited/energetic':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshSuggestions() async {
    await _fetchRecommendedSuggestions();
  }

  // Public method to refresh suggestions (can be called from parent)
  void refreshSuggestions() {
    _refreshSuggestions();
  }

  @override
  void dispose() {
    // Clean up the realtime subscription
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            _buildLoadingState(),

          if (_error != null)
            _buildErrorState(),

          if (!_isLoading && _suggestions.isEmpty)
            _buildEmptyState(),

          if (!_isLoading && _suggestions.isNotEmpty)
            _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading recommendations...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'Error loading suggestions',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _refreshSuggestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.grey[400], size: 40),
            const SizedBox(height: 8),
            Text(
              'No recommendations yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'New suggestions will appear here automatically',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final item = _suggestions[index];
        final suggestion = item['suggestions'] as Map<String, dynamic>?;
        
        if (suggestion == null) return const SizedBox();
        
        return _buildSuggestionCard(item, suggestion, index);
      },
    );
  }

  Widget _buildSuggestionCard(
    Map<String, dynamic> item, 
    Map<String, dynamic> suggestion, 
    int index
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(suggestion['category']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                suggestion['logo'] ?? '💡',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            suggestion['suggestion'] ?? 'No Title',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                suggestion['description'] ?? 'No description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(suggestion['category']).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion['category'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[800]!.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['dominant_state'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: () => _showSuggestionDetail(item),
        ),
      ),
    );
  }
}