import 'device.dart';

class ModePreset {
  const ModePreset({
    required this.key,
    required this.label,
    required this.description,
    required this.accent,
    required this.icon,
    required this.defaultDaysOfWeek,
    required this.defaultStartsAtMinute,
    required this.defaultEndsAtMinute,
  });

  final String key;
  final String label;
  final String description;
  final String accent;
  final String icon;
  final List<int> defaultDaysOfWeek;
  final int defaultStartsAtMinute;
  final int defaultEndsAtMinute;

  factory ModePreset.fromJson(Map<String, dynamic> json) {
    return ModePreset(
      key: json['key'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      accent: json['accent'] as String,
      icon: json['icon'] as String,
      defaultDaysOfWeek: (json['default_days_of_week'] as List<dynamic>)
          .map((item) => item as int)
          .toList(),
      defaultStartsAtMinute: json['default_starts_at_minute'] as int,
      defaultEndsAtMinute: json['default_ends_at_minute'] as int,
    );
  }
}

class ModeProfile {
  const ModeProfile({
    required this.id,
    required this.name,
    required this.deviceCount,
    required this.scheduledDeviceCount,
    this.color,
  });

  final int id;
  final String name;
  final String? color;
  final int deviceCount;
  final int scheduledDeviceCount;

  bool get hasRoutine => scheduledDeviceCount > 0;

  factory ModeProfile.fromJson(Map<String, dynamic> json) {
    return ModeProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String?,
      deviceCount: json['device_count'] as int,
      scheduledDeviceCount: json['scheduled_device_count'] as int,
    );
  }
}

class ModesOverview {
  const ModesOverview({
    required this.presets,
    required this.profiles,
    required this.devices,
  });

  final List<ModePreset> presets;
  final List<ModeProfile> profiles;
  final List<Device> devices;

  factory ModesOverview.fromJson(Map<String, dynamic> json) {
    return ModesOverview(
      presets: (json['presets'] as List<dynamic>)
          .map((item) => ModePreset.fromJson(item as Map<String, dynamic>))
          .toList(),
      profiles: (json['profiles'] as List<dynamic>)
          .map((item) => ModeProfile.fromJson(item as Map<String, dynamic>))
          .toList(),
      devices: (json['devices'] as List<dynamic>)
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
