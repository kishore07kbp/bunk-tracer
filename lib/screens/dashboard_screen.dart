import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String roll;
  final String deviceID;
  final String permanentID;

  DashboardScreen({required this.roll, required this.deviceID, required this.permanentID});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isAdvertising = false;

  @override
  void initState() {
    super.initState();
    // Auto-start BLE advertising as per workflow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("---------------------------------");
      print("ROLL NUMBER (EXISTING SESSION): ${widget.roll}");
      print("PERMANENT ID (EXISTING SESSION): ${widget.permanentID}");
      print("---------------------------------");
      startBLE();
    });
    _checkAuthAndRedirect(); // Check authentication status on init
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

  startBLE() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    await BleService.startAdvertising(widget.permanentID);
    setState(() {
      isAdvertising = true;
    });
  }

  stopBLE() async {
    await BleService.stopAdvertising();
    setState(() {
      isAdvertising = false;
    });
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
