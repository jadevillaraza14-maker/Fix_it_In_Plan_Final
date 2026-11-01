import 'package:shared_preferences/shared_preferences.dart';

class RememberMe {
  static const _kRemember = 'remember_me';
  static const _kLogin = 'remembered_login';

  static Future<void> save(String login) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, true);
    await p.setString(_kLogin, login);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRemember);
    await p.remove(_kLogin);
  }

  static Future<String?> load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kRemember) != true) return null;
    return p.getString(_kLogin);
  }
}