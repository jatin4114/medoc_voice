import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_application_1/const.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/prescription_generator_page.dart';

void main() {
  Gemini.init(apiKey: GEMINI_API_KEY);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/prescription-generator': (context) => const PrescriptionGeneratorPage(),
      },
      initialRoute: '/',
    );
  }
}
