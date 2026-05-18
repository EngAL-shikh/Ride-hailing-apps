import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/auth_store.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(
        RegExp(r'/*$'),
        '',
      ),
      _client = client ?? http.Client() {
    if (kDebugMode) {
      debugPrint('[ApiClient] Initialized with baseUrl: $baseUrl');
    }
  }

  Map<String, String> _headers({bool auth = false}) {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = AuthStore.token;
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    if (kDebugMode) {
      debugPrint('[API][request log][GET] Full URL: $uri');
      debugPrint('[API][request log][GET] Headers: ${_headers(auth: auth)}');
      debugPrint('[API][request log][GET] Query params: $query');
    }
    try {
      debugPrint('[API][request log][GET] Sending request to: $uri');
      final res = await _client
          .get(uri, headers: _headers(auth: auth))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[API][request log][GET] TIMEOUT for: $uri');
              throw ApiException(0, 'Connection timeout');
            },
          );
      if (kDebugMode) {
        debugPrint(
          '[API][request log][GET] Response status: ${res.statusCode}',
        );
        debugPrint(
          '[API][request log][GET] Response body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}',
        );
      }
      final body = res.body;
      if (body.isEmpty) {
        throw ApiException(res.statusCode, 'Empty response');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
        throw ApiException(
          res.statusCode,
          decoded['message']?.toString() ?? 'api_error',
        );
      }
      throw ApiException(res.statusCode, 'invalid_response');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API][GET] Error: $e');
      }
      if (e is ApiException) rethrow;
      throw ApiException(0, e.toString());
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    if (kDebugMode) {
      debugPrint('[API][request log][POST] Full URL: $uri');
      debugPrint(
        '[API][request log][POST] Request body: ${jsonEncode(body ?? {})}',
      );
      debugPrint('[API][request log][POST] Headers: ${_headers(auth: auth)}');
    }
    final res = await _client.post(
      uri,
      headers: _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    if (kDebugMode) {
      debugPrint('[API][request log][POST] Response status: ${res.statusCode}');
      debugPrint(
        '[API][request log][POST] Response body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(
        res.statusCode,
        decoded['message']?.toString() ?? 'api_error',
      );
    }
    throw ApiException(res.statusCode, 'invalid_response');
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? files, // fieldName: filePath
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      debugPrint('[API][request log][MULTIPART] Full URL: $uri');
      debugPrint('[API][request log][MULTIPART] Fields: $fields');
      debugPrint('[API][request log][MULTIPART] Files: $files');
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(auth: auth));
    
    // Auth headers are already set by _headers, but multipart needs 'multipart/form-data'
    // Actually http.MultipartRequest sets it automatically. 
    // We just need to make sure we don't force 'application/json'
    request.headers.remove('Content-Type');

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (var entry in files.entries) {
        if (entry.value.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
        }
      }
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      debugPrint('[API][request log][MULTIPART] Response status: ${res.statusCode}');
      debugPrint('[API][request log][MULTIPART] Response body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(
        res.statusCode,
        decoded['message']?.toString() ?? 'api_error',
      );
    }
    throw ApiException(res.statusCode, 'invalid_response');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
