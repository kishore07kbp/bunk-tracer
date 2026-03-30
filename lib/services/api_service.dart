import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ble_service.dart';

class ApiService {

  static const String baseUrl = "https://attendance-backend-i6mj.onrender.com/api/mobile";

  static Future registerUser(data) async {

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print("REGISTER RESPONSE STATUS: ${response.statusCode}");
      print("REGISTER RESPONSE BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("REGISTER ERROR: $e");
      return {"success": false, "message": "Connection error"};
    }
  }

  static Future verifyOtp(data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print("VERIFY OTP RESPONSE STATUS: ${response.statusCode}");
      print("VERIFY OTP RESPONSE BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("VERIFY OTP ERROR: $e");
      return {"success": false, "message": "Connection error"};
    }
  }

  static Future loginUser(requestData) async {

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      print("LOGIN RESPONSE STATUS: ${response.statusCode}");
      print("LOGIN RESPONSE BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (data != null && data["success"] == true) {
        String rollNumber = data["rollNumber"];
        String permanentId = data["permanentId"];

        print("---------------------------------");
        print("ROLL NUMBER FROM SERVER: $rollNumber");
        print("PERMANENT ID FROM SERVER: $permanentId");
        print("---------------------------------");

        await BleService.startAdvertising(permanentId);
      } else {
        print("LOGIN ATTEMPT FAILED: ${data['message'] ?? 'Unknown error'}");
      }

      return data;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {"success": false, "message": "Connection error"};
    }
  }

  static Future logout(String rollNumber) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rollNumber": rollNumber}),
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }
}

