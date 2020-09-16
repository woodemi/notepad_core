import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:http/http.dart' as http;
import 'package:tf_toast/Toast.dart';

class NotepadDetailPage extends StatefulWidget {
  final scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

_toast(String msg) => _scaffoldKey.currentState
    .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class _NotepadDetailPageState extends State<NotepadDetailPage>
    implements NotepadClientCallback {
  @override
  void initState() {
    super.initState();
    notepadConnector.connectionChangeHandler = _handleConnectionChange;
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.connectionChangeHandler = null;
  }

  NotepadClient _notepadClient;

  void _handleConnectionChange(
      NotepadClient client, NotepadConnectionState state) {
    print('_handleConnectionChange $client $state');
    if (state == NotepadConnectionState.connected) {
      _notepadClient = client;
      _notepadClient.callback = this;
    } else {
      _notepadClient?.callback = null;
      _notepadClient = null;
    }
  }

  @override
  void handlePointer(List<NotePenPointer> list) {
    for (var p in list) {
      print('handlePointer ${p.x}, ${p.y}, ${p.p}');
    }
  }

  @override
  void handleEvent(NotepadEvent notepadEvent) {
    print('handleEvent $notepadEvent');
    _toast(notepadEvent.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NotepadDetailPage'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('connect'),
                onPressed: () {
                  notepadConnector.connect(widget.scanResult,
                      Uint8List.fromList([0x00, 0x00, 0x00, 0x02]));
                },
              ),
              RaisedButton(
                child: Text('disconnect'),
                onPressed: () {
                  notepadConnector.disconnect();
                },
              ),
            ],
          ),
          _buildAuthorizationButtons(),
          ..._buildDeviceInfoButtons(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('setMode(COMMON)'),
                onPressed: () async {
                  await _notepadClient.setMode(NotepadMode.Common);
                },
              ),
              RaisedButton(
                child: Text('setMode(SYNC)'),
                onPressed: () async {
                  await _notepadClient.setMode(NotepadMode.Sync);
                },
              ),
            ],
          ),
          ..._buildImportMemoButtons(),
          _buildUpgradeButtons(),
        ],
      ),
    );
  }

  Widget _buildAuthorizationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          child: Text('claimAuth'),
          onPressed: () async {
            if (_notepadClient != null) {
              await _notepadClient.claimAuth();
              _toast('claimAuth success');
            } else {
              _toast('_notepadClient = null');
            }
          },
        ),
        RaisedButton(
          child: Text('disclaimAuth'),
          onPressed: () async {
            if (_notepadClient != null) {
              await _notepadClient.disclaimAuth();
              _toast('disclaimAuth success');
            } else {
              _toast('_notepadClient = null');
            }
          },
        ),
      ],
    );
  }

  List<Widget> _buildDeviceInfoButtons() {
    return <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('getDeviceSize'),
            onPressed: () async {
              var size = _notepadClient.getDeviceSize();
              _toast('device size = $size');
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('getDeviceName'),
            onPressed: () async {
              _toast('DeviceName: ${await _notepadClient.getDeviceName()}');
            },
          ),
          RaisedButton(
            child: Text('setDeviceName'),
            onPressed: () async => {
              await _notepadClient.setDeviceName('abc'),
              _toast('New DeviceName: ${await _notepadClient.getDeviceName()}'),
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('getBatteryInfo'),
            onPressed: () async {
              BatteryInfo battery = await _notepadClient.getBatteryInfo();
              _toast(
                  'battery.percent = ${battery.percent}  battery.charging = ${battery.charging}');
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('getDeviceDate'),
            onPressed: () async {
              var date = await _notepadClient.getDeviceDate();
              _toast('date = ${date}');
            },
          ),
          RaisedButton(
            child: Text('setDeviceDate'),
            onPressed: () async => {
              await _notepadClient.setDeviceDate(0), // second
              _toast('new DeivceDate = 0，即北京时间：1970-01-01 08:00:00}'),
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
              child: Text('getAutoLockTime'),
              onPressed: () async {
                try {
                  _toast(
                      'AutoLockTime = ${await _notepadClient.getAutoLockTime()}分钟');
                } catch (e) {
                  Toast.fail(context, title: e.toString());
                }
              }),
          RaisedButton(
            child: Text('setAutoLockTime'),
            onPressed: () async {
              try {
                await _notepadClient.setAutoLockTime(11);
                _toast('new AutoLockTime = 11分钟');
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildImportMemoButtons() {
    return <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('getMemoSummary'),
            onPressed: () async {
              try {
                var memoSummary = await _notepadClient.getMemoSummary();
                print('${memoSummary.toString()}');
                _toast('getMemoSummary ${memoSummary.toString()}');
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
          RaisedButton(
            child: Text('getMemoInfo'),
            onPressed: () async {
              try {
                var memoInfo = await _notepadClient.getMemoInfo();
                _toast('getMemoInfo ${memoInfo.toString()}');
                print('${memoInfo.toString()}');
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('importMemo'),
            onPressed: () async {
              try {
                var memoData = await _notepadClient.importMemo((progress) =>
                    Toast.loading(context,
                        title: 'importMemo progress $progress'));
                Toast.success(context,
                    title:
                        'importMemo finish, 有效点共计${memoData.pointers.length}个点');
                memoData.pointers.forEach((p) async {
                  print(
                      'memoData x = ${p.x}\ty = ${p.y}\tt = ${p.t}\tp = ${p.p}');
                });
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
          RaisedButton(
            child: Text('deleteMemo'),
            onPressed: () async {
              try {
                await _notepadClient.deleteMemo();
                _toast('deleteMemo success');
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
          RaisedButton(
            child: Text('importAllMemo'),
            onPressed: () async {
              try {
                var memoSummary = await _notepadClient.getMemoSummary();

                var importedCount = 0;
                do {
                  Toast.loading(context,
                      title:
                          "设备总计${memoSummary.memoCount}个，准备导入第${importedCount + 1}个");
                  await Future.delayed(Duration(milliseconds: 3000), () {});
                  var memoData = await _notepadClient.importMemo((progress) =>
                      Toast.loading(context,
                          title: 'importMemo progress $progress'));
                  Toast.success(
                    context,
                    title:
                        'importMemo finish, 有效点共计${memoData.pointers.length}个点',
                  );
                  await _notepadClient.deleteMemo();
                  importedCount += 1;
                } while (importedCount < memoSummary.memoCount);
              } catch (e) {
                Toast.fail(context, title: e.toString());
              }
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildUpgradeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          child: Text('getVersionInfo'),
          onPressed: () async {
            VersionInfo version = await _notepadClient.getVersionInfo();
            _toast(
                'version.hardware = ${version.hardware.major}  version.software = ${version.hardware.minor} version.software = ${version.software.major} version.software = ${version.software.minor} version.software = ${version.software.patch}');
          },
        ),
        RaisedButton(
          child: Text('upgrade'),
          onPressed: () async {
            var upgradeBlob = await _loadUpgradeFile(Version(1, 0, 0));
            await _notepadClient.upgrade(upgradeBlob, Version(0xFF, 0xFF, 0xFF),
                (progress) {
              print('upgrade progress $progress');
            });
          },
        ),
      ],
    );
  }
}

Future<Uint8List> _loadUpgradeFile(Version version) async {
  var userServiceUrl = await _getUserServiceUrl();
  var appUrl = await _getAppUrl(userServiceUrl, version);
  return (await http.get(appUrl)).bodyBytes;
}

Future<String> _getUserServiceUrl() async {
  var response = await http.get('https://service.36notes.com/v2/config/info');
  return json.decode(response.body)['data']['entities'][0]['userServiceUrl'];
}

Future<String> _getAppUrl(String userServiceUrl, Version version) async {
  var appVer = '${version.major}.${version.minor ?? 0}.${version.patch ?? 0}';
  var response =
      await http.get('$userServiceUrl/config/nxpUpdate?appVer=$appVer');
  return json.decode(response.body)['data']['appUrl'];
}
