import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const tokenKey = 'japen.token';
  static const emailKey = 'japen.email';

  Future<({String? token, String? email})> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (token: prefs.getString(tokenKey), email: prefs.getString(emailKey));
  }

  Future<void> write(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(emailKey, email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(emailKey);
  }
}
