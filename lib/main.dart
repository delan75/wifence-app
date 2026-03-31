import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const NetworkApp());
}

class NetworkApp extends StatelessWidget {
  const NetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetworkApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFFF97316),
          surface: const Color(0xFFFFFBF5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xFF16221F),
              displayColor: const Color(0xFF16221F),
            ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

