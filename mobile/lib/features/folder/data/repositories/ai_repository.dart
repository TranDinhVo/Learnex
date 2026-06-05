import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/data/repositories/mock_auth_repository.dart';

class AiRepository {
  final String _baseUrl = 'http://localhost:8080/api';

  Future<String> chat({
    required String documentTitle,
    required String documentDescription,
    required String documentSubject,
    required List<Map<String, String>> messages,
  }) async {
    final token = MockAuthRepository.userToken;
    
    final response = await http.post(
      Uri.parse('$_baseUrl/ai/chat'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'documentTitle': documentTitle,
        'documentDescription': documentDescription,
        'documentSubject': documentSubject,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data']['reply'] as String;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to chat with AI');
      }
    } else {
      throw Exception('Failed to communicate with Learnex AI (Status: ${response.statusCode})');
    }
  }
}
