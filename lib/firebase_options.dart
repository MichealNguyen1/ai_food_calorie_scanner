import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO: Replace with your Firebase configuration
    return const FirebaseOptions(
      apiKey: 'AIzaSyD2j2PHqwD5isuHZICYovNtBGkmQpNPLeA',
      appId: 'com.ai.calories.scanner',
      messagingSenderId: '624916292299',
      projectId: 'ai-food-calorie-scanner',
      storageBucket: 'ai-food-calorie-scanner.firebasestorage.app',
    );
  }
} 