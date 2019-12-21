import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

import 'NotepadDetailPage.dart';

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin example app',
      home: _WebHomePage(),
    );
  }
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

_toast(String msg) => _scaffoldKey.currentState
  .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class _WebHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WebHomePageState();
  
}

class _WebHomePageState extends State<_WebHomePage> {
  @override
  void initState() {
    super.initState();
    notepadConnector.bluetoothChangeHandler = _handleBluetoothChange;
  }
  @override
  void dispose() {
    super.dispose();
    notepadConnector.bluetoothChangeHandler = null;
  }

  void _handleBluetoothChange(BluetoothState state) {
    _toast('_handleBluetoothChange ${state.value}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Plugin example app'),
      ),
      body: _buildCenter(context),
    );
  }

  Widget _buildCenter(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FutureBuilder(
            future: notepadConnector.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Text('Bluetooth init: $available');
            },
          ),
          RaisedButton(
            child: Text('requestDevice'),
            onPressed: () async {
              var device = await notepadConnector.requestDevice();
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => NotepadDetailPage(device),
              ));
            },
          ),
        ],
      ),
    );
  }
}