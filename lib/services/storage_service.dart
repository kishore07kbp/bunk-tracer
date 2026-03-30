import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {

  static final storage = FlutterSecureStorage();

  static Future savePermanentID(String id) async {
    await storage.write(key: "permanentID", value: id);
  }

  static Future<String?> getPermanentID() async {
    return await storage.read(key: "permanentID");
  }

  static Future saveRollNumber(String roll) async {
    await storage.write(key: "rollNumber", value: roll);
  }

  static Future<String?> getRollNumber() async {
    return await storage.read(key: "rollNumber");
  }

  static Future saveLoginStatus(bool status) async {
    await storage.write(key: "isLoggedIn", value: status.toString());
  }

  static Future<bool> getLoginStatus() async {
    String? status = await storage.read(key: "isLoggedIn");
    return status == "true";
  }

  static Future saveToken(String token) async {
    await storage.write(key: "token", value: token);
  }

  static Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  static Future clear() async {
    await storage.deleteAll();
  }
}
