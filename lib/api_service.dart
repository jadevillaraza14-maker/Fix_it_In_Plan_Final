import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://steed-husband-drier.ngrok-free.dev/Fix_it_In_Plans_Api';
  // =========================================================
  // REGISTER
  // =========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String contact,
  }) async {
    try {
      final response = await http
          .post(
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
      )
          .timeout(
        const Duration(seconds: 15),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  // =========================================================
  // CLIENT PROJECTS
  // =========================================================

  static Future<List<Map<String, dynamic>>> getClientProjects(
      int clientId,
      ) async {
    final uri = Uri.parse('$baseUrl/client_projects.php').replace(
      queryParameters: {
        'client_id': clientId.toString(),
        'clientId': clientId.toString(),
      },
    );

    final response = await http
        .get(uri)
        .timeout(
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
          decoded['message']?.toString() ??
              'API request failed.',
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
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  static Future<Map<String, dynamic>> sendMessage({
    required int clientId,
    required String senderRole,
    required String message,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/send_message.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'sender_role': senderRole,
          'message': message,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  // =========================================================
  // GET CLIENT MESSAGES
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMessages({
    required int clientId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/get_messages.php',
      ).replace(
        queryParameters: {
          'client_id': clientId.toString(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map &&
          decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to get messages.',
        );
      }

      dynamic list = decoded;

      if (decoded is Map) {
        list = decoded['messages'] ??
            decoded['data'] ??
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
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } catch (e) {
      throw Exception(
        'Cannot connect to server.',
      );
    }
  }

  // =========================================================
  // GET ADMIN MESSAGES
  // =========================================================

  static Future<List<Map<String, dynamic>>> getAdminMessages() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/admin_messages.php'),
      )
          .timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map &&
          decoded['success'] == false) {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to get admin messages.',
        );
      }

      dynamic list = decoded;

      if (decoded is Map) {
        list = decoded['messages'] ??
            decoded['data'] ??
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
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } catch (e) {
      throw Exception(
        'Cannot connect to server.',
      );
    }
  }

  // ============================================================
// RESET PASSWORD
// ============================================================

  static Future<Map<String, dynamic>> resetPassword({
    required String account,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/reset_password.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'account': account,
          'new_password': newPassword,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
      );

      return jsonDecode(response.body)
      as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  // ============================================================
  // UPDATE PROJECT STATUS
  // ============================================================

  static Future<Map<String, dynamic>> updateProjectStatus({
    required int projectId,
    required String status,
    required int progress,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/update_project_status.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'project_id': projectId,
          'status': status,
          'progress': progress,
        }),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  static Future<Map<String, dynamic>> updateRevisionStatus({
    required int revisionId,
    required String status,
    required String engineerRemarks,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/update_revision.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'revision_id': revisionId,
          'status': status,
          'engineer_remarks': engineerRemarks,
        }),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  static Future<Map<String, dynamic>> saveFcmToken({
    required int clientId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_fcm_token.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'fcm_token': token,
        }),
      );

      return jsonDecode(response.body)
      as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  static Future<List<Map<String, dynamic>>> getTerms() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/client_terms.php'),
    )
        .timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to load terms.',
      );
    }

    dynamic list = decoded;

    if (decoded is Map) {
      list = decoded['clauses'] ?? [];
    }

    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  static Future<Map<String, dynamic>> saveAdminFcmToken({
    required String token,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/save_admin_fcm_token.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': token,
        }),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body)
      as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  static Future<Map<String, dynamic>> sendChatMessage({
    required int clientId,
    required String senderRole,
    required String message,
    List<String> filePaths = const [],
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/send_chat_message.php'),
      );

      request.fields['client_id'] = clientId.toString();
      request.fields['sender_role'] = senderRole;
      request.fields['message'] = message;

      for (final path in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files[]',
            path,
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final body = await streamed.stream.bytesToString();

      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': false,
        'message': 'Unexpected server response.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server. $e',
      };
    }
  }
  static Future<Map<String, dynamic>> changePassword({
    required int clientId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }
  static Future<Map<String, dynamic>> getNotificationSettings(
      int clientId,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '$baseUrl/notification_settings.php?client_id=$clientId',
        ),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

  static Future<Map<String, dynamic>> saveNotificationSettings({
    required int clientId,
    required bool enabled,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/notification_settings.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'notif_enabled': enabled ? 1 : 0,
        }),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server.',
      };
    }
  }

}