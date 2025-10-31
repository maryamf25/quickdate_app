import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class SessionManager {
  static const String _boxName = 'loginBox';
  static const String _userKey = 'currentUser';
  static const String _tokenKey = 'accessToken';

  // Load token quickly without fully opening the box every time
  static Future<String?> getAccessToken() async {
    final box = await Hive.openBox(_boxName);
    final fromKey = box.get(_tokenKey) as String?;
    if (fromKey != null && fromKey.isNotEmpty) return fromKey;

    // fallback – try to read from stored user object
    final currentUser = box.get(_userKey);
    if (currentUser is Map && currentUser['access_token'] is String) {
      return currentUser['access_token'] as String;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(_userKey);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> setSession({
    required Map<String, dynamic> userData, // must include 'access_token'
  }) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_userKey, userData);
    await box.put(_tokenKey, userData['access_token'] ?? '');
  }

  static Future<void> clearSession() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_userKey);
    await box.delete(_tokenKey);
  }

  // Helpers to build authorized requests with the http package
  static Future<Map<String, String>> _authHeaders(
      {Map<String, String>? headers}) async {
    final token = await getAccessToken();
    final base = <String, String>{
      'Accept': 'application/json',
      if (headers?['Content-Type'] != null)
        'Content-Type': headers!['Content-Type']!
    };
    if (token != null && token.isNotEmpty) {
      base['Authorization'] = 'Bearer $token';
    }
    if (headers != null) base.addAll(headers);
    return base;
  }

  static Future<http.Response> get(Uri url,
      {Map<String, String>? headers}) async {
    return http.get(url, headers: await _authHeaders(headers: headers));
  }

  static Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return http.post(
      url,
      headers: await _authHeaders(headers: headers),
      body: body,
      encoding: encoding,
    );
  }

  static Future<void> logout(BuildContext context, {VoidCallback? onDone}) async {
    await clearSession();
    onDone?.call();
  }
}