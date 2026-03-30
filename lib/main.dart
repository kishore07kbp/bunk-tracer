import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:attendance_app/services/storage_service.dart';
import 'package:attendance_app/services/device_service.dart';
import 'package:attendance_app/screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  bool isLoggedIn = await StorageService.getLoginStatus();
  String? roll = await StorageService.getRollNumber();
  String? permID = await StorageService.getPermanentID();
  String deviceID = await DeviceService.getDeviceID();
  
  Widget initialScreen;
  if (isLoggedIn && roll != null && permID != null) {
    initialScreen = DashboardScreen(roll: roll, deviceID: deviceID, permanentID: permID);
  } else {
    initialScreen = LoginScreen();
  }
  
  runApp(SmartAttendanceApp(initialScreen: initialScreen));
}

class SmartAttendanceApp extends StatelessWidget {
  final Widget initialScreen;
  SmartAttendanceApp({required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BunkTracer',
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}