import 'dart:math';

class AppUtils {

  static String generatePermanentID() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

}
