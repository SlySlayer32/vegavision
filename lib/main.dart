import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vegavision/core/di/locator.dart';
import 'package:vegavision/firebase_options.dart';
import 'package:vegavision/views/image_capture/image_capture_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup dependencies
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VegaVision AI Editor', // Updated title slightly
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Enable Material 3
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          backgroundColor: Colors.deepPurple, // Example color
          foregroundColor: Colors.white, // Example color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            backgroundColor: Colors.deepPurple, // Example color
            foregroundColor: Colors.white, // Example color
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true, // Enable Material 3
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          // Dark theme colors can be customized further if needed
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            // Dark theme button colors can be customized further
          ),
        ),
      ),
      home: const ImageCaptureView(),
    );
  }
}
