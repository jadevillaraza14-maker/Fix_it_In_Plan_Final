import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://192.168.1.3/Fix_it_In_Plans_Api';

  // ============================================================
  // REGISTER CLIENT
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String contact,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'contact': contact,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
}