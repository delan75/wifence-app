import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import '../models/device.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:8000';

  final http.Client _client;
  final String _baseUrl;

  Future<DashboardData> fetchDashboard() async {
    final response = await _client.get(Uri.parse('$_baseUrl/dashboard'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard');
    }

    return DashboardData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Device> pauseDevice(int deviceId) async {
    await _post('/devices/$deviceId/pause');
    return fetchDevice(deviceId);
  }

  Future<Device> resumeDevice(int deviceId) async {
    await _post('/devices/$deviceId/resume');
    return fetchDevice(deviceId);
  }

  Future<Device> updateQuota(int deviceId, int dailyLimitMinutes) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/devices/$deviceId/quota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'daily_limit_minutes': dailyLimitMinutes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update quota');
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> addCategoryPolicy(int deviceId, String categoryKey) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/devices/$deviceId/category-policies'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'category_key': categoryKey}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add category rule');
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> fetchDevice(int deviceId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/devices/$deviceId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load device');
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> _post(String path) async {
    final response = await _client.post(Uri.parse('$_baseUrl$path'));
    if (response.statusCode != 200) {
      throw Exception('Request failed');
    }
  }
}

