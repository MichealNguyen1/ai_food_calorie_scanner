import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ResultPage extends StatelessWidget {
  final String? imagePath;
  const ResultPage({
    super.key,
    required this.imagePath,
  });

  Future<Map<String, dynamic>> _analyzeFood() async {
    if (imagePath == null) {
      throw Exception('No image selected');
    }

    // Upload image to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('food_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(File(imagePath!));
    final imageUrl = await storageRef.getDownloadURL();

    // Call Firebase Function to analyze the image
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('analyzeFood');
    final result = await callable.call({
      'imageUrl': imageUrl,
    });

    return result.data;
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const Scaffold(body: Center(child: Text('No image selected')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyzeFood(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data received'));
          }

          final result = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Image.file(File(imagePath!), height: 200),
                const SizedBox(height: 24),
                Text('Food: ${result['name']}'),
                Text('Calories: ${result['calories']} kcal'),
                Text('Fat: ${result['fat']}'),
                Text('Protein: ${result['protein']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
