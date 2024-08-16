import 'package:flutter/material.dart';
import 'prescription_generator_page.dart'; // Import your prescription generator page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrescriptionGeneratorPage()),
            );
          },
          child: const Text('Write Prescription'),
        ),
      ),
    );
  }
}
