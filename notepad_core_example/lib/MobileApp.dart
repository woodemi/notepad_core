import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';

import 'NotepadDetailPage.dart';

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
  StreamSubscription<NotepadScanResult> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = notepadConnector.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: notepadConnector.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Text('Bluetooth: $available');
            },
          ),
          _buildButtons(),
          Divider(color: Colors.blue,),
          _buildListView(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          child: Text('startScan'),
          onPressed: () {
            notepadConnector.startScan();
          },
        ),
        RaisedButton(
          child: Text('stopScan'),
          onPressed: () {
            notepadConnector.stopScan();
          },
        ),
      ],
    );
  }

  var _scanResults = List<NotepadScanResult>();

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) =>
            ListTile(
              title: Text('${_scanResults[index].name}(${_scanResults[index].rssi})'),
              subtitle: Text(_scanResults[index].deviceId),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => NotepadDetailPage(_scanResults[index]),
                ));
              },
            ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }
}
