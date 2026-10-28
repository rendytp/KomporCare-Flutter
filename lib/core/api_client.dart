import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Error validasi per-field dari Laravel (422): {'email': 'Email sudah terdaftar.'}
  final Map<String, String> fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({this.token});

  String? token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send(() => http.delete(_uri(path), headers: _headers));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send(() => http.get(_uri(path, query), headers: _headers));
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(const Duration(seconds: 20));

      Map<String, dynamic> json = {};
      if (res.body.isNotEmpty) {
        try {
          json = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (res.statusCode >= 200 && res.statusCode < 300) return json;

      final fields = <String, String>{};
      if (json['errors'] is Map) {
        (json['errors'] as Map).forEach((k, v) {
          if (v is List && v.isNotEmpty) fields[k.toString()] = v.first.toString();
        });
      }
      throw ApiException(
        (json['message'] as String?) ?? 'Terjadi kesalahan (${res.statusCode}).',
        statusCode: res.statusCode,
        fieldErrors: fields,
      );
    } on SocketException {
      throw ApiException(
          'Tidak dapat terhubung ke ${AppConfig.apiBaseUrl}. Periksa koneksi atau alamat server.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi.');
    }
  }
}
