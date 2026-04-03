import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';
import 'audit_log_screen.dart';
import 'changelog_screen.dart';
import 'dashboard_screen.dart';
import 'enforcement_settings_screen.dart';
import 'modes_screen.dart';
import 'pulse_screen.dart';
import 'trusted_devices_screen.dart';

class WiFenceAppShell extends StatefulWidget {
  const WiFenceAppShell({
    super.key,
    required this.apiClient,
    required this.currentUser,
    required this.currentTrustedDevice,
    required this.currentDeviceId,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final AuthUser currentUser;
  final TrustedDevice? currentTrustedDevice;
  final String currentDeviceId;
  final Future<void> Function() onLogout;

  @override
  State<WiFenceAppShell> createState() => _WiFenceAppShellState();
}

class _WiFenceAppShellState extends State<WiFenceAppShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    DashboardScreen(apiClient: widget.apiClient),
    ModesScreen(apiClient: widget.apiClient),
    PulseScreen(
      apiClient: widget.apiClient,
      currentTrustedDevice: widget.currentTrustedDevice,
      onOpenModes: () {
        setState(() {
          _currentIndex = 1;
        });
      },
    ),
    _AccountStageScreen(
      currentUser: widget.currentUser,
      currentTrustedDevice: widget.currentTrustedDevice,
      onLogout: widget.onLogout,
      onOpenEnforcement: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EnforcementSettingsScreen(apiClient: widget.apiClient),
          ),
        );
      },
      onOpenTrustedDevices: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TrustedDevicesScreen(
              apiClient: widget.apiClient,
              currentDeviceId: widget.currentDeviceId,
            ),
          ),
        );
      },
      onOpenChangelog: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ChangelogScreen(),
          ),
        );
      },
      onOpenAuditLog: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AuditLogScreen(apiClient: widget.apiClient),
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundWash(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Padding(
                key: ValueKey(_currentIndex),
                padding: const EdgeInsets.only(bottom: 104),
                child: _pages[_currentIndex],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                onChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundWash extends StatelessWidget {
  const _BackgroundWash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: WiFenceColors.canvas),
        Positioned(
          top: -120,
          right: -30,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.sky.withValues(alpha: 0.22),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -90,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.coral.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.mint.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (label: 'Home', icon: Icons.home_rounded),
    (label: 'Modes', icon: Icons.tune_rounded),
    (label: 'Pulse', icon: Icons.insights_rounded),
    (label: 'More', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: WiFenceColors.deepSea,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: i == currentIndex
                        ? const LinearGradient(
                            colors: [WiFenceColors.cobalt, WiFenceColors.sky],
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[i].icon,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountStageScreen extends StatelessWidget {
  const _AccountStageScreen({
    required this.currentUser,
    required this.currentTrustedDevice,
    required this.onLogout,
    required this.onOpenEnforcement,
    required this.onOpenTrustedDevices,
    required this.onOpenChangelog,
    required this.onOpenAuditLog,
  });

  final AuthUser currentUser;
  final TrustedDevice? currentTrustedDevice;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenEnforcement;
  final VoidCallback onOpenTrustedDevices;
  final VoidCallback onOpenChangelog;
  final VoidCallback onOpenAuditLog;

  @override
  Widget build(BuildContext context) {
    final deviceRole = currentTrustedDevice?.role ?? 'viewer';
    final isOwner = deviceRole == 'owner';
    final canViewAudit = deviceRole == 'owner' || deviceRole == 'manager';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Gateway account',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (canViewAudit)
              IconButton(
                onPressed: onOpenAuditLog,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WiFenceColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WiFenceColors.line),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: WiFenceColors.deepSea,
                  ),
                ),
              ),
            if (isOwner)
              IconButton(
                onPressed: onOpenTrustedDevices,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WiFenceColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WiFenceColors.line),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: WiFenceColors.deepSea,
                  ),
                ),
              ),
            if (isOwner)
              IconButton(
                onPressed: onOpenEnforcement,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WiFenceColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WiFenceColors.line),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: WiFenceColors.deepSea,
                  ),
                ),
              ),
            IconButton(
              onPressed: onOpenChangelog,
              icon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: WiFenceColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WiFenceColors.line),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: WiFenceColors.deepSea,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This account stays on your local WiFence gateway.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: WiFenceColors.muted,
              ),
        ),
        const SizedBox(height: 24),
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
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: WiFenceColors.cobalt.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_rounded, color: WiFenceColors.cobalt),
              ),
              const SizedBox(height: 18),
              Text(
                currentUser.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                currentUser.role,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: WiFenceColors.cobalt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${deviceRole[0].toUpperCase()}${deviceRole.substring(1)} device approval',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WiFenceColors.cobalt,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => onLogout(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
