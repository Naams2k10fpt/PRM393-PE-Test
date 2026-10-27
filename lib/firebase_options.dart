import 'package:firebase_core/firebase_core.dart';

// Firebase Android CLIENT configuration. No admin credentials.
class DefaultFirebaseOptions {
  static const currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyBGziKsrQmYQtPoAruljRUYM0oHEwfbMNw',
    appId: '1:1010827395265:android:02742b2b5dc39222b35440',
    messagingSenderId: '1010827395265',
    projectId: 'prm393-pe-71dac',
    storageBucket: 'prm393-pe-71dac.firebasestorage.app',
  );
  static bool get isConfigured => true;
}
