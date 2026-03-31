import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.apiClient,
  });

  final int deviceId;
  final ApiClient apiClient;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Future<Device> _deviceFuture;

  static const List<String> _categoryOptions = [
    'social_media',
    'gaming',
    'streaming',
    'adult',
  ];

  @override
  void initState() {
    super.initState();
    _deviceFuture = widget.apiClient.fetchDevice(widget.deviceId);
  }

  Future<void> _reload() async {
    setState(() {
      _deviceFuture = widget.apiClient.fetchDevice(widget.deviceId);
    });
    await _deviceFuture;
  }

  Future<void> _togglePause(Device device) async {
    if (device.isPaused) {
      await widget.apiClient.resumeDevice(device.id);
    } else {
      await widget.apiClient.pauseDevice(device.id);
    }
    await _reload();
  }

  Future<void> _setQuota(Device device) async {
    final controller = TextEditingController(
      text: '${device.dailyLimitMinutes ?? 120}',
    );

    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily time limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes per day',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              int.tryParse(controller.text),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (value == null || value <= 0) {
      return;
    }

    await widget.apiClient.updateQuota(device.id, value);
    await _reload();
  }

  Future<void> _addCategory(Device device) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Block a category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              ..._categoryOptions.map(
                (category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.replaceAll('_', ' ')),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () => Navigator.of(context).pop(category),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    await widget.apiClient.addCategoryPolicy(device.id, selected);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WiFenceColors.canvas,
      appBar: AppBar(
        title: const Text('Device control'),
      ),
      body: FutureBuilder<Device>(
        future: _deviceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load device'));
          }

          final device = snapshot.data!;
          final usageProgress = _usageProgress(device);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _DeviceHero(device: device, usageProgress: usageProgress),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _togglePause(device),
                      style: FilledButton.styleFrom(
                        backgroundColor: device.isPaused
                            ? WiFenceColors.mint
                            : WiFenceColors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        device.isPaused ? 'Resume internet' : 'Pause internet',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setQuota(device),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Set limit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _addCategory(device),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Block category'),
              ),
              const SizedBox(height: 24),
              Text(
                'Today at a glance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Used',
                      value: '${device.minutesUsedToday} min',
                      accent: WiFenceColors.cobalt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Limit',
                      value: device.dailyLimitMinutes == null
                          ? 'Open'
                          : '${device.dailyLimitMinutes} min',
                      accent: WiFenceColors.coral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Trust',
                      value: '${device.identityConfidence}%',
                      accent: WiFenceColors.mint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Active rules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: device.policies
                    .map(
                      (policy) => _RulePill(
                        label: policy.categoryKey?.replaceAll('_', ' ') ??
                            (policy.dailyMinutes == null
                                ? policy.name
                                : '${policy.dailyMinutes} min per day'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (device.identityConfidence < 50)
                const _AttentionCard(
                  title: 'Identity is less stable',
                  description:
                      'This device may be using a private Wi-Fi address. Controls still work, but mapping can drift over time.',
                )
              else
                const _AttentionCard(
                  title: 'Control looks healthy',
                  description:
                      'This device has a strong identity match, so schedules and limits should behave predictably.',
                ),
            ],
          );
        },
      ),
    );
  }

  double _usageProgress(Device device) {
    if (device.dailyLimitMinutes == null || device.dailyLimitMinutes == 0) {
      return 0.24;
    }
    return (device.minutesUsedToday / device.dailyLimitMinutes!).clamp(0.0, 1.0);
  }
}

class _DeviceHero extends StatelessWidget {
  const _DeviceHero({
    required this.device,
    required this.usageProgress,
  });

  final Device device;
  final double usageProgress;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(device.status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            WiFenceColors.deepSea,
            tone.withValues(alpha: 0.86),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.profile?.name ?? 'Ungrouped device',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            device.displayName,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(label: device.currentIp ?? 'No IP'),
              _HeroBadge(label: _humanizeStatus(device.status)),
              if (device.deviceType != null) _HeroBadge(label: device.deviceType!),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Daily flow',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${(usageProgress * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: usageProgress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _humanizeStatus(String value) {
    return value.replaceAll('_', ' ');
  }

  static Color _tone(String status) {
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RulePill extends StatelessWidget {
  const _RulePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2D7B7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: WiFenceColors.coral.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline_rounded, color: WiFenceColors.coral),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WiFenceColors.ink,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
