import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {

  static Future<String> getDeviceID() async {

    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo android = await deviceInfo.androidInfo;
      return android.id; // ANDROID_ID
    }

    if (Platform.isIOS) {
      IosDeviceInfo ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? "";
    }

    return "UNKNOWN_DEVICE";
  }
}
