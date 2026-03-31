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

class ModesOverview {
  const ModesOverview({
    required this.presets,
    required this.devices,
  });

  final List<ModePreset> presets;
  final List<Device> devices;

  factory ModesOverview.fromJson(Map<String, dynamic> json) {
    return ModesOverview(
      presets: (json['presets'] as List<dynamic>)
          .map((item) => ModePreset.fromJson(item as Map<String, dynamic>))
          .toList(),
      devices: (json['devices'] as List<dynamic>)
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
