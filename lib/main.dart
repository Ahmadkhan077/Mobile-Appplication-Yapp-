import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/yapp_provider.dart';
import 'screens/yapp_list_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => YappProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const YappListScreen(), // We'll implement this screen in next steps
    );
  }
}
