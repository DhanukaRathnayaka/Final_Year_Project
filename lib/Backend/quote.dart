import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Quote Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QuoteUploadScreen(), // Screen to upload quotes
    );
  }
}

class QuoteUploadScreen extends StatefulWidget {
  @override
  _QuoteUploadScreenState createState() => _QuoteUploadScreenState();
}

class _QuoteUploadScreenState extends State<QuoteUploadScreen> {
  final _quoteController = TextEditingController();

  // Function to upload the quote to Firebase
  Future<void> uploadQuote(String quote) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Add quote to Firestore
        await FirebaseFirestore.instance.collection('quotes').add({
          'quote': quote,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quote uploaded successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must be signed in to upload a quote')));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload the quote')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload a Quote'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _quoteController,
              decoration: InputDecoration(
                labelText: 'Enter your quote',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final quote = _quoteController.text.trim();
                if (quote.isNotEmpty) {
                  uploadQuote(quote);
                  _quoteController.clear();
                }
              },
              child: Text('Upload Quote'),
            ),
          ],
        ),
      ),
    );
  }
}
