// user_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static Future<void> saveUser(String uid, String email, String displayName, String photoURL) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('email', email);
    await prefs.setString('displayName', displayName);
    await prefs.setString('photoURL', photoURL);
  }

  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final email = prefs.getString('email');
    final displayName = prefs.getString('displayName');
    final photoURL = prefs.getString('photoURL');

    if (uid != null && email != null) {
      return {
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
      };
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
