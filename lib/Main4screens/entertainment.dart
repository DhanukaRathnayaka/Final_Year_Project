import 'package:flutter/material.dart';
import 'package:safespace/widgets/PlayerPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Entertainment extends StatelessWidget {
  const Entertainment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Entertainment"),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  automaticallyImplyLeading: false, // 👈 This removes the back button
),
      backgroundColor: const Color(0xFFF5F5FF),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entertainments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No entertainment content available."));
          }

          final allDocs = snapshot.data!.docs;

          // Separate by category
          final music = allDocs.where((doc) => doc['category'] == 'Music').toList();
          final meditation = allDocs.where((doc) => doc['category'] == 'Meditation').toList();
          final breathing = allDocs.where((doc) => doc['category'] == 'Breathing').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (music.isNotEmpty) _buildSection("Music Tracks", music),
                if (meditation.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection("Meditation", meditation),
                ],
                if (breathing.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection("Breathing Exercises", breathing),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<QueryDocumentSnapshot> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCard(context, item['imageUrl'] ?? '', item['title'] ?? 'Untitled', item['mp3Url'] ?? '', item.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, String imageUrl, String title, String mp3Url, String docId) {
  return GestureDetector(
    onTap: () {
      // Navigate to the PlayerPage with the MP3 URL and other info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(mp3Url: mp3Url, title: title, docId: docId, imageUrl: imageUrl),
        ),
      );
    },
    child: Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const NetworkImage('https://via.placeholder.com/120'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

}
