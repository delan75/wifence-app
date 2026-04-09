class AnalyticsDaySummary {
  const AnalyticsDaySummary({
    required this.dateKey,
    required this.weekdayLabel,
    required this.usageMinutes,
    required this.bytesIn,
    required this.bytesOut,
    required this.blockedDnsEventCount,
    required this.deviceCount,
    required this.activeDeviceCount,
    required this.profileCount,
    required this.scheduleHitCount,
    required this.quotaHitCount,
    required this.manualPauseCount,
  });

  final String dateKey;
  final String weekdayLabel;
  final int usageMinutes;
  final int bytesIn;
  final int bytesOut;
  final int blockedDnsEventCount;
  final int deviceCount;
  final int activeDeviceCount;
  final int profileCount;
  final int scheduleHitCount;
  final int quotaHitCount;
  final int manualPauseCount;

  factory AnalyticsDaySummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsDaySummary(
      dateKey: json['date_key'] as String,
      weekdayLabel: json['weekday_label'] as String,
      usageMinutes: json['usage_minutes'] as int? ?? 0,
      bytesIn: json['bytes_in'] as int? ?? 0,
      bytesOut: json['bytes_out'] as int? ?? 0,
      blockedDnsEventCount: json['blocked_dns_event_count'] as int? ?? 0,
      deviceCount: json['device_count'] as int? ?? 0,
      activeDeviceCount: json['active_device_count'] as int? ?? 0,
      profileCount: json['profile_count'] as int? ?? 0,
      scheduleHitCount: json['schedule_hit_count'] as int? ?? 0,
      quotaHitCount: json['quota_hit_count'] as int? ?? 0,
      manualPauseCount: json['manual_pause_count'] as int? ?? 0,
    );
  }
}

class AnalyticsProfileTrend {
  const AnalyticsProfileTrend({
    required this.profileName,
    required this.color,
    required this.deviceCount,
    required this.activeDays,
    required this.usageMinutes,
    required this.bytesIn,
    required this.bytesOut,
    required this.blockedDnsEventCount,
    required this.averageUsageMinutes,
    required this.scheduleHitCount,
    required this.quotaHitCount,
    required this.manualPauseCount,
  });

  final String profileName;
  final String? color;
  final int deviceCount;
  final int activeDays;
  final int usageMinutes;
  final int bytesIn;
  final int bytesOut;
  final int blockedDnsEventCount;
  final int averageUsageMinutes;
  final int scheduleHitCount;
  final int quotaHitCount;
  final int manualPauseCount;

  factory AnalyticsProfileTrend.fromJson(Map<String, dynamic> json) {
    return AnalyticsProfileTrend(
      profileName: json['profile_name'] as String,
      color: json['color'] as String?,
      deviceCount: json['device_count'] as int? ?? 0,
      activeDays: json['active_days'] as int? ?? 0,
      usageMinutes: json['usage_minutes'] as int? ?? 0,
      bytesIn: json['bytes_in'] as int? ?? 0,
      bytesOut: json['bytes_out'] as int? ?? 0,
      blockedDnsEventCount: json['blocked_dns_event_count'] as int? ?? 0,
      averageUsageMinutes: json['average_usage_minutes'] as int? ?? 0,
      scheduleHitCount: json['schedule_hit_count'] as int? ?? 0,
      quotaHitCount: json['quota_hit_count'] as int? ?? 0,
      manualPauseCount: json['manual_pause_count'] as int? ?? 0,
    );
  }
}

class AnalyticsDeviceTrend {
  const AnalyticsDeviceTrend({
    required this.deviceId,
    required this.displayName,
    required this.profileName,
    required this.currentStatus,
    required this.dailyLimitMinutes,
    required this.activeDays,
    required this.usageMinutes,
    required this.bytesIn,
    required this.bytesOut,
    required this.blockedDnsEventCount,
    required this.averageUsageMinutes,
    required this.scheduleHitCount,
    required this.quotaHitCount,
    required this.manualPauseCount,
  });

  final int deviceId;
  final String displayName;
  final String? profileName;
  final String? currentStatus;
  final int? dailyLimitMinutes;
  final int activeDays;
  final int usageMinutes;
  final int bytesIn;
  final int bytesOut;
  final int blockedDnsEventCount;
  final int averageUsageMinutes;
  final int scheduleHitCount;
  final int quotaHitCount;
  final int manualPauseCount;

