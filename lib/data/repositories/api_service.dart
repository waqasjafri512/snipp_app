import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = AppConstants.apiUrl;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // Headers helper — automatically refreshes Firebase token if expired
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: AppConstants.tokenKey);

    // If the backend token is missing or if we have a Firebase user,
    // attempt to refresh via Firebase ID token
    if (token == null) {
      token = await _tryRefreshToken();
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Attempts to refresh the JWT by re-syncing the Firebase ID token
  /// with the backend. Returns the new token or null on failure.
  Future<String?> _tryRefreshToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      final idToken = await firebaseUser.getIdToken(true); // force refresh
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'username': firebaseUser.displayName ?? '',
          'full_name': firebaseUser.displayName ?? '',
          'avatar_url': firebaseUser.photoURL,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final newToken = data['data']['token'];
        await saveToken(newToken);
        return newToken;
      }
    } catch (e) {
      // Token refresh failed silently — caller will handle 401
    }
    return null;
  }

  // GET Request with auto-retry on 401
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
        .timeout(_timeout);

    // If 401, try refreshing token and retry once
    if (response.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        final retryHeaders = await _getHeaders();
        return await http
            .get(Uri.parse('$_baseUrl$endpoint'), headers: retryHeaders)
            .timeout(_timeout);
      }
    }
    return response;
  }

  // POST Request with auto-retry on 401
  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? customHeaders}) async {
    final headers = await _getHeaders();
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    final response = await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        final retryHeaders = await _getHeaders();
        if (customHeaders != null) retryHeaders.addAll(customHeaders);
        return await http
            .post(
              Uri.parse('$_baseUrl$endpoint'),
              headers: retryHeaders,
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      }
    }
    return response;
  }

  // PUT Request with auto-retry on 401
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        final retryHeaders = await _getHeaders();
        return await http
            .put(
              Uri.parse('$_baseUrl$endpoint'),
              headers: retryHeaders,
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      }
    }
    return response;
  }

  // DELETE Request with auto-retry on 401
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$_baseUrl$endpoint'), headers: headers)
        .timeout(_timeout);

    if (response.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        final retryHeaders = await _getHeaders();
        return await http
            .delete(Uri.parse('$_baseUrl$endpoint'), headers: retryHeaders)
            .timeout(_timeout);
      }
    }
    return response;
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

  // Upload File (Multipart) with auto-retry on 401
  Future<http.Response> uploadFile(
      String endpoint, String filePath, String fieldName) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamedResponse = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);

    // Retry upload on 401
    if (response.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        final retryRequest =
            http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
        retryRequest.headers['Authorization'] = 'Bearer $newToken';
        retryRequest.files
            .add(await http.MultipartFile.fromPath(fieldName, filePath));
        final retryStreamedResponse =
            await retryRequest.send().timeout(_uploadTimeout);
        return await http.Response.fromStream(retryStreamedResponse);
      }
    }

    return response;
  }
}
