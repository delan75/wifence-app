import 'package:flutter/material.dart';

import '../models/category.dart';
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
    final categories = await widget.apiClient.fetchCategories();
    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<CategoryOption>(
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
              ...categories.map(
                (category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.label),
                  subtitle: Text(category.description),
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

    await widget.apiClient.addCategoryPolicy(device.id, selected.key);
    await _reload();
  }

  Future<void> _assignProfile(Device device) async {
    final profiles = await widget.apiClient.fetchProfiles();
    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<int?>(
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
                'Move to group',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose which household group this device belongs to.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('No group'),
                subtitle: const Text('Keep this device ungrouped.'),
                trailing: const Icon(Icons.remove_circle_outline_rounded),
                onTap: () => Navigator.of(context).pop(-1),
              ),
              ...profiles.map(
                (profile) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(profile.name),
                  subtitle: Text(profile.color ?? 'Local group'),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => Navigator.of(context).pop(profile.id),
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

    await widget.apiClient.updateDeviceProfile(
      deviceId: device.id,
      profileId: selected == -1 ? null : selected,
    );
    await _reload();
  }

  Future<void> _editAllowlist(Device device) async {
    final existingPolicy = _allowlistPolicy(device);
    final nameController = TextEditingController(
      text: existingPolicy?.name == 'Homework allowlist' ? '' : existingPolicy?.name ?? '',
    );
    final domainsController = TextEditingController(
      text: (existingPolicy?.domainList ?? const []).join('\n'),
    );
    var selectedMode = existingPolicy?.modeKey ?? 'study';

    final result = await showDialog<_AllowlistDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Homework allowlist'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Homework allowlist',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'When it should apply',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'study',
                        child: Text('Only during Study mode'),
                      ),
                      DropdownMenuItem(
                        value: 'always',
                        child: Text('Always on for this device'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: domainsController,
                    minLines: 6,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Approved domains',
                      hintText: 'school.example.com\nclassroom.google.com',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Only the listed sites stay reachable while this rule is active. Enter one domain per line.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (existingPolicy != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  const _AllowlistDraft(clear: true, domains: []),
                ),
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _AllowlistDraft(
                  clear: false,
                  name: nameController.text.trim(),
                  domains: domainsController.text
                      .split(RegExp(r'[\n,]'))
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                  modeKey: selectedMode == 'always' ? null : selectedMode,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.clear) {
      await widget.apiClient.clearAllowlist(device.id);
      await _reload();
      return;
    }

    if (result.domains.isEmpty) {
      return;
    }

    await widget.apiClient.updateAllowlist(
      deviceId: device.id,
      name: result.name.isEmpty ? null : result.name,
      domains: result.domains,
      modeKey: result.modeKey,
    );
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
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _assignProfile(device),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Move to group'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _editAllowlist(device),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Homework allowlist'),
              ),
              const SizedBox(height: 24),
              Text(
                'Today at a glance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Used',
                      value: '${device.minutesUsedToday} min',
                      accent: WiFenceColors.cobalt,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Limit',
                      value: device.dailyLimitMinutes == null
                          ? 'Open'
                          : '${device.dailyLimitMinutes} min',
                      accent: WiFenceColors.coral,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Download',
                      value: _formatBytes(device.bytesInToday),
                      accent: WiFenceColors.sky,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Upload',
                      value: _formatBytes(device.bytesOutToday),
                      accent: WiFenceColors.mint,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Blocked',
                      value: '${device.blockedDnsEventsToday}',
                      accent: WiFenceColors.coral,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _MetricTile(
                      label: 'Trust',
                      value: '${device.identityConfidence}%',
                      accent: WiFenceColors.mint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_allowlistPolicy(device) case final allowlist?)
                _AllowlistCard(policy: allowlist),
              if (_allowlistPolicy(device) != null) const SizedBox(height: 24),
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
                        label: _policyLabel(policy),
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

  Policy? _allowlistPolicy(Device device) {
    for (final policy in device.policies) {
      if (policy.policyType == 'domain_allowlist' && policy.enabled) {
        return policy;
      }
    }
    return null;
  }

  String _policyLabel(Policy policy) {
    if (policy.policyType == 'domain_allowlist') {
      final scope = policy.modeKey == null ? 'always on' : '${policy.modeKey} only';
      return '${policy.name} • ${policy.domainList.length} domains • $scope';
    }
    if (policy.categoryKey != null) {
      return policy.categoryKey!.replaceAll('_', ' ');
    }
    if (policy.dailyMinutes != null) {
      return '${policy.dailyMinutes} min per day';
    }
    return policy.name;
  }

  String _formatBytes(int value) {
    if (value >= 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    return '$value B';
  }
}

class _AllowlistDraft {
  const _AllowlistDraft({
    required this.clear,
    required this.domains,
    this.name = '',
    this.modeKey,
  });

  final bool clear;
  final String name;
  final List<String> domains;
  final String? modeKey;
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

class _AllowlistCard extends StatelessWidget {
  const _AllowlistCard({required this.policy});

  final Policy policy;

  @override
  Widget build(BuildContext context) {
    final modeLabel = policy.modeKey == null ? 'Always active' : 'Only during ${policy.modeKey}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD2EBDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WiFenceColors.mint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded, color: WiFenceColors.mint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: policy.domainList
                .map((domain) => _RulePill(label: domain))
                .toList(),
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
