import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothStateService {
  /*
  ---------------------------------------
  Check if Bluetooth is currently ON
  ---------------------------------------
  */
  static Future<bool> isBluetoothOn() async {
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  /*
  ---------------------------------------
  Stream for Bluetooth Adapter changes
  ---------------------------------------
  */
  static Stream<BluetoothAdapterState> get adapterStatusStream {
    return FlutterBluePlus.adapterState;
  }

  /*
  ---------------------------------------
  Request to turn ON Bluetooth (Android Only)
  ---------------------------------------
  */
  static Future<void> turnOn() async {
    await FlutterBluePlus.turnOn();
  }
}
