import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// A thin wrapper around the http client that adds logging and auth headers.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();
  String? _token;
  Future<void> Function()? onUnauthorized;

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> _buildHeaders({
    bool auth = true,
    Map<String, String>? additional,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      headers['X-Auth-Token'] = _token!;
    }
    if (additional != null) {
      headers.addAll(additional);
    }
    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? query,
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, query: query);
    debugPrint('GET $uri');
    final response = await _client.get(
      uri,
      headers: _buildHeaders(auth: auth, additional: headers),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('POST $uri body: $body');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(auth: auth, additional: headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('PUT $uri body: $body');
    final response = await _client.put(
      uri,
      headers: _buildHeaders(auth: auth, additional: headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('DELETE $uri body: $body');
    final request = http.Request('DELETE', uri)
      ..headers.addAll(_buildHeaders(auth: auth, additional: headers));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _client.send(request);
    final fullResponse = await http.Response.fromStream(response);
    return _handleResponse(fullResponse);
  }

  Future<dynamic> uploadFile(
    String endpoint, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    bool auth = true,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('UPLOAD $uri file: $filename');
    final request = http.MultipartRequest('POST', uri);
    final headers = _buildHeaders(auth: auth);
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
    ));
    final response = await request.send();
    final fullResponse = await http.Response.fromStream(response);
    return _handleResponse(fullResponse);
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    debugPrint('Response ${response.statusCode}: ${response.body}');
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final ok = decoded['ok'];
        final data = decoded['data'];
        if (ok == true && decoded.containsKey('data')) {
          return data;
        }
      }
      return decoded;
    }
    if (response.statusCode == 401) {
      if (onUnauthorized != null) {
        try {
          await onUnauthorized!.call();
        } catch (error, stackTrace) {
          debugPrint('Failed to handle unauthorized callback: $error\n$stackTrace');
        }
      }
    }
    String message = response.statusCode == 401
        ? 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.'
        : 'Request failed with status: ${response.statusCode}';
    if (decoded is Map<String, dynamic> && response.statusCode != 401) {
      message = decoded['message'] as String? ??
          decoded['error'] as String? ??
          message;
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Uri _buildUri(
    String endpoint, {
    Map<String, dynamic>? query,
  }) {
    final url = _resolveUrl(endpoint);
    final uri = Uri.parse(url);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  String _resolveUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    final base = apiBase.endsWith('/')
        ? apiBase.substring(0, apiBase.length - 1)
        : apiBase;
    final version = apiVersionPath.isEmpty
        ? ''
        : (apiVersionPath.startsWith('/')
            ? apiVersionPath
            : '/$apiVersionPath');
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$version$normalizedEndpoint';
  }
}

/// Exception thrown when an API request does not succeed.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
