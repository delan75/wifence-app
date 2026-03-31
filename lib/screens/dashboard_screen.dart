import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../models/gateway.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardPayload> _dashboardFuture;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardPayload> _loadDashboard() async {
    final results = await Future.wait([
      widget.apiClient.fetchGatewayMeta(),
      widget.apiClient.fetchDashboard(),
    ]);
    return _DashboardPayload(
      gatewayMeta: results[0] as GatewayMeta,
      dashboard: results[1] as DashboardData,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
  }

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final report = await widget.apiClient.refreshDiscovery();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan complete: ${report.discoveredCount} seen, ${report.createdCount} new, ${report.updatedCount} updated.',
          ),
        ),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network scan failed. Check that the local gateway is running.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardPayload>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              const _BrandBar(
                mode: 'offline',
                isLiveMode: false,
              ),
              const SizedBox(height: 22),
              _OfflineGatewayCard(
                onRetry: _refresh,
              ),
            ],
          );
        }

        final payload = snapshot.data!;
        final dashboard = payload.dashboard;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              _BrandBar(
                mode: payload.gatewayMeta.mode,
                isLiveMode: payload.gatewayMeta.isLiveMode,
              ),
              const SizedBox(height: 22),
              _ControlCenterCard(
                stats: dashboard.stats,
                gatewayMode: payload.gatewayMeta.mode,
              ),
              const SizedBox(height: 18),
              _DiscoveryStrip(
                isLiveMode: payload.gatewayMeta.isLiveMode,
                isScanning: _isScanning,
                onScan: _scanNetwork,
              ),
              const SizedBox(height: 18),
              _ShortcutRail(actions: dashboard.quickActions),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'People & devices',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${dashboard.devices.length} live',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dashboard.devices.isEmpty)
                _EmptyDiscoveryCard(
                  isScanning: _isScanning,
                  onScan: _scanNetwork,
                )
              else
                ...dashboard.devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DeviceCard(
                      device: device,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DeviceDetailScreen(
                              deviceId: device.id,
                              apiClient: widget.apiClient,
                            ),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({
    required this.mode,
    required this.isLiveMode,
  });

  final String mode;
  final bool isLiveMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [WiFenceColors.cobalt, WiFenceColors.sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WiFence',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Home internet, made understandable',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WiFenceColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: WiFenceColors.mint,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLiveMode ? 'Live' : mode == 'offline' ? 'Offline' : 'Demo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WiFenceColors.deepSea,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlCenterCard extends StatelessWidget {
  const _ControlCenterCard({
    required this.stats,
    required this.gatewayMode,
  });

  final DashboardStats stats;
  final String gatewayMode;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalDevices == 0 ? 1 : stats.totalDevices;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [WiFenceColors.deepSea, Color(0xFF1A3452), WiFenceColors.cobalt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gatewayMode == 'live' ? 'Live gateway' : 'Control center',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Household internet,\nunder control.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '${stats.onlineDevices} devices are active right now. ${stats.pausedDevices} are paused and ${stats.quotaExhaustedDevices} have hit their limit.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SignalTag(
                      label: 'Online',
                      value: '${stats.onlineDevices}',
                      accent: WiFenceColors.sky,
                    ),
                    _SignalTag(
                      label: 'Paused',
                      value: '${stats.pausedDevices}',
                      accent: WiFenceColors.coral,
                    ),
                    _SignalTag(
                      label: 'Rule hits',
                      value: '${stats.ruleHitsToday}',
                      accent: WiFenceColors.mint,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                height: 150,
                child: _SignalOrbit(
                  onlineRatio: stats.onlineDevices / total,
                  pausedRatio: stats.pausedDevices / total,
                  quotaRatio: stats.quotaExhaustedDevices / total,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoveryStrip extends StatelessWidget {
  const _DiscoveryStrip({
    required this.isLiveMode,
    required this.isScanning,
    required this.onScan,
  });

  final bool isLiveMode;
  final bool isScanning;
  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: WiFenceColors.mint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.radar_rounded, color: WiFenceColors.mint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiveMode ? 'Gateway discovery' : 'Demo gateway',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  isLiveMode
                      ? 'Scan the local network and pull fresh devices into WiFence.'
                      : 'Switch the gateway to live mode to discover real devices.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: isLiveMode && !isScanning ? () => onScan() : null,
            child: Text(isScanning ? 'Scanning...' : 'Scan'),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRail extends StatelessWidget {
  const _ShortcutRail({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final accents = [
      WiFenceColors.cobalt,
      WiFenceColors.coral,
      WiFenceColors.mint,
      const Color(0xFF8C6BFF),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fast moves',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                _ShortcutCard(
                  label: actions[i],
                  accent: accents[i % accents.length],
                ),
                if (i != actions.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.bolt_rounded, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'One tap, clear effect.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SignalTag extends StatelessWidget {
  const _SignalTag({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value $label',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SignalOrbit extends StatelessWidget {
  const _SignalOrbit({
    required this.onlineRatio,
    required this.pausedRatio,
    required this.quotaRatio,
  });

  final double onlineRatio;
  final double pausedRatio;
  final double quotaRatio;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SignalOrbitPainter(
        onlineRatio: onlineRatio,
        pausedRatio: pausedRatio,
        quotaRatio: quotaRatio,
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: const Icon(
            Icons.wifi_tethering_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _SignalOrbitPainter extends CustomPainter {
  const _SignalOrbitPainter({
    required this.onlineRatio,
    required this.pausedRatio,
    required this.quotaRatio,
  });

  final double onlineRatio;
  final double pausedRatio;
  final double quotaRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [70.0, 54.0, 38.0];
    final ratios = [onlineRatio, pausedRatio, quotaRatio];
    final colors = [
      WiFenceColors.sky,
      WiFenceColors.coral,
      WiFenceColors.mint,
    ];

    for (var i = 0; i < radii.length; i++) {
      final basePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 11
        ..color = Colors.white.withValues(alpha: 0.08);
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 11
        ..color = colors[i];
      final rect = Rect.fromCircle(center: center, radius: radii[i]);

      canvas.drawArc(rect, -math.pi * 0.78, math.pi * 1.56, false, basePaint);
      canvas.drawArc(
        rect,
        -math.pi * 0.78,
        math.pi * 1.56 * ratios[i].clamp(0.08, 1.0),
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalOrbitPainter oldDelegate) {
    return oldDelegate.onlineRatio != onlineRatio ||
        oldDelegate.pausedRatio != pausedRatio ||
        oldDelegate.quotaRatio != quotaRatio;
  }
}

class _OfflineGatewayCard extends StatelessWidget {
  const _OfflineGatewayCard({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: WiFenceColors.coral.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.portable_wifi_off_rounded,
              color: WiFenceColors.coral,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Gateway not reachable',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect the phone to the same Wi-Fi as the gateway, then pull to refresh.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () => onRetry(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiscoveryCard extends StatelessWidget {
  const _EmptyDiscoveryCard({
    required this.isScanning,
    required this.onScan,
  });

  final bool isScanning;
  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: WiFenceColors.cobalt.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.wifi_find_rounded, color: WiFenceColors.cobalt),
          ),
          const SizedBox(height: 18),
          Text(
            'No devices yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Run a network scan to let WiFence discover devices on the local gateway.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isScanning ? null : () => onScan(),
            child: Text(isScanning ? 'Scanning network...' : 'Scan network'),
          ),
        ],
      ),
    );
  }
}

class _DashboardPayload {
  const _DashboardPayload({
    required this.gatewayMeta,
    required this.dashboard,
  });

  final GatewayMeta gatewayMeta;
  final DashboardData dashboard;
}
