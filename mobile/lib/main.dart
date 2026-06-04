import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app/app.dart';
import 'app/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase init ignored on web to prevent crash: $e");
    }
  } else {
    await Firebase.initializeApp();
  }
  setupDependencies();
  runApp(const App());
}
