import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../models/gateway.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';
import 'pairing_scanner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.apiClient,
    required this.deviceId,
    required this.deviceName,
    required this.devicePlatform,
    required this.onAuthenticated,
    this.initialReadiness,
    this.initialStatus,
    this.initialErrorMessage,
  });

  final ApiClient apiClient;
  final String deviceId;
  final String deviceName;
  final String devicePlatform;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final GatewayReadiness? initialReadiness;
  final SetupStatus? initialStatus;
  final String? initialErrorMessage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  SetupStatus? _setupStatus;
  GatewayReadiness? _readiness;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _readiness = widget.initialReadiness;
    _setupStatus = widget.initialStatus;
    _errorMessage = widget.initialErrorMessage;
    if (_setupStatus == null || _readiness == null) {
      _refreshStatus();
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _requiresOwnerSetup => _setupStatus?.requiresOwnerSetup ?? false;

  Future<void> _refreshStatus() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final readiness = await widget.apiClient.fetchGatewayReadiness();
      final status = await widget.apiClient.fetchSetupStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _readiness = readiness;
        _setupStatus = status;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not reach the local gateway. Make sure it is running on the same network.';
      });
    }
  }

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();
    final password = _passwordController.text;

    if (displayName.length < 2 || password.length < 8) {
      setState(() {
        _errorMessage = 'Enter a display name and a password with at least 8 characters.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final session = _requiresOwnerSetup
          ? await widget.apiClient.setupOwner(
              displayName: displayName,
              password: password,
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
              devicePlatform: widget.devicePlatform,
            )
          : await widget.apiClient.login(
              displayName: displayName,
              password: password,
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
              devicePlatform: widget.devicePlatform,
            );

      await widget.onAuthenticated(session);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _openPairingSheet() async {
    final controller = TextEditingController();
    final pairingCode = await showModalBottomSheet<String>(
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
                Text(
                  'Pair this phone',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the one-time pairing code from an already approved WiFence device.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Pairing code',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final scanned = await Navigator.of(context).push<String>(
                            MaterialPageRoute<String>(
                              builder: (_) => const PairingScannerScreen(),
                            ),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop(scanned);
                        },
                        child: const Text('Scan QR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text.trim()),
                        child: const Text('Pair phone'),
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

    if (pairingCode == null || pairingCode.isEmpty) {
      return;
    }

    final normalizedCode = _extractPairingCode(pairingCode);
    if (normalizedCode == null || normalizedCode.isEmpty) {
      setState(() {
        _errorMessage = 'That QR or code is not a valid WiFence pairing pass.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.apiClient.claimPairingCode(
        pairingCode: normalizedCode,
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        devicePlatform: widget.devicePlatform,
      );
      await widget.onAuthenticated(session);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String? _extractPairingCode(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.scheme == 'wifence') {
      final code = parsed.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return code.toUpperCase();
      }
    }
    return trimmed.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [WiFenceColors.cobalt, WiFenceColors.sky],
                        ),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WiFence', style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          'Local-first family internet control',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                if (_readiness != null) ...[
                  _GatewayReadinessCard(readiness: _readiness!),
                  const SizedBox(height: 18),
                ],
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: WiFenceColors.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: WiFenceColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _requiresOwnerSetup ? 'Create your local owner account' : 'Sign in to your gateway',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _requiresOwnerSetup
                            ? 'This is the first-time setup for your WiFence gateway. The account stays local to your network.'
                            : 'Use your local WiFence account to control the gateway.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: _requiresOwnerSetup ? 'Owner name' : 'Display name',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1E8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: WiFenceColors.ink,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(
                          _submitting
                              ? (_requiresOwnerSetup ? 'Creating account...' : 'Signing in...')
                              : (_requiresOwnerSetup ? 'Create owner account' : 'Sign in'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refreshStatus,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: const Text('Refresh gateway status'),
                      ),
                      if (!_requiresOwnerSetup) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _submitting ? null : _openPairingSheet,
                          child: const Text('Pair this phone with a code'),
                        ),
                      ],
                    ],
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

class _GatewayReadinessCard extends StatelessWidget {
  const _GatewayReadinessCard({
    required this.readiness,
  });

  final GatewayReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color chipColor;
    final String badge;
    switch (readiness.status) {
      case 'conflicted':
        accent = WiFenceColors.coral;
        chipColor = const Color(0xFFFFEFE9);
        badge = 'Conflicted';
        break;
      case 'warning':
        accent = const Color(0xFFBC7A19);
        chipColor = const Color(0xFFFFF5E5);
        badge = 'Review needed';
        break;
      default:
        accent = WiFenceColors.mint;
        chipColor = const Color(0xFFEAF8F1);
        badge = 'Ready';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  readiness.hasBlockingConflicts
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gateway readiness',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (readiness.advisory != null) ...[
            const SizedBox(height: 14),
            Text(
              readiness.advisory!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WiFenceColors.ink,
                  ),
            ),
          ],
          if (readiness.conflicts.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...readiness.conflicts.take(3).map(
              (conflict) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: conflict.blocking
                        ? const Color(0xFFFFF1EB)
                        : const Color(0xFFFFF8EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: WiFenceColors.ink,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        conflict.summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        conflict.resolution,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WiFenceColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: WiFenceColors.canvas),
        Positioned(
          top: -80,
          right: -30,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: WiFenceColors.sky.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: WiFenceColors.coral.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
