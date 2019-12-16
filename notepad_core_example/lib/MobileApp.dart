
import 'package:flutter/material.dart';
import 'package:notepad_core_platform_interface/notepad_core_platform_interface.dart';

class MobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _MobileHomePage(),
    );
  }
}

class _MobileHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<_MobileHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
      ),
      body: Column(
        children: <Widget>[
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: <Widget>[
        RaisedButton(
          child: Text('startScan'),
          onPressed: () {
            NotepadCorePlatform.instance.startScan();
          },
        ),
        RaisedButton(
          child: Text('stopScan'),
          onPressed: () {
            NotepadCorePlatform.instance.stopScan();
          },
        ),
      ],
    );
  }
}
