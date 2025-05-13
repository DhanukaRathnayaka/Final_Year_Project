import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlayerPage extends StatefulWidget {
  final String mp3Url;
  final String title;
  final String docId;
  final String? imageUrl;
  
  const PlayerPage({
    super.key,
    required this.mp3Url,
    required this.title,
    required this.docId,
    required this.imageUrl,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isPlaying = false;
  bool isLiked = false;
  double currentPosition = 0.0;
  double totalDuration = 1.0;
  String? imageUrl;
  String? artist;
  
  final AudioPlayer audioPlayer = AudioPlayer();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchSongData();
    _setupAudioPlayer();
  }

  Future<void> _fetchSongData() async {
    try {
      DocumentSnapshot doc = await firestore.collection('songs').doc(widget.docId).get();
      if (doc.exists) {
        setState(() {
          imageUrl = doc['imageUrl'];
          artist = doc['artist'];
        });
      }
    } catch (e) {
      print('Error fetching song data: $e');
    }
  }

  void _setupAudioPlayer() {
    audioPlayer.setSourceUrl(widget.mp3Url);
    
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration.inSeconds.toDouble();
      });
    });

    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position.inSeconds.toDouble();
      });
    });
  }

  String _formatTime(double seconds) {
    return '${(seconds / 60).floor()}:${(seconds % 60).floor().toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Album Art
          Container(
            margin: const EdgeInsets.all(40),
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              image: DecorationImage(
                image: imageUrl != null 
                  ? NetworkImage(imageUrl!) 
                  : const NetworkImage('https://via.placeholder.com/120'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Song Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist ?? 'Unknown Artist',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isLiked = !isLiked;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.grey.shade600,
                        inactiveTrackColor: Colors.grey.shade800,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.1),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: currentPosition.clamp(0.0, totalDuration),
                        max: totalDuration,
                        onChanged: (value) {
                          setState(() {
                            currentPosition = value;
                          });
                          audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(currentPosition),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatTime(totalDuration),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.shuffle),
                      color: Colors.grey.shade400,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      color: Colors.white,
                      iconSize: 36,
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (isPlaying) {
                          await audioPlayer.pause();
                        } else {
                          await audioPlayer.resume();
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: Colors.white,
                      iconSize: 36,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.repeat),
                      color: Colors.grey.shade400,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bottom options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices),
                      color: Colors.grey.shade400,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      color: Colors.grey.shade400,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}