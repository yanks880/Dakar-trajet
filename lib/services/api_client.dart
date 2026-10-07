import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  const ApiClient({required this.baseUrl});

  bool get configured => baseUrl.trim().isNotEmpty;

  Future<Map<String, dynamic>> getJson(String path) async {
    if (!configured) throw const ApiException('API non configurée');
    final uri = Uri.parse(baseUrl).resolve(path.startsWith('/') ? path.substring(1) : path);
    final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException('API ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) throw const ApiException('Réponse API invalide');
    return decoded;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
