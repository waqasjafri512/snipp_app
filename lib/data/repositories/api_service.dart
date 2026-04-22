import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = AppConstants.apiUrl;

  // Headers helper
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse('$_baseUrl$endpoint'), headers: headers);
  }

  // POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // PUT Request
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers);
  }

  // Auth specific methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  // Upload File (Multipart)
  Future<http.Response> uploadFile(String endpoint, String filePath, String fieldName) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
