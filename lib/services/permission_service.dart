import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /*
  ---------------------------------------
  Get all required BLE permissions
  ---------------------------------------
  */
  static List<Permission> get requiredPermissions {
    return [
      Permission.bluetooth, // Core bluetooth for legacy Android
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location, 
    ];
  }

  /*
  ---------------------------------------
  Check if all permissions are granted
  ---------------------------------------
  */
  static Future<bool> checkPermissions() async {
    for (var permission in requiredPermissions) {
      if (!await permission.isGranted) {
        return false;
      }
    }
    return true;
  }

  /*
  ---------------------------------------
  Request and handle permissions
  ---------------------------------------
  */
  static Future<PermissionState> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await requiredPermissions.request();
    
    // Log statuses for debugging
    statuses.forEach((permission, status) {
      print("🔍 Permission: $permission | Status: $status");
    });

    // Strategy for Android 12+ (Nearby Devices):
    // If Advertise, Connect, and Scan are granted, we don't strictly need legacy Bluetooth 
    // to report 'granted' because it might not even be in the manifest (due to maxSdkVersion).
    bool nearbyGranted = statuses[Permission.bluetoothAdvertise]?.isGranted == true &&
                         statuses[Permission.bluetoothConnect]?.isGranted == true &&
                         statuses[Permission.bluetoothScan]?.isGranted == true;

    bool locationGranted = statuses[Permission.location]?.isGranted == true;

    // Check if everything is okay for the current device context
    if ((nearbyGranted || statuses[Permission.bluetooth]?.isGranted == true) && locationGranted) {
      return PermissionState.granted;
    }

    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      return PermissionState.permanentlyDenied;
    }

    return PermissionState.denied;
  }

  static Future<List<Permission>> getDeniedPermissions() async {
    List<Permission> denied = [];
    
    // Check Location
    if (!await Permission.location.isGranted) {
      denied.add(Permission.location);
    }

    // Check Nearby Strategy
    bool nearbyGranted = (await Permission.bluetoothAdvertise.isGranted) &&
                         (await Permission.bluetoothConnect.isGranted) &&
                         (await Permission.bluetoothScan.isGranted);
    
    bool legacyGranted = await Permission.bluetooth.isGranted;

    if (!nearbyGranted && !legacyGranted) {
      // If none of the Bluetooth options are granted, we report them as missing.
      // But we prefer reporting the modern ones if it's a modern device.
      if (await Permission.bluetoothAdvertise.isLimited || await Permission.bluetoothAdvertise.isDenied) {
        denied.add(Permission.bluetoothAdvertise);
        denied.add(Permission.bluetoothConnect);
        denied.add(Permission.bluetoothScan);
      } else {
        denied.add(Permission.bluetooth);
      }
    }

    return denied;
  }
}

enum PermissionState { granted, denied, permanentlyDenied }
