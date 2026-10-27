import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase CLIENT configurations only. No admin credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBGziKsrQmYQtPoAruljRUYM0oHEwfbMNw',
    appId: '1:1010827395265:android:02742b2b5dc39222b35440',
    messagingSenderId: '1010827395265',
    projectId: 'prm393-pe-71dac',
    storageBucket: 'prm393-pe-71dac.firebasestorage.app',
  );
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDsSUqfPjYF6ZNMMlMSMYvMg8whs97dzAA',
    appId: '1:1010827395265:web:abac1685db96340eb35440',
    messagingSenderId: '1010827395265',
    projectId: 'prm393-pe-71dac',
    storageBucket: 'prm393-pe-71dac.firebasestorage.app',
    authDomain: 'prm393-pe-71dac.firebaseapp.com',
  );

  static bool get isConfigured =>
      currentPlatform.apiKey.isNotEmpty &&
      currentPlatform.appId.isNotEmpty &&
      currentPlatform.projectId.isNotEmpty;
}
