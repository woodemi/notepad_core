import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:http/http.dart' as http;
import 'package:notepad_core_example/WDMAlertDialog.dart';
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
  var _textEditingController = TextEditingController();

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

  int startDate = 0;
  int totalPointers = 0;
  var averageCount = '';

  @override
  void handlePointer(List<NotePenPointer> list) {
    var nowDate = DateTime.now().millisecondsSinceEpoch;

    //  累加点数
    totalPointers += list.length;

    //  每s计算一次
    if (nowDate > startDate + 1000) {
      print('总数：$totalPointers，平均速度：${totalPointers}');
      setState(() => averageCount = '$totalPointers个/s');
      startDate = nowDate;
      totalPointers = 0;
    }

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
        actions: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: Text(averageCount),
          ),
        ],
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
            child: Text('setSyncfrequencyInterval'),
            onPressed: () async {
              setInputText('请输入每s上报点数(数字)', (value) {
                int count = int.parse(value);
                if (count == null) {
                  _toast('请输入有效数字');
                  return;
                }
                _notepadClient.setSyncfrequencyInterval(count);
                _toast('setSyncfrequencyInterval count = $count');
              });
            },
          ),
        ],
      ),
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
            onPressed: () {
              setInputText('请输入新名字', (value) async {
                await _notepadClient.setDeviceName(value);
                _toast(
                    'New DeviceName: ${await _notepadClient.getDeviceName()}');
              });
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
              _toast(
                  'date = ${date} 即北京时间：${DateTime.fromMillisecondsSinceEpoch(date.toInt() * 1000)}');
            },
          ),
          RaisedButton(
            child: Text('setDeviceDate'),
            onPressed: () async {
              setInputText('请输入新的时间（自1970年起，单位s）', (value) async {
                int date = int.parse(value);
                if (date == null) {
                  _toast('请输入有效数字');
                  return;
                }
                await _notepadClient.setDeviceDate(date); // second
                _toast(
                    'newDate = $date，即北京时间：${DateTime.fromMillisecondsSinceEpoch(date * 1000)}');
              });
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
              setInputText('请输入新的休眠时间（单位分钟）', (value) async {
                int date = int.parse(value);
                if (date == null) {
                  _toast('请输入有效数字');
                  return;
                }
                await _notepadClient.setAutoLockTime(date);
                _toast('new AutoLockTime = $date分钟');
              });
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
            // var upgradeBlob = await _loadUpgradeFile(Version(1, 0, 0));
            // await _notepadClient.upgrade(upgradeBlob, Version(0xFF, 0xFF, 0xFF),
            //     (progress) {
            // var versionInfo = await _notepadClient.getVersionInfo();
            // var version = versionInfo.hardware;
            var version = Version(1, 0, 0);

            var deviceType = _notepadClient.getDeviceType();
            var otaModel = await _loadUpgradeFile(deviceType, version);
            var otaFile = (await http.get(otaModel.appUrl)).bodyBytes;
            await _notepadClient.upgrade(otaFile, otaModel.getVersion(),
                (progress) {
              print('upgrade progress $progress');
            });
          },
        ),
      ],
    );
  }

  setInputText(String title, StringCallback confirm) {
    _textEditingController.text = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WDMAlertDialog(
        type: Operation.EDIT,
        textEditingController: _textEditingController,
        title: title,
        confirm: confirm,
      ),
    );
  }
}

class OTAModel {
  bool hasNewVersion;
  String version;
  String appUrl;
  String description;
  int releaseTime;
  int level;

  OTAModel.fromMap(Map json) {
    hasNewVersion = json['hasNewVersion'] ?? false;
    version = json['version'] ?? '';
    appUrl = json['appUrl'] ?? '';
    description = json['description'] ?? '';
    releaseTime = json['releaseTime'] ?? 0;
    level = json['level'] ?? 0;
  }

  Version getVersion() {
    var list = version.split('.');
    if (list.length != 3) return Version(0, 0, 0);
    return Version(int.parse(list[0]), int.parse(list[1]), int.parse(list[2]));
  }
}

Future<OTAModel> _loadUpgradeFile(String deviceType, Version version) async {
  var userServiceUrl = await _getUserServiceUrl();
  return await _getAppUrl(userServiceUrl, deviceType, version);
}

Future<String> _getUserServiceUrl() async {
  var response = await http.get('https://service.36notes.com/v2/config/info');
  return json.decode(response.body)['data']['entities'][0]['userServiceUrl'];
}

Future<OTAModel> _getAppUrl(
  String userServiceUrl,
  String deviceType,
  Version version,
) async {
  var appVer = '${version.major}.${version.minor ?? 0}.${version.patch ?? 0}';
  appVer = '0.0.1';
  var url = '$userServiceUrl/config/nxpUpdate?appVer=$appVer&deviceType=$deviceType';
  var response = await http.get(url);
  return OTAModel.fromMap(json.decode(response.body)['data']);
}
