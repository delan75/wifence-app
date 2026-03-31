import 'package:flutter/material.dart';

import '../models/device.dart';

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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _badgeColor(device.status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                device.isPaused ? Icons.pause_circle : Icons.wifi,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(device),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF58615E),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _statusText(device.status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Device device) {
    final profile = device.profile?.name ?? 'Unassigned';
    if (device.dailyLimitMinutes == null) {
      return '$profile • ${device.minutesUsedToday} min today';
    }
    return '$profile • ${device.minutesUsedToday}/${device.dailyLimitMinutes} min';
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
        return 'Check';
      default:
        return 'Online';
    }
  }

  Color _badgeColor(String status) {
    switch (status) {
      case 'paused':
        return const Color(0xFFF97316);
      case 'quota_exhausted':
        return const Color(0xFFB45309);
      case 'offline':
        return const Color(0xFF64748B);
      case 'needs_attention':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }
}

