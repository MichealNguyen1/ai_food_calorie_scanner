// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class FirebaseUploadService {
//   final FirebaseStorage storage = FirebaseStorage.instance;

//   Future<String> uploadImage(File imageFile) async {
//     final fileName = DateTime.now().millisecondsSinceEpoch.toString();
//     final ref = storage.ref().child('uploads/$fileName.jpg');
//     await ref.putFile(imageFile);
//     return await ref.getDownloadURL();
//   }
// }
