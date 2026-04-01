class GatewayMeta {
  const GatewayMeta({
    required this.appName,
    required this.version,
    required this.mode,
  });

  final String appName;
  final String version;
  final String mode;

  bool get isLiveMode => mode == 'live';

  factory GatewayMeta.fromJson(Map<String, dynamic> json) {
    return GatewayMeta(
      appName: json['app_name'] as String,
      version: json['version'] as String,
      mode: json['mode'] as String,
    );
  }
}

class GatewayConflict {
  const GatewayConflict({
    required this.code,
    required this.title,
    required this.summary,
    required this.severity,
    required this.blocking,
    required this.detectedSource,
    required this.resolution,
  });

  final String code;
  final String title;
  final String summary;
  final String severity;
  final bool blocking;
  final String detectedSource;
  final String resolution;

  factory GatewayConflict.fromJson(Map<String, dynamic> json) {
    return GatewayConflict(
      code: json['code'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      severity: json['severity'] as String,
      blocking: json['blocking'] as bool? ?? false,
      detectedSource: json['detected_source'] as String? ?? 'gateway',
      resolution: json['resolution'] as String? ?? '',
    );
  }
}

class GatewayReadiness {
  const GatewayReadiness({
    required this.checkedAt,
    required this.hostPlatform,
    required this.status,
    required this.enforcementBlocked,
    required this.conflictCount,
    required this.blockingConflictCount,
    required this.summary,
    required this.conflicts,
    this.advisory,
  });

  final DateTime checkedAt;
  final String hostPlatform;
  final String status;
  final bool enforcementBlocked;
  final int conflictCount;
  final int blockingConflictCount;
  final String summary;
  final String? advisory;
  final List<GatewayConflict> conflicts;

  bool get hasConflicts => conflictCount > 0;
  bool get hasBlockingConflicts => blockingConflictCount > 0;
  bool get isReady => status == 'ready';

  factory GatewayReadiness.fromJson(Map<String, dynamic> json) {
    return GatewayReadiness(
      checkedAt: DateTime.parse(json['checked_at'] as String),
      hostPlatform: json['host_platform'] as String,
      status: json['status'] as String,
      enforcementBlocked: json['enforcement_blocked'] as bool? ?? false,
      conflictCount: json['conflict_count'] as int? ?? 0,
      blockingConflictCount: json['blocking_conflict_count'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      advisory: json['advisory'] as String?,
      conflicts: (json['conflicts'] as List<dynamic>? ?? const [])
          .map((item) => GatewayConflict.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EnforcementArtifact {
  const EnforcementArtifact({
    required this.name,
    required this.path,
    required this.bytesWritten,
  });

  final String name;
  final String path;
  final int bytesWritten;

  factory EnforcementArtifact.fromJson(Map<String, dynamic> json) {
    return EnforcementArtifact(
      name: json['name'] as String,
      path: json['path'] as String,
      bytesWritten: json['bytes_written'] as int? ?? 0,
    );
  }
}

class EnforcementStatus {
  const EnforcementStatus({
    required this.mode,
    required this.canApplySystem,
    required this.dnsReloadConfigured,
    required this.dnsLockEnabled,
    required this.encryptedDnsHardeningEnabled,
    required this.conflictState,
    required this.enforcementBlocked,
    required this.managedDeviceCount,
    required this.blockedDeviceCount,
    required this.scheduledBlockCount,
    required this.quotaBlockCount,
    required this.categoryRuleCount,
    required this.encryptedDnsRuleCount,
    required this.conflicts,
    required this.artifacts,
    required this.message,
  });

  final String mode;
  final bool canApplySystem;
  final bool dnsReloadConfigured;
  final bool dnsLockEnabled;
  final bool encryptedDnsHardeningEnabled;
  final String conflictState;
  final bool enforcementBlocked;
  final int managedDeviceCount;
  final int blockedDeviceCount;
  final int scheduledBlockCount;
  final int quotaBlockCount;
  final int categoryRuleCount;
  final int encryptedDnsRuleCount;
  final List<GatewayConflict> conflicts;
  final List<EnforcementArtifact> artifacts;
  final String message;

  factory EnforcementStatus.fromJson(Map<String, dynamic> json) {
    return EnforcementStatus(
      mode: json['mode'] as String? ?? 'unknown',
      canApplySystem: json['can_apply_system'] as bool? ?? false,
      dnsReloadConfigured: json['dns_reload_configured'] as bool? ?? false,
      dnsLockEnabled: json['dns_lock_enabled'] as bool? ?? false,
      encryptedDnsHardeningEnabled:
          json['encrypted_dns_hardening_enabled'] as bool? ?? false,
      conflictState: json['conflict_state'] as String? ?? 'unknown',
      enforcementBlocked: json['enforcement_blocked'] as bool? ?? false,
      managedDeviceCount: json['managed_device_count'] as int? ?? 0,
      blockedDeviceCount: json['blocked_device_count'] as int? ?? 0,
      scheduledBlockCount: json['scheduled_block_count'] as int? ?? 0,
      quotaBlockCount: json['quota_block_count'] as int? ?? 0,
      categoryRuleCount: json['category_rule_count'] as int? ?? 0,
      encryptedDnsRuleCount: json['encrypted_dns_rule_count'] as int? ?? 0,
      conflicts: (json['conflicts'] as List<dynamic>? ?? const [])
          .map((item) => GatewayConflict.fromJson(item as Map<String, dynamic>))
          .toList(),
      artifacts: (json['artifacts'] as List<dynamic>? ?? const [])
          .map((item) => EnforcementArtifact.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }
}

class DiscoveryDevice {
  const DiscoveryDevice({
    required this.ip,
    required this.mac,
    required this.source,
    this.hostname,
    this.deviceType,
  });

  final String ip;
  final String mac;
  final String source;
  final String? hostname;
  final String? deviceType;

  factory DiscoveryDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveryDevice(
      ip: json['ip'] as String,
      mac: json['mac'] as String,
      source: json['source'] as String,
      hostname: json['hostname'] as String?,
      deviceType: json['device_type'] as String?,
    );
  }
}

class DiscoveryReport {
  const DiscoveryReport({
    required this.discoveredCount,
    required this.createdCount,
    required this.updatedCount,
    required this.source,
    required this.devices,
  });

  final int discoveredCount;
  final int createdCount;
  final int updatedCount;
  final String source;
  final List<DiscoveryDevice> devices;

  factory DiscoveryReport.fromJson(Map<String, dynamic> json) {
    return DiscoveryReport(
      discoveredCount: json['discovered_count'] as int,
      createdCount: json['created_count'] as int,
      updatedCount: json['updated_count'] as int,
      source: json['source'] as String,
      devices: (json['devices'] as List<dynamic>)
          .map((item) => DiscoveryDevice.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

