import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://10.10.10.77/Fix_it_In_Plans_Api';

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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'contact': contact,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getClientProjects(
      int clientId,
      ) async {
    final uri = Uri.parse('$baseUrl/client_projects.php').replace(
      queryParameters: {
        'client_id': clientId.toString(),
        'clientId': clientId.toString(),
      },
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    dynamic list = decoded;
    if (decoded is Map) {
      if (decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ?? 'API request failed.',
        );
      }

      list = decoded['projects'] ??
          decoded['data'] ??
          decoded['project'] ??
          [];
    }

    if (list is Map) {
      list = [list];
    }

    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
