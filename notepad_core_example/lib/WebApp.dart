import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin example app',
      home: _WebHomePage(),
    );
  }
}

class _WebHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WebHomePageState();
  
}

class _WebHomePageState extends State<_WebHomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RaisedButton(
            child: Text('requestDevice'),
            onPressed: () async {
              var device = await notepadConnector.requestDevice();
              print('requestDevice $device');
            },
          ),
        ],
      ),
    );
  }
}