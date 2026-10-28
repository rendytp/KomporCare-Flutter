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

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

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
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi.');
    }
  }
}
