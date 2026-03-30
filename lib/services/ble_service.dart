import 'package:flutter/services.dart';

class BleService {

  static const platform = MethodChannel('ble_advertise');

  /*
  ---------------------------------------
  Start BLE (permId only)
  ---------------------------------------
  */
  static Future<void> startAdvertising(String permId) async {
    try {
      await platform.invokeMethod('startBLE', {
        "permId": permId,
      });
    } catch (e) {
      print("❌ BLE Start Error: $e");
    }
  }

  /*
  ---------------------------------------
  Stop BLE
  ---------------------------------------
  */
  static Future<void> stopAdvertising() async {
    try {
      await platform.invokeMethod('stopBLE');
    } catch (e) {
      print("❌ BLE Stop Error: $e");
    }
  }
}