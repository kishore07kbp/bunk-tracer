import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;

  register() async {

    if (nameController.text.isEmpty ||
        rollController.text.isEmpty ||
        phoneController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      String deviceID = await DeviceService.getDeviceID();
      String permanentID = AppUtils.generatePermanentID();

      var data = {
        "fullname": nameController.text.trim(),
        "rollNumber": rollController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "deviceSystemID": deviceID,
        "permanentID": permanentID,
      };

      print("REGISTER DATA SENT:");
      print(data);

      var response = await ApiService.registerUser(data);

      if (response != null && response["success"] == true){

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {

            final otpController = TextEditingController();
            bool isVerifying = false;

            return StatefulBuilder(
              builder: (context, setDialogState) {

                return AlertDialog(
                  title: Text("Enter OTP"),

                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Text("OTP sent to Email"),

                      SizedBox(height: 16),

                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "OTP",
                          border: OutlineInputBorder(),
                        ),
                      ),

                    ],
                  ),

                  actions: [

                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Cancel"),
                    ),

                    ElevatedButton(

                      onPressed: isVerifying ? null : () async {

                        if (otpController.text.isEmpty) return;

                        setDialogState(() {
                          isVerifying = true;
                        });

                        try {

                          var verifyData = {
                            "phoneNumber": phoneController.text.trim(),
                            "otp": otpController.text.trim(),
                            "deviceSystemID": deviceID,
                            "permanentID": permanentID,
                          };

                          var verifyResponse =
                              await ApiService.verifyOtp(verifyData);

                          if (verifyResponse != null &&
                              verifyResponse["success"] == true) {

                            await StorageService.savePermanentID(permanentID);

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Registration successful')),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashboardScreen(
                                  roll: rollController.text,
                                  deviceID: deviceID,
                                  permanentID: permanentID,
                                ),
                              ),
                            );

                          } else {

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  verifyResponse?["message"] ??
                                  "OTP verification failed"
                                ),
                              ),
                            );

                          }

                        } catch (e) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );

                        } finally {

                          setDialogState(() {
                            isVerifying = false;
                          });

                        }

                      },

                      child: isVerifying
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text("Verify"),

                    ),

                  ],

                );

              },

            );

          },

        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?["message"] ?? "Registration failed")),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    } finally {

      setState(() {
        isLoading = false;
      });

    }

  }

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),

              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(32.0),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Icon(
                        Icons.person_add,
                        size: 80,
                        color: Colors.blue.shade700,
                      ),

                      SizedBox(height: 16),

                      Text(
                        "Register Device",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),

                      SizedBox(height: 32),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      TextField(
                        controller: rollController,
                        decoration: InputDecoration(
                          labelText: "Roll Number",
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                    ],

                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }
}