import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wifence_app/screens/setup_wizard_screen.dart';
import 'package:wifence_app/services/api_client.dart';
import 'package:wifence_app/theme/wifence_theme.dart';

void main() {
  testWidgets('setup wizard loads the first onboarding step', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/onboarding/summary') {
        return http.Response(
          jsonEncode({
            'gateway_mode': 'live',
            'can_verify_live_controls': true,
            'verification_summary': 'Live verification is ready.',
            'readiness': {
              'checked_at': '2026-04-09T10:00:00Z',
              'host_platform': 'linux',
              'status': 'ready',
              'enforcement_blocked': false,
              'conflict_count': 0,
              'blocking_conflict_count': 0,
              'summary': 'Gateway is ready.',
              'advisory': null,
              'conflicts': [],
            },
            'enforcement': {
              'mode': 'live',
              'can_apply_system': true,
              'dns_reload_configured': true,
              'dns_lock_enabled': true,
              'encrypted_dns_hardening_enabled': true,
              'conflict_state': 'ready',
              'enforcement_blocked': false,
              'managed_device_count': 1,
              'blocked_device_count': 0,
              'scheduled_block_count': 0,
              'quota_block_count': 0,
              'category_rule_count': 0,
              'encrypted_dns_rule_count': 0,
              'conflicts': [],
              'artifacts': [],
              'message': 'Ready',
            },
            'devices': [
              {
                'id': 1,
                'display_name': 'John phone',
                'hostname': 'john-phone',
                'current_ip': '192.168.1.10',
                'current_mac': 'AA:BB:CC:DD:EE:FF',
                'device_type': 'phone',
                'is_online': true,
                'is_paused': false,
                'daily_limit_minutes': null,
                'minutes_used_today': 0,
                'bytes_in_today': 0,
                'bytes_out_today': 0,
                'blocked_dns_events_today': 0,
                'identity_confidence': 92,
                'status': 'online',
                'last_seen_at': '2026-04-09T10:00:00Z',
                'profile': null,
                'policies': [],
              }
            ],
            'categories': [
              {
                'key': 'social_media',
                'label': 'Social media',
                'description': 'Block distracting social networks.',
                'example_domains': ['facebook.com', 'instagram.com'],
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });

    final apiClient = ApiClient(
      client: client,
      baseUrl: 'https://wizard.test',
    );
    apiClient.setAccessToken('token');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildWiFenceTheme(),
        home: SetupWizardScreen(
          apiClient: apiClient,
          onClosed: (_) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Setup wizard'), findsOneWidget);
    expect(find.text('Check the gateway and scan the network'), findsOneWidget);
    expect(find.text('Scan network again'), findsOneWidget);
  });
}
