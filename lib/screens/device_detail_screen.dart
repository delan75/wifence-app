import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/api_client.dart';

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
        title: const Text('Set daily time limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes per day'),
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
            child: const Text('Save'),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categoryOptions
              .map(
                (category) => ListTile(
                  title: Text(category.replaceAll('_', ' ')),
                  onTap: () => Navigator.of(context).pop(category),
                ),
              )
              .toList(),
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
      appBar: AppBar(title: const Text('Device')),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _HeaderCard(device: device),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _togglePause(device),
                style: FilledButton.styleFrom(
                  backgroundColor: device.isPaused
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(device.isPaused ? 'Resume internet' : 'Pause internet'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _setQuota(device),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Set daily limit'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _addCategory(device),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Block a category'),
              ),
              const SizedBox(height: 24),
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Used time',
                value: '${device.minutesUsedToday} minutes',
              ),
              _InfoRow(
                label: 'Daily limit',
                value: device.dailyLimitMinutes == null
                    ? 'Not set'
                    : '${device.dailyLimitMinutes} minutes',
              ),
              _InfoRow(
                label: 'Status',
                value: _humanizeStatus(device.status),
              ),
              _InfoRow(
                label: 'Trust level',
                value: '${device.identityConfidence}%',
              ),
              const SizedBox(height: 24),
              Text(
                'Rules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...device.policies.map(
                (policy) => Card(
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    title: Text(policy.name),
                    subtitle: Text(
                      policy.categoryKey?.replaceAll('_', ' ') ??
                          (policy.dailyMinutes == null
                              ? policy.policyType
                              : '${policy.dailyMinutes} minutes per day'),
                    ),
                  ),
                ),
              ),
              if (device.identityConfidence < 50) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'This device may be using a private Wi-Fi address. Control should still work, but identity may be less stable.',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _humanizeStatus(String value) {
    return value.replaceAll('_', ' ');
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(device.currentIp ?? 'No IP address'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: device.isOnline ? 'Online' : 'Offline'),
              if (device.profile != null) _Badge(label: device.profile!.name),
              if (device.deviceType != null) _Badge(label: device.deviceType!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5F2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

