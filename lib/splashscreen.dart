import 'package:flutter/material.dart';

// Simple welcome screen shown when the app starts.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 64),
            SizedBox(height: 16),
            Text(
              'StudyLog',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Keep track of your study sessions'),
          ],
        ),
      ),
    );
  }
}
