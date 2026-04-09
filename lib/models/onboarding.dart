import 'category.dart';
import 'device.dart';
import 'gateway.dart';

class OnboardingSummary {
  const OnboardingSummary({
    required this.gatewayMode,
    required this.canVerifyLiveControls,
    required this.verificationSummary,
    required this.readiness,
    required this.enforcement,
    required this.devices,
    required this.categories,
  });

  final String gatewayMode;
  final bool canVerifyLiveControls;
  final String verificationSummary;
  final GatewayReadiness readiness;
  final EnforcementStatus enforcement;
  final List<Device> devices;
  final List<CategoryOption> categories;

  factory OnboardingSummary.fromJson(Map<String, dynamic> json) {
    return OnboardingSummary(
      gatewayMode: json['gateway_mode'] as String? ?? 'live',
      canVerifyLiveControls: json['can_verify_live_controls'] as bool? ?? false,
      verificationSummary: json['verification_summary'] as String? ?? '',
      readiness: GatewayReadiness.fromJson(
        json['readiness'] as Map<String, dynamic>,
      ),
      enforcement: EnforcementStatus.fromJson(
        json['enforcement'] as Map<String, dynamic>,
      ),
      devices: (json['devices'] as List<dynamic>? ?? const [])
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((item) => CategoryOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
