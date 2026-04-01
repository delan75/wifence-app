import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/auth.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({
    super.key,
    required this.apiClient,
    required this.currentDeviceId,
  });

  final ApiClient apiClient;
  final String currentDeviceId;

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  static const _roles = ['manager', 'viewer', 'owner'];

  List<TrustedDevice> _devices = const [];
  PairingCodeSession? _pairingCode;
  bool _loading = true;
  bool _creatingCode = false;
  String _pairingRole = 'manager';
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
      final devices = await widget.apiClient.fetchTrustedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createPairingCode() async {
    setState(() {
      _creatingCode = true;
      _error = null;
    });

    try {
      final code = await widget.apiClient.createPairingCode(role: _pairingRole);
      if (!mounted) return;
      setState(() {
        _pairingCode = code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _creatingCode = false;
        });
      }
    }
  }

  Future<void> _revokeDevice(TrustedDevice device) async {
    try {
      await widget.apiClient.revokeTrustedDevice(device.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.displayName} revoked')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _updateRole(TrustedDevice device, String role) async {
    try {
      await widget.apiClient.updateTrustedDeviceRole(
        trustedDeviceId: device.id,
        role: role,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.displayName} is now $role')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WiFenceColors.canvas,
      appBar: AppBar(
        title: const Text('Trusted devices'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _TrustedBackground(),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _PairingHero(
                  creatingCode: _creatingCode,
                  pairingCode: _pairingCode,
                  pairingRole: _pairingRole,
                  roles: _roles,
                  onRoleChanged: (value) {
                    setState(() {
                      _pairingRole = value;
                    });
                  },
                  onCreateCode: _createPairingCode,
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TrustedError(message: _error!),
                  ),
                Text(
                  'Approved phones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Only approved devices can control WiFence. Role changes take effect on the next request.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ..._devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TrustedDeviceCard(
                      device: device,
                      roles: _roles,
                      isCurrent: device.deviceKey == widget.currentDeviceId,
                      onRoleSelected: (role) => _updateRole(device, role),
                      onRevoke: () => _revokeDevice(device),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrustedBackground extends StatelessWidget {
  const _TrustedBackground();

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
              color: WiFenceColors.sky.withValues(alpha: 0.14),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.mint.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PairingHero extends StatelessWidget {
  const _PairingHero({
    required this.creatingCode,
    required this.pairingCode,
    required this.pairingRole,
    required this.roles,
    required this.onRoleChanged,
    required this.onCreateCode,
  });

  final bool creatingCode;
  final PairingCodeSession? pairingCode;
  final String pairingRole;
  final List<String> roles;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onCreateCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1C2B), WiFenceColors.deepSea, WiFenceColors.cobalt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approve a new phone',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create a short-lived pass, choose its approval role, then let the new phone scan the QR code or type the code in manually.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: pairingRole,
                dropdownColor: WiFenceColors.deepSea,
                iconEnabledColor: Colors.white,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                items: roles
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          '${role[0].toUpperCase()}${role.substring(1)} approval',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onRoleChanged(value);
                  }
                },
              ),
            ),
          ),
          if (pairingCode != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: pairingCode!.pairingUri,
                        version: QrVersions.auto,
                        size: 190,
                        eyeStyle: const QrEyeStyle(
                          color: WiFenceColors.deepSea,
                          eyeShape: QrEyeShape.square,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: WiFenceColors.cobalt,
                          dataModuleShape: QrDataModuleShape.square,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current pairing code',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pairingCode!.pairingCode,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Approves as ${pairingCode!.assignedRole}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Expires at ${pairingCode!.expiresAt.toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: creatingCode ? null : onCreateCode,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: WiFenceColors.deepSea,
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(creatingCode ? 'Creating QR...' : 'Create pairing pass'),
          ),
        ],
      ),
    );
  }
}

class _TrustedDeviceCard extends StatelessWidget {
  const _TrustedDeviceCard({
    required this.device,
    required this.roles,
    required this.isCurrent,
    required this.onRoleSelected,
    required this.onRevoke,
  });

  final TrustedDevice device;
  final List<String> roles;
  final bool isCurrent;
  final ValueChanged<String> onRoleSelected;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isCurrent)
                _RoleChip(
                  label: 'This phone',
                  color: WiFenceColors.mint,
                  background: const Color(0xFFEAF8F1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoleChip(
                label: device.role,
                color: WiFenceColors.cobalt,
                background: WiFenceColors.cobalt.withValues(alpha: 0.12),
              ),
              _RoleChip(
                label: device.platform ?? 'Unknown platform',
                color: WiFenceColors.deepSea,
                background: const Color(0xFFF1F4F8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Last seen: ${device.lastSeenAt.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: onRoleSelected,
                    itemBuilder: (context) => roles
                        .map(
                          (role) => PopupMenuItem<String>(
                            value: role,
                            child: Text(
                              'Approve as ${role[0].toUpperCase()}${role.substring(1)}',
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: WiFenceColors.line),
                      ),
                      child: Text(
                        'Change approval',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: WiFenceColors.deepSea,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRevoke,
                    child: const Text('Revoke'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TrustedError extends StatelessWidget {
  const _TrustedError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WiFenceColors.ink,
            ),
      ),
    );
  }
}
