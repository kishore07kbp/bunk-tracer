import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermissions() async {
  var status = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();

  return status.values.every((s) => s.isGranted);
}