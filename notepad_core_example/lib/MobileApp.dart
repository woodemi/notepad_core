import 'dart:async';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:notepad_core_example/permission.dart';
import 'package:permission_handler/permission_handler.dart';

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

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

_toast(String msg) => _scaffoldKey.currentState
  .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class _MobileHomePageState extends State<_MobileHomePage> {
  StreamSubscription<NotepadScanResult> _subscription;

  @override
  void initState() {
    super.initState();
    notepadConnector.bluetoothChangeHandler = _handleBluetoothChange;
    _subscription = notepadConnector.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.bluetoothChangeHandler = null;
    _subscription?.cancel();
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
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: notepadConnector.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Text('Bluetooth init: $available');
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
          onPressed: () async {
            var b = await checkAndRequest(PermissionGroup.location);
            if (b) {
              notepadConnector.startScan();
            }
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
