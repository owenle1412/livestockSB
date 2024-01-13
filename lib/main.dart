import 'package:flutter/material.dart';
import './livestock.dart';

void main() {
  runApp(const MainScreen());
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(    
      home: const SafeArea(child: LiveStock()),
      theme: ThemeData(
        primarySwatch: Colors.green
      ),
    );
  }
}