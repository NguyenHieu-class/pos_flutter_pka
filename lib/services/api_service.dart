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

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> _buildHeaders([Map<String, String>? additional]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (additional != null) {
      headers.addAll(additional);
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$apiBase$endpoint').replace(queryParameters: query);
    debugPrint('GET $uri');
    final response = await _client.get(uri, headers: _buildHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    final uri = Uri.parse('$apiBase$endpoint');
    debugPrint('POST $uri body: $body');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$apiBase$endpoint');
    debugPrint('PUT $uri body: $body');
    final response = await _client.put(
      uri,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('Response ${response.statusCode}: ${response.body}');
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['message'] != null
        ? body['message'] as String
        : 'Request failed with status: ${response.statusCode}';
    throw ApiException(message, statusCode: response.statusCode);
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
