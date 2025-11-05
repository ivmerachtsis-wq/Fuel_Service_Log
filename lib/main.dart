import 'package:flutter/material.dart';
import 'ui/shell.dart';
import 'state/navigation_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final nav = NavigationController(0);
  runApp(MyApp(controller: nav));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final NavigationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel & Service Log',
      debugShowCheckedModeBanner: false,
      home: Shell(controller: controller),
    );
  }
}
