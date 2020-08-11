import 'package:permission_handler/permission_handler.dart';

Future<bool> checkAndRequest(PermissionGroup permissionGroup) async {
  var permissionHandler = PermissionHandler();
  var permissionStatus =
      await permissionHandler.checkPermissionStatus(permissionGroup);
  if (permissionStatus == PermissionStatus.granted) return true;

  var requestResults =
      await permissionHandler.requestPermissions([permissionGroup]);

  if (requestResults[permissionGroup] == PermissionStatus.granted) return true;
  return false;
}
