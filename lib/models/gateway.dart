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

