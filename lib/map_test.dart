import 'package:flutter/material.dart';
import 'map.dart';

void main() {
  runApp(const MapTestApp());
}

class MapTestApp extends StatelessWidget {
  const MapTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Test',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}