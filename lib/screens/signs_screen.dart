import 'package:flutter/material.dart';

class SignsScreen extends StatelessWidget {
  const SignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Signs'),
      ),
      body: InteractiveViewer(
        maxScale: 5.0,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Image.asset(
              'assets/signs_pdf/road_signs_page_1.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Error loading Page 1', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/signs_pdf/road_signs_page_2.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Error loading Page 2', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
