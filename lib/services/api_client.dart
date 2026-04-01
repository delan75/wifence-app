import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth.dart';
import '../models/category.dart';
import '../models/dashboard.dart';
import '../models/device.dart';
import '../models/gateway.dart';
import '../models/gateway_preferences.dart';
import '../models/modes.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:8000';

  final http.Client _client;
  final String _baseUrl;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<GatewayMeta> fetchGatewayMeta() async {
    final response = await _client.get(
      Uri.parse(_baseUrl),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load gateway metadata');
    }

    return GatewayMeta.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SetupStatus> fetchSetupStatus() async {
    final response = await _client.get(Uri.parse('$_baseUrl/setup/status'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load setup status');
    }

    return SetupStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AuthSession> setupOwner({
    required String displayName,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/setup/owner'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'display_name': displayName,
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to set up owner'));
    }

    final session = AuthSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    setAccessToken(session.accessToken);
    return session;
  }

  Future<AuthSession> login({
    required String displayName,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'display_name': displayName,
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to log in'));
    }

    final session = AuthSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    setAccessToken(session.accessToken);
    return session;
  }

  Future<AuthUser> fetchMe() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load current user'));
    }

    return AuthUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to log out'));
    }
    setAccessToken(null);
  }

  Future<DashboardData> fetchDashboard() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/dashboard'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load dashboard'));
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
      headers: _jsonHeaders(),
      body: jsonEncode({'daily_limit_minutes': dailyLimitMinutes}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update quota'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> addCategoryPolicy(int deviceId, String categoryKey) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/devices/$deviceId/category-policies'),
      headers: _jsonHeaders(),
      body: jsonEncode({'category_key': categoryKey}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to add category rule'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> fetchDevice(int deviceId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/devices/$deviceId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load device'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<DiscoveryReport> refreshDiscovery() async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/discovery/refresh'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to refresh network discovery'));
    }

    return DiscoveryReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GatewayPreferences> fetchGatewayPreferences() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gateway/preferences'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load gateway preferences'));
    }

    return GatewayPreferences.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GatewayPreferences> updateGatewayPreferences(
    GatewayPreferences preferences,
  ) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/gateway/preferences'),
      headers: _jsonHeaders(),
      body: jsonEncode(preferences.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update gateway preferences'));
    }

    return GatewayPreferences.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<CategoryOption>> fetchCategories() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/categories'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load categories'));
    }

    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => CategoryOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ModesOverview> fetchModes() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/modes'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load routines'));
    }

    return ModesOverview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Device> updateSchedule({
    required int deviceId,
    required String name,
    required List<int> daysOfWeek,
    required int startsAtMinute,
    required int endsAtMinute,
    String? modeKey,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/devices/$deviceId/schedule'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'days_of_week': daysOfWeek,
        'starts_at_minute': startsAtMinute,
        'ends_at_minute': endsAtMinute,
        'mode_key': modeKey,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to save routine'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> clearSchedule(int deviceId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/devices/$deviceId/schedule'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to clear routine'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Profile>> fetchProfiles() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/profiles'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to load profiles'));
    }

    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Profile> createProfile({
    required String name,
    String? color,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/profiles'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'color': color,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to create profile'));
    }

    return Profile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Profile> updateProfile({
    required int profileId,
    String? name,
    String? color,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/profiles/$profileId'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (color != null) 'color': color,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update profile'));
    }

    return Profile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Device> updateDeviceProfile({
    required int deviceId,
    required int? profileId,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/devices/$deviceId'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'profile_id': profileId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update device profile'));
    }

    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateProfileSchedule({
    required int profileId,
    required String name,
    required List<int> daysOfWeek,
    required int startsAtMinute,
    required int endsAtMinute,
    String? modeKey,
  }) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/profiles/$profileId/schedule'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'days_of_week': daysOfWeek,
        'starts_at_minute': startsAtMinute,
        'ends_at_minute': endsAtMinute,
        'mode_key': modeKey,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to save profile routine'));
    }
  }

  Future<void> clearProfileSchedule(int profileId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/profiles/$profileId/schedule'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to clear profile routine'));
    }
  }

  Future<void> pauseProfile(int profileId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/profiles/$profileId/pause'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to pause profile'));
    }
  }

  Future<void> resumeProfile(int profileId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/profiles/$profileId/resume'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to resume profile'));
    }
  }

  Future<void> _post(String path) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Request failed'));
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Map<String, String> _jsonHeaders() {
    return {
      ..._headers(),
      'Content-Type': 'application/json',
    };
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Ignore parse errors and fall back to the provided message.
    }
    return fallback;
  }
}
