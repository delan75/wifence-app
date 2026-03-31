import 'device.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.pausedDevices,
    required this.quotaExhaustedDevices,
    required this.ruleHitsToday,
  });

  final int totalDevices;
  final int onlineDevices;
  final int pausedDevices;
  final int quotaExhaustedDevices;
  final int ruleHitsToday;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDevices: json['total_devices'] as int,
      onlineDevices: json['online_devices'] as int,
      pausedDevices: json['paused_devices'] as int,
      quotaExhaustedDevices: json['quota_exhausted_devices'] as int,
      ruleHitsToday: json['rule_hits_today'] as int,
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.quickActions,
    required this.devices,
  });

  final DashboardStats stats;
  final List<String> quickActions;
  final List<Device> devices;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      quickActions: (json['quick_actions'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      devices: (json['devices'] as List<dynamic>)
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

