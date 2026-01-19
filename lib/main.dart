import 'package:flutter/material.dart';
import 'package:oving8/widgets/main_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
