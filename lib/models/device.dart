class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.color,
  });

  final int id;
  final String name;
  final String? color;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String?,
    );
  }
}

class Policy {
  const Policy({
    required this.id,
    required this.policyType,
    required this.name,
    required this.enabled,
    this.dailyMinutes,
    this.categoryKey,
  });

  final int id;
  final String policyType;
  final String name;
  final bool enabled;
  final int? dailyMinutes;
  final String? categoryKey;

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as int,
      policyType: json['policy_type'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
      dailyMinutes: json['daily_minutes'] as int?,
      categoryKey: json['category_key'] as String?,
    );
  }
}

class Device {
  const Device({
    required this.id,
    required this.displayName,
    required this.isOnline,
    required this.isPaused,
    required this.minutesUsedToday,
    required this.identityConfidence,
    required this.status,
    this.hostname,
    this.currentIp,
    this.deviceType,
    this.dailyLimitMinutes,
    this.profile,
    this.policies = const [],
  });

  final int id;
  final String displayName;
  final String? hostname;
  final String? currentIp;
  final String? deviceType;
  final bool isOnline;
  final bool isPaused;
  final int? dailyLimitMinutes;
  final int minutesUsedToday;
  final int identityConfidence;
  final String status;
  final Profile? profile;
  final List<Policy> policies;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      hostname: json['hostname'] as String?,
      currentIp: json['current_ip'] as String?,
      deviceType: json['device_type'] as String?,
      isOnline: json['is_online'] as bool,
      isPaused: json['is_paused'] as bool,
      dailyLimitMinutes: json['daily_limit_minutes'] as int?,
      minutesUsedToday: json['minutes_used_today'] as int,
      identityConfidence: json['identity_confidence'] as int,
      status: json['status'] as String,
      profile: json['profile'] == null
          ? null
          : Profile.fromJson(json['profile'] as Map<String, dynamic>),
      policies: (json['policies'] as List<dynamic>? ?? [])
          .map((item) => Policy.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

