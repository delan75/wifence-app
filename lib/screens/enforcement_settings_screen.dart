import 'package:flutter/material.dart';

import '../models/gateway_preferences.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class EnforcementSettingsScreen extends StatefulWidget {
  const EnforcementSettingsScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<EnforcementSettingsScreen> createState() =>
      _EnforcementSettingsScreenState();
}

class _EnforcementSettingsScreenState extends State<EnforcementSettingsScreen> {
  GatewayPreferences? _preferences;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preferences = await widget.apiClient.fetchGatewayPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _save(GatewayPreferences preferences) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await widget.apiClient.updateGatewayPreferences(preferences);
      if (!mounted) return;
      setState(() {
        _preferences = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gateway enforcement settings updated')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error ?? 'Failed to save settings')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _addItem({
    required String title,
    required String hint,
    required List<String> existing,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WiFenceColors.card,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: hint,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text.trim()),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value == null || value.isEmpty) {
      return;
    }

    if (existing.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That item is already listed')),
      );
      return;
    }

    onChanged([...existing, value]);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;

    return Scaffold(
      backgroundColor: WiFenceColors.canvas,
      appBar: AppBar(
        title: const Text('Enforcement'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _SettingsBackground(),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null && preferences == null)
            _ErrorState(
              message: _error!,
              onRetry: _load,
            )
          else if (preferences != null)
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _HeroCard(
                  saving: _saving,
                  hardeningEnabled: preferences.hardenEncryptedDns,
                  canaryEnabled: preferences.enableDohCanaryDomain,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _InlineError(message: _error!),
                  ),
                _ToggleSection(
                  title: 'Encrypted DNS hardening',
                  subtitle:
                      'Block known resolver targets and keep managed devices on WiFence-controlled DNS paths.',
                  value: preferences.hardenEncryptedDns,
                  onChanged: (value) {
                    final updated = preferences.copyWith(
                      hardenEncryptedDns: value,
                    );
                    setState(() {
                      _preferences = updated;
                    });
                    _save(updated);
                  },
                ),
                const SizedBox(height: 14),
                _ToggleSection(
                  title: 'Firefox canary domain',
                  subtitle:
                      'Serve use-application-dns.net locally so compatible clients stay on network DNS.',
                  value: preferences.enableDohCanaryDomain,
                  onChanged: preferences.hardenEncryptedDns
                      ? (value) {
                          final updated = preferences.copyWith(
                            enableDohCanaryDomain: value,
                          );
                          setState(() {
                            _preferences = updated;
                          });
                          _save(updated);
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Custom resolver targets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add app-specific domains or IPs when a service bypasses the default provider list.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                _EditableTagSection(
                  title: 'Domains',
                  description:
                      'Examples: dns.example.com, resolver.myapp.net',
                  items: preferences.extraEncryptedDnsDomains,
                  accent: WiFenceColors.cobalt,
                  onAdd: () => _addItem(
                    title: 'Add resolver domain',
                    hint: 'dns.example.com',
                    existing: preferences.extraEncryptedDnsDomains,
                    onChanged: (items) {
                      final updated = preferences.copyWith(
                        extraEncryptedDnsDomains: items,
                      );
                      setState(() {
                        _preferences = updated;
                      });
                      _save(updated);
                    },
                  ),
                  onRemove: (item) {
                    final updated = preferences.copyWith(
                      extraEncryptedDnsDomains: preferences.extraEncryptedDnsDomains
                          .where((entry) => entry != item)
                          .toList(),
                    );
                    setState(() {
                      _preferences = updated;
                    });
                    _save(updated);
                  },
                ),
                const SizedBox(height: 14),
                _EditableTagSection(
                  title: 'IPv4 targets',
                  description:
                      'Direct IP endpoints for resolvers or app-embedded DNS services.',
                  items: preferences.extraEncryptedDnsIpv4,
                  accent: WiFenceColors.coral,
                  onAdd: () => _addItem(
                    title: 'Add IPv4 target',
                    hint: '203.0.113.10',
                    existing: preferences.extraEncryptedDnsIpv4,
                    onChanged: (items) {
                      final updated = preferences.copyWith(
                        extraEncryptedDnsIpv4: items,
                      );
                      setState(() {
                        _preferences = updated;
                      });
                      _save(updated);
                    },
                  ),
                  onRemove: (item) {
                    final updated = preferences.copyWith(
                      extraEncryptedDnsIpv4: preferences.extraEncryptedDnsIpv4
                          .where((entry) => entry != item)
                          .toList(),
                    );
                    setState(() {
                      _preferences = updated;
                    });
                    _save(updated);
                  },
                ),
                const SizedBox(height: 14),
                _EditableTagSection(
                  title: 'IPv6 targets',
                  description: 'Manual IPv6 resolver targets for advanced networks.',
                  items: preferences.extraEncryptedDnsIpv6,
                  accent: WiFenceColors.mint,
                  onAdd: () => _addItem(
                    title: 'Add IPv6 target',
                    hint: '2001:db8::10',
                    existing: preferences.extraEncryptedDnsIpv6,
                    onChanged: (items) {
                      final updated = preferences.copyWith(
                        extraEncryptedDnsIpv6: items,
                      );
                      setState(() {
                        _preferences = updated;
                      });
                      _save(updated);
                    },
                  ),
                  onRemove: (item) {
                    final updated = preferences.copyWith(
                      extraEncryptedDnsIpv6: preferences.extraEncryptedDnsIpv6
                          .where((entry) => entry != item)
                          .toList(),
                    );
                    setState(() {
                      _preferences = updated;
                    });
                    _save(updated);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.sky.withValues(alpha: 0.16),
            ),
          ),
        ),
        Positioned(
          top: 260,
          left: -60,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.coral.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.saving,
    required this.hardeningEnabled,
    required this.canaryEnabled,
  });

  final bool saving;
  final bool hardeningEnabled;
  final bool canaryEnabled;

  @override
  Widget build(BuildContext context) {
    final state = hardeningEnabled ? 'Active' : 'Relaxed';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1C2B), WiFenceColors.deepSea, WiFenceColors.cobalt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  saving ? 'Saving…' : state,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Resolver hardening',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tune how aggressively WiFence forces household devices back onto local DNS and known-safe resolver paths.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                label: hardeningEnabled ? 'Known DoH blocked' : 'Known DoH relaxed',
              ),
              _HeroPill(
                label: canaryEnabled ? 'Canary enabled' : 'Canary off',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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

class _ToggleSection extends StatelessWidget {
  const _ToggleSection({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EditableTagSection extends StatelessWidget {
  const _EditableTagSection({
    required this.title,
    required this.description,
    required this.items,
    required this.accent,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String description;
  final List<String> items;
  final Color accent;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add_circle_rounded, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'No custom entries yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WiFenceColors.ink,
                    ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.only(
                        left: 14,
                        right: 8,
                        top: 8,
                        bottom: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: WiFenceColors.ink,
                                ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onRemove(item),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: WiFenceColors.deepSea,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD0BF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: WiFenceColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WiFenceColors.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: WiFenceColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 32,
                color: WiFenceColors.coral,
              ),
              const SizedBox(height: 14),
              Text(
                'Could not load enforcement controls',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
