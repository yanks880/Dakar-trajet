import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  const ApiClient({required this.baseUrl});

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: {'Accept': 'application/json'});
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('API ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
