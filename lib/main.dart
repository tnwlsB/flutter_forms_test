import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Forms (GAS & Forms API)',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
