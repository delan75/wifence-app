import 'device.dart';
import 'gateway.dart';

class PulseProbe {
  const PulseProbe({
    required this.label,
    required this.host,
    required this.port,
    required this.reachable,
    this.latencyMs,
    this.error,
  });

  final String label;
  final String host;
  final int port;
  final bool reachable;
  final double? latencyMs;
  final String? error;

  factory PulseProbe.fromJson(Map<String, dynamic> json) {
    return PulseProbe(
      label: json['label'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      reachable: json['reachable'] as bool? ?? false,
      latencyMs: (json['latency_ms'] as num?)?.toDouble(),
      error: json['error'] as String?,
    );
  }
}

class PulseRecentEvent {
  const PulseRecentEvent({
    required this.id,
    required this.action,
    required this.summary,
    required this.createdAt,
    this.actorDisplayName,
  });

  final int id;
  final String action;
  final String summary;
  final DateTime createdAt;
  final String? actorDisplayName;

  factory PulseRecentEvent.fromJson(Map<String, dynamic> json) {
    return PulseRecentEvent(
      id: json['id'] as int,
      action: json['action'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      actorDisplayName: json['actor_display_name'] as String?,
    );
  }
}

class PulseInsight {
  const PulseInsight({
    required this.key,
    required this.title,
    required this.summary,
    required this.tone,
    this.actionLabel,
    this.actionRoute,
  });

  final String key;
  final String title;
  final String summary;
  final String tone;
  final String? actionLabel;
  final String? actionRoute;

  factory PulseInsight.fromJson(Map<String, dynamic> json) {
    return PulseInsight(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tone: json['tone'] as String? ?? 'cobalt',
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
    );
  }
}

class PulseStatusBreakdown {
  const PulseStatusBreakdown({
    required this.online,
    required this.paused,
    required this.quotaExhausted,
    required this.scheduledOff,
    required this.needsAttention,
    required this.offline,
  });

  final int online;
  final int paused;
  final int quotaExhausted;
  final int scheduledOff;
  final int needsAttention;
  final int offline;

  factory PulseStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return PulseStatusBreakdown(
      online: json['online'] as int? ?? 0,
      paused: json['paused'] as int? ?? 0,
      quotaExhausted: json['quota_exhausted'] as int? ?? 0,
      scheduledOff: json['scheduled_off'] as int? ?? 0,
      needsAttention: json['needs_attention'] as int? ?? 0,
      offline: json['offline'] as int? ?? 0,
    );
  }
}

class SpeedTestSnapshot {
  const SpeedTestSnapshot({
    required this.available,
    required this.configured,
    required this.running,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.sourceLabel,
    required this.message,
    this.measuredAt,
    this.downloadMbps,
    this.uploadMbps,
    this.latencyMs,
    this.error,
  });

  final bool available;
  final bool configured;
  final bool running;
  final DateTime? measuredAt;
  final double? downloadMbps;
  final double? uploadMbps;
  final double? latencyMs;
  final int downloadBytes;
  final int uploadBytes;
  final String sourceLabel;
  final String message;
  final String? error;

  factory SpeedTestSnapshot.fromJson(Map<String, dynamic> json) {
    return SpeedTestSnapshot(
      available: json['available'] as bool? ?? false,
      configured: json['configured'] as bool? ?? false,
      running: json['running'] as bool? ?? false,
      measuredAt: json['measured_at'] == null
          ? null
          : DateTime.parse(json['measured_at'] as String),
      downloadMbps: (json['download_mbps'] as num?)?.toDouble(),
      uploadMbps: (json['upload_mbps'] as num?)?.toDouble(),
      latencyMs: (json['latency_ms'] as num?)?.toDouble(),
      downloadBytes: json['download_bytes'] as int? ?? 0,
      uploadBytes: json['upload_bytes'] as int? ?? 0,
      sourceLabel: json['source_label'] as String? ?? 'gateway',
      message: json['message'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
}

class PulseSnapshot {
  const PulseSnapshot({
    required this.generatedAt,
    required this.gatewayMode,
    required this.hostPlatform,
    required this.overallState,
    required this.overallSummary,
    required this.reachableProbeCount,
    required this.probeCount,
    required this.enforcementMode,
    required this.dnsLockEnabled,
    required this.encryptedDnsHardeningEnabled,
    required this.canApplySystem,
    required this.deviceCount,
    required this.activeProfileCount,
    required this.ruleHitsToday,
    required this.statusBreakdown,
    required this.speedTest,
    required this.impactedDevices,
    required this.recentEvents,
    required this.probes,
    required this.insights,
    required this.readiness,
    this.medianLatencyMs,
  });

  final DateTime generatedAt;
  final String gatewayMode;
  final String hostPlatform;
  final String overallState;
  final String overallSummary;
  final double? medianLatencyMs;
  final int reachableProbeCount;
  final int probeCount;
  final String enforcementMode;
  final bool dnsLockEnabled;
  final bool encryptedDnsHardeningEnabled;
  final bool canApplySystem;
  final int deviceCount;
  final int activeProfileCount;
  final int ruleHitsToday;
  final PulseStatusBreakdown statusBreakdown;
  final SpeedTestSnapshot speedTest;
  final List<Device> impactedDevices;
  final List<PulseRecentEvent> recentEvents;
  final List<PulseProbe> probes;
  final List<PulseInsight> insights;
  final GatewayReadiness readiness;

  factory PulseSnapshot.fromJson(Map<String, dynamic> json) {
    return PulseSnapshot(
      generatedAt: DateTime.parse(json['generated_at'] as String),
      gatewayMode: json['gateway_mode'] as String? ?? 'live',
      hostPlatform: json['host_platform'] as String? ?? 'unknown',
      overallState: json['overall_state'] as String? ?? 'steady',
      overallSummary: json['overall_summary'] as String? ?? '',
      medianLatencyMs: (json['median_latency_ms'] as num?)?.toDouble(),
      reachableProbeCount: json['reachable_probe_count'] as int? ?? 0,
      probeCount: json['probe_count'] as int? ?? 0,
      enforcementMode: json['enforcement_mode'] as String? ?? 'unknown',
      dnsLockEnabled: json['dns_lock_enabled'] as bool? ?? false,
      encryptedDnsHardeningEnabled:
          json['encrypted_dns_hardening_enabled'] as bool? ?? false,
      canApplySystem: json['can_apply_system'] as bool? ?? false,
      deviceCount: json['device_count'] as int? ?? 0,
      activeProfileCount: json['active_profile_count'] as int? ?? 0,
      ruleHitsToday: json['rule_hits_today'] as int? ?? 0,
      statusBreakdown: PulseStatusBreakdown.fromJson(
        json['status_breakdown'] as Map<String, dynamic>,
      ),
      speedTest: SpeedTestSnapshot.fromJson(
        json['speed_test'] as Map<String, dynamic>,
      ),
      impactedDevices: (json['impacted_devices'] as List<dynamic>? ?? const [])
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentEvents: (json['recent_events'] as List<dynamic>? ?? const [])
          .map((item) => PulseRecentEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      probes: (json['probes'] as List<dynamic>? ?? const [])
          .map((item) => PulseProbe.fromJson(item as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>? ?? const [])
          .map((item) => PulseInsight.fromJson(item as Map<String, dynamic>))
          .toList(),
      readiness: GatewayReadiness.fromJson(
        json['readiness'] as Map<String, dynamic>,
      ),
    );
  }
}
