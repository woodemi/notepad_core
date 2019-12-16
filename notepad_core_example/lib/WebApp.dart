import 'package:flutter/material.dart';

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin example app',
      home: Center(
        child: Text('Running on: Web\n'),
      ),
    );
  }
}