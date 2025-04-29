import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _imageFile;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _foodList = [];
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      print('Error signing in anonymously: $e');
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    _imageFile = File(pickedFile.path);

    try {
      final imageUrl = await _uploadImageToFirebase(_imageFile!);
      final result = await _callAnalyzeFoodFunction(imageUrl);

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _uploadImageToFirebase(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _callAnalyzeFoodFunction(String imageUrl) async {
    final callable = FirebaseFunctions.instance.httpsCallable('analyzeFood');
    final response = await callable.call(<String, dynamic>{
      'imageUrl': imageUrl,
    });

    final data = Map<String, dynamic>.from(response.data);

    // Lấy food list từ server
    final List<dynamic> foodListData = data['foods'] ?? [];

    setState(() {
      _foodList = foodListData.map<Map<String, dynamic>>(
        (item) => Map<String, dynamic>.from(item),
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Food Scanner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickAndAnalyzeImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Select Food Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_uploadedImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _uploadedImageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (_foodList.isNotEmpty) Expanded(child: _buildNutritionList()),
                ],
              ),
      ),
    );
  }

  Widget _buildNutritionList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _foodList.length,
      itemBuilder: (context, index) {
        final food = _foodList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(food['name'] ?? 'Unknown Food'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories: ${food['calories']} kcal'),
                Text('Fat: ${food['fat']}'),
                Text('Protein: ${food['protein']}'),
                Text('Carbs: ${food['carbs']}'),
                if (food['score'] != null)
                  Text(
                    'Confidence: ${(food['score'] * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
