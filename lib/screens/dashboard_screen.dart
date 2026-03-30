import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/bluetooth_state_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String roll;
  final String deviceID;
  final String permanentID;

  DashboardScreen({required this.roll, required this.deviceID, required this.permanentID});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool isAdvertising = false;
  bool _userWantsToAdvertise = false; // Tracks intent even if temporarily stopped
  StreamSubscription<BluetoothAdapterState>? _btStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBluetoothMonitoring();
    // Auto-start BLE advertising as per workflow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startBLE(isAutoStart: true);
    });
    _checkAuthAndRedirect(); // Check authentication status on init
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _btStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only attempt start if user intent is true AND hardware isn't already active
      if (_userWantsToAdvertise && !isAdvertising) {
        _startBLEInternal();
      }
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      if (isAdvertising) {
        // Stop hardware but keep user intent true for resume
        _stopBLEInternal();
      }
    }
  }

  void _initBluetoothMonitoring() {
    _btStateSubscription = BluetoothStateService.adapterStatusStream.listen((state) {
      if (state == BluetoothAdapterState.off && isAdvertising) {
        stopBLE();
        _showBluetoothOffDialog();
      }
    });
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bluetooth Required"),
        content: Text("Bluetooth is currently OFF. Please turn it back on to continue advertising."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await BluetoothStateService.turnOn();
            },
            child: Text("TURN ON", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: "SETTINGS",
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  Future<String> _getMissingPermissionNames() async {
    List<Permission> denied = await PermissionService.getDeniedPermissions();
    if (denied.isEmpty) return "None";
    
    return denied.map((p) {
      if (p == Permission.bluetoothAdvertise || p == Permission.bluetoothConnect || p == Permission.bluetoothScan) {
        return "Nearby Devices";
      }
      if (p == Permission.location) return "Location";
      if (p == Permission.bluetooth) return "Bluetooth (Legacy)";
      return p.toString().split('.').last;
    }).toSet().join(", "); // Using toSet() to avoid duplicates like "Nearby Devices, Nearby Devices"
  }

  void _checkAuthAndRedirect() async {
    // Ensure the widget is still mounted before performing async operations or navigation
    if (!mounted) return;

    bool isLoggedIn = await StorageService.getLoginStatus();
    String? roll = await StorageService.getRollNumber();
    String? permID = await StorageService.getPermanentID();

    if (!isLoggedIn || roll == null || permID == null) {
      // Re-check mounted after async operation to prevent errors if widget was disposed
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  bool _isCheckingPermissions = false;
  DateTime? _lastCheckTime;

  startBLE({bool isAutoStart = false}) {
    _userWantsToAdvertise = true;
    _startBLEInternal(isAutoStart: isAutoStart);
  }

  _startBLEInternal({bool isAutoStart = false}) async {
    // 1. Re-entrancy Guard
    if (_isCheckingPermissions) return;

    // 2. Cooldown Guard (to prevent UI flickering/looping)
    if (_lastCheckTime != null && 
        DateTime.now().difference(_lastCheckTime!).inSeconds < 2) {
      return;
    }
    
    _isCheckingPermissions = true;
    _lastCheckTime = DateTime.now();

    try {
      // 1. Check Condition: Foreground Only
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;

      // 2. Check & Request Permissions
      PermissionState pState = await PermissionService.requestPermissions();
      if (pState != PermissionState.granted) {
        if (!isAutoStart && mounted) {
          String missing = await _getMissingPermissionNames();
          _showPermissionDeniedMessage("Missing required permissions: $missing");
        }
        return;
      }

      // 3. Check Bluetooth State
      bool isBtOn = await BluetoothStateService.isBluetoothOn();
      if (!isBtOn) {
        _showBluetoothOffDialog();
        return;
      }

      // 4. Start Advertising
      await BleService.startAdvertising(widget.permanentID);
      if (mounted) {
        setState(() {
          isAdvertising = true;
        });
      }
    } finally {
      _isCheckingPermissions = false;
    }
  }

  stopBLE() async {
    _userWantsToAdvertise = false;
    await _stopBLEInternal();
  }

  _stopBLEInternal() async {
    await BleService.stopAdvertising();
    if (mounted) {
      setState(() {
        isAdvertising = false;
      });
    }
  }

  logout() async {
    await stopBLE();
    try {
      await ApiService.logout(widget.roll);
    } catch (e) {
      print("Error calling backend logout: $e");
    }
    await StorageService.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.school_outlined, "Roll Number", widget.roll),
                  Divider(height: 30),
                  _buildInfoRow(Icons.devices_outlined, "Device ID", widget.deviceID),
                  Divider(height: 30),
                  _buildInfoRow(Icons.fingerprint_outlined, "Permanent ID", widget.permanentID),
                ],
              ),
            ),
            SizedBox(height: 40),
            _buildActionButton(
              onPressed: startBLE,
              label: "START BLE ADVERTISE",
              icon: Icons.bluetooth_audio,
              color: Colors.green[600]!,
              isActive: isAdvertising,
            ),
            SizedBox(height: 16),
            _buildActionButton(
              onPressed: stopBLE,
              label: "STOP BLE ADVERTISE",
              icon: Icons.bluetooth_disabled,
              color: Colors.red[400]!,
              isActive: !isAdvertising,
            ),
            Spacer(),
            // The requested Logout Button logic with the red circle
            GestureDetector(
              onTap: logout,
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "LOGOUT",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[800], size: 28),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? color : Colors.grey[200],
          foregroundColor: isActive ? Colors.white : Colors.grey[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: isActive ? 4 : 0,
        ),
      ),
    );
  }
}
