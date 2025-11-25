import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FinTraceApp());
}

class FinTraceApp extends StatelessWidget {
  const FinTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrace',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}