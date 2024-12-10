import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition App',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
