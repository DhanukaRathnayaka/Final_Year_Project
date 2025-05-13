import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadEntertainmentScreen extends StatefulWidget {
  @override
  _UploadEntertainmentScreenState createState() => _UploadEntertainmentScreenState();
}

class _UploadEntertainmentScreenState extends State<UploadEntertainmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title, _mp3Url, _imageUrl;
  String _category = 'Music';

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance.collection('entertainments').add({
          'title': _title,
          'category': _category,
          'mp3Url': _mp3Url,
          'imageUrl': _imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded successfully!')),
        );

        _formKey.currentState!.reset();
        setState(() {
          _category = 'Music';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Entertainment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
                onSaved: (val) => _title = val,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: ['Music', 'Meditation', 'Breathing'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'MP3 URL'),
                validator: (val) => val == null || val.isEmpty ? 'Enter MP3 URL' : null,
                onSaved: (val) => _mp3Url = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Image URL (optional)'),
                onSaved: (val) => _imageUrl = val,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
