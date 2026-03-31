import 'package:flutter/material.dart';

import '../models/device.dart';
import '../theme/wifence_theme.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  final Device device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(device.status);
    final quota = _quotaProgress(device);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: WiFenceColors.line),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -10,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withValues(alpha: 0.09),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tone, tone.withValues(alpha: 0.72)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        device.isPaused ? Icons.pause_rounded : Icons.wifi_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            device.profile?.name ?? 'Unassigned',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _statusText(device.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tone,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        label: 'Today',
                        value: '${device.minutesUsedToday} min',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        label: 'IP',
                        value: device.currentIp ?? 'Not found',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily flow',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: quota,
                              minHeight: 10,
                              backgroundColor: WiFenceColors.line,
                              valueColor: AlwaysStoppedAnimation<Color>(tone),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.arrow_forward_rounded, color: tone),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _quotaProgress(Device device) {
    if (device.dailyLimitMinutes == null || device.dailyLimitMinutes == 0) {
      return 0.25;
    }
    return (device.minutesUsedToday / device.dailyLimitMinutes!).clamp(0.0, 1.0);
  }

  String _statusText(String status) {
    switch (status) {
      case 'paused':
        return 'Paused';
      case 'quota_exhausted':
        return 'Limit reached';
      case 'offline':
        return 'Offline';
      case 'needs_attention':
        return 'Needs check';
      default:
        return 'Open';
    }
  }

  Color _tone(String status) {
    switch (status) {
      case 'paused':
        return WiFenceColors.coral;
      case 'quota_exhausted':
        return const Color(0xFF9A5B2C);
      case 'offline':
        return const Color(0xFF7B8794);
      case 'needs_attention':
        return WiFenceColors.danger;
      default:
        return WiFenceColors.cobalt;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: WiFenceColors.deepSea,
                ),
          ),
        ],
      ),
    );
  }
}