  factory AnalyticsDeviceTrend.fromJson(Map<String, dynamic> json) {
    return AnalyticsDeviceTrend(
      deviceId: json['device_id'] as int? ?? 0,
      displayName: json['display_name'] as String,
      profileName: json['profile_name'] as String?,
      currentStatus: json['current_status'] as String?,
      dailyLimitMinutes: json['daily_limit_minutes'] as int?,
      activeDays: json['active_days'] as int? ?? 0,
      usageMinutes: json['usage_minutes'] as int? ?? 0,
      bytesIn: json['bytes_in'] as int? ?? 0,
      bytesOut: json['bytes_out'] as int? ?? 0,
      blockedDnsEventCount: json['blocked_dns_event_count'] as int? ?? 0,
      averageUsageMinutes: json['average_usage_minutes'] as int? ?? 0,
      scheduleHitCount: json['schedule_hit_count'] as int? ?? 0,
      quotaHitCount: json['quota_hit_count'] as int? ?? 0,
      manualPauseCount: json['manual_pause_count'] as int? ?? 0,
    );
  }
}

class AnalyticsWeekdayTrend {
  const AnalyticsWeekdayTrend({
    required this.weekdayIndex,
    required this.weekdayLabel,
    required this.usageMinutes,
    required this.bytesIn,
    required this.bytesOut,
    required this.blockedDnsEventCount,
    required this.scheduleHitCount,
    required this.quotaHitCount,
    required this.manualPauseCount,
  });

  final int weekdayIndex;
  final String weekdayLabel;
  final int usageMinutes;
  final int bytesIn;
  final int bytesOut;
  final int blockedDnsEventCount;
  final int scheduleHitCount;
  final int quotaHitCount;
  final int manualPauseCount;

  factory AnalyticsWeekdayTrend.fromJson(Map<String, dynamic> json) {
    return AnalyticsWeekdayTrend(
      weekdayIndex: json['weekday_index'] as int? ?? 0,
      weekdayLabel: json['weekday_label'] as String,
      usageMinutes: json['usage_minutes'] as int? ?? 0,
      bytesIn: json['bytes_in'] as int? ?? 0,
      bytesOut: json['bytes_out'] as int? ?? 0,
      blockedDnsEventCount: json['blocked_dns_event_count'] as int? ?? 0,
      scheduleHitCount: json['schedule_hit_count'] as int? ?? 0,
      quotaHitCount: json['quota_hit_count'] as int? ?? 0,
      manualPauseCount: json['manual_pause_count'] as int? ?? 0,
    );
  }
}

class HouseholdAnalyticsSnapshot {
  const HouseholdAnalyticsSnapshot({
    required this.generatedAt,
    required this.rangeDays,
    required this.today,
    required this.dailySummaries,
    required this.profileTrends,
    required this.deviceTrends,
    required this.weekdayTrends,
  });

  final DateTime generatedAt;
  final int rangeDays;
  final AnalyticsDaySummary today;
  final List<AnalyticsDaySummary> dailySummaries;
  final List<AnalyticsProfileTrend> profileTrends;
  final List<AnalyticsDeviceTrend> deviceTrends;
  final List<AnalyticsWeekdayTrend> weekdayTrends;

  factory HouseholdAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return HouseholdAnalyticsSnapshot(
      generatedAt: DateTime.parse(json['generated_at'] as String).toLocal(),
      rangeDays: json['range_days'] as int? ?? 14,
      today: AnalyticsDaySummary.fromJson(json['today'] as Map<String, dynamic>),
      dailySummaries: (json['daily_summaries'] as List<dynamic>? ?? const [])
          .map((item) => AnalyticsDaySummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      profileTrends: (json['profile_trends'] as List<dynamic>? ?? const [])
          .map((item) => AnalyticsProfileTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
      deviceTrends: (json['device_trends'] as List<dynamic>? ?? const [])
          .map((item) => AnalyticsDeviceTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
      weekdayTrends: (json['weekday_trends'] as List<dynamic>? ?? const [])
          .map((item) => AnalyticsWeekdayTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
