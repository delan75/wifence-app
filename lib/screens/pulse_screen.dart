import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../models/device.dart';
import '../models/pulse.dart';
import '../services/api_client.dart';
import '../services/phone_speed_test_service.dart';
import '../theme/wifence_theme.dart';
import 'audit_log_screen.dart';
import 'device_detail_screen.dart';
import 'enforcement_settings_screen.dart';

class PulseScreen extends StatefulWidget {
  const PulseScreen({
    super.key,
    required this.apiClient,
    required this.currentTrustedDevice,
    required this.onOpenModes,
  });

  final ApiClient apiClient;
  final TrustedDevice? currentTrustedDevice;
  final VoidCallback onOpenModes;

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen> {
  late Future<PulseSnapshot> _future;
  final PhoneSpeedTestService _phoneSpeedTestService = PhoneSpeedTestService();
  bool _runningSpeedTest = false;
  bool _runningPhoneSpeedTest = false;
  PhoneSpeedTestResult? _phoneSpeedTestResult;
  String? _phoneSpeedTestError;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.fetchPulse();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.apiClient.fetchPulse();
    });
    await _future;
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _runningSpeedTest = true;
    });
    try {
      final snapshot = await widget.apiClient.runPulseSpeedTest();
      if (!mounted) return;
      final message = snapshot.error == null ? snapshot.message : '${snapshot.message} ${snapshot.error!}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _runningSpeedTest = false;
        });
      }
    }
  }

  Future<void> _runPhoneSpeedTest() async {
    setState(() {
      _runningPhoneSpeedTest = true;
      _phoneSpeedTestError = null;
    });
    try {
      final result = await _phoneSpeedTestService.runFastComCheck();
      if (!mounted) return;
      setState(() {
        _phoneSpeedTestResult = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone speed check completed')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phoneSpeedTestError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _runningPhoneSpeedTest = false;
        });
      }
    }
  }

  Future<void> _handleInsightAction(PulseInsight insight, PulseSnapshot pulse) async {
    switch (insight.actionRoute) {
      case 'enforcement':
        if (_canOpenEnforcement) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EnforcementSettingsScreen(apiClient: widget.apiClient),
            ),
          );
        }
        break;
      case 'audit':
        if (_canViewAudit) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AuditLogScreen(apiClient: widget.apiClient),
            ),
          );
        }
        break;
      case 'devices':
        if (pulse.impactedDevices.isNotEmpty) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeviceDetailScreen(
                deviceId: pulse.impactedDevices.first.id,
                apiClient: widget.apiClient,
              ),
            ),
          );
        }
        break;
      case 'modes':
        widget.onOpenModes();
        break;
    }
  }

  bool get _canViewAudit {
    final role = widget.currentTrustedDevice?.role ?? 'viewer';
    return role == 'owner' || role == 'manager';
  }

  bool get _canOpenEnforcement => (widget.currentTrustedDevice?.role ?? 'viewer') == 'owner';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PulseSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        return RefreshIndicator(
          color: WiFenceColors.cobalt,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network pulse',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Live gateway status, line checks, and where the pressure is landing.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: WiFenceColors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : () {
                            _refresh();
                          },
                    icon: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: WiFenceColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WiFenceColors.line),
                      ),
                      child: const Icon(Icons.sync_rounded, color: WiFenceColors.deepSea),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _PulseLoadingState()
              else if (snapshot.hasError)
                _PulseErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () {
                    _refresh();
                  },
                )
              else if (snapshot.hasData)
                _PulseLoadedState(
                  pulse: snapshot.data!,
                  canOpenEnforcement: _canOpenEnforcement,
                  canViewAudit: _canViewAudit,
                  onOpenEnforcement: _canOpenEnforcement
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  EnforcementSettingsScreen(apiClient: widget.apiClient),
                            ),
                          );
                        }
                      : null,
                  onOpenAudit: _canViewAudit
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AuditLogScreen(apiClient: widget.apiClient),
                            ),
                          );
                        }
                      : null,
                  onInsightAction: (insight) => _handleInsightAction(insight, snapshot.data!),
                  onOpenDevice: (deviceId) async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DeviceDetailScreen(
                          deviceId: deviceId,
                          apiClient: widget.apiClient,
                        ),
                      ),
                    );
                    await _refresh();
                  },
                  gatewaySpeedTestBusy: _runningSpeedTest,
                  onRunSpeedTest: _runSpeedTest,
                  phoneSpeedTestBusy: _runningPhoneSpeedTest,
                  phoneSpeedTestResult: _phoneSpeedTestResult,
                  phoneSpeedTestError: _phoneSpeedTestError,
                  onRunPhoneSpeedTest: _runPhoneSpeedTest,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseLoadedState extends StatelessWidget {
  const _PulseLoadedState({
    required this.pulse,
    required this.canOpenEnforcement,
    required this.canViewAudit,
    required this.onInsightAction,
    required this.onOpenDevice,
    required this.gatewaySpeedTestBusy,
    required this.onRunSpeedTest,
    required this.phoneSpeedTestBusy,
    required this.onRunPhoneSpeedTest,
    required this.phoneSpeedTestResult,
    required this.phoneSpeedTestError,
    this.onOpenEnforcement,
    this.onOpenAudit,
  });

  final PulseSnapshot pulse;
  final bool canOpenEnforcement;
  final bool canViewAudit;
  final Future<void> Function(PulseInsight insight) onInsightAction;
  final Future<void> Function(int deviceId) onOpenDevice;
  final bool gatewaySpeedTestBusy;
  final Future<void> Function() onRunSpeedTest;
  final bool phoneSpeedTestBusy;
  final Future<void> Function() onRunPhoneSpeedTest;
  final PhoneSpeedTestResult? phoneSpeedTestResult;
  final String? phoneSpeedTestError;
  final VoidCallback? onOpenEnforcement;
  final VoidCallback? onOpenAudit;

  Color get _stateColor {
    switch (pulse.overallState) {
      case 'steady':
        return WiFenceColors.mint;
      case 'watch':
        return WiFenceColors.sky;
      case 'pressure':
        return WiFenceColors.coral;
      case 'blocked':
      case 'disconnected':
        return WiFenceColors.danger;
      default:
        return WiFenceColors.cobalt;
    }
  }

  String get _stateLabel {
    switch (pulse.overallState) {
      case 'steady':
        return 'Steady';
      case 'watch':
        return 'Watch';
      case 'pressure':
        return 'Pressure';
      case 'blocked':
        return 'Blocked';
      case 'disconnected':
        return 'Disconnected';
      default:
        return 'Live';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: WiFenceColors.line),
            boxShadow: [
              BoxShadow(
                color: _stateColor.withValues(alpha: 0.08),
                blurRadius: 36,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _stateColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _stateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _stateColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${pulse.generatedAt.hour.toString().padLeft(2, '0')}:${pulse.generatedAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                pulse.overallSummary,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Median latency',
                      value: pulse.medianLatencyMs == null
                          ? 'No reply'
                          : '${pulse.medianLatencyMs!.round()} ms',
                      accent: WiFenceColors.cobalt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Probe replies',
                      value: '${pulse.reachableProbeCount}/${pulse.probeCount}',
                      accent: WiFenceColors.sky,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Online now',
                      value: '${pulse.statusBreakdown.online}',
                      accent: WiFenceColors.mint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Rules active',
                      value:
                          '${pulse.statusBreakdown.paused + pulse.statusBreakdown.scheduledOff + pulse.statusBreakdown.quotaExhausted}',
                      accent: WiFenceColors.coral,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Speed checks'),
        const SizedBox(height: 12),
        _SpeedTestCard(
          title: 'Gateway speed check',
          subtitle: 'Measures the gateway path, which is the path WiFence is actually controlling.',
          speedTest: pulse.speedTest,
          busy: gatewaySpeedTestBusy,
          actionLabel: gatewaySpeedTestBusy ? 'Running…' : 'Run gateway',
          onRun: gatewaySpeedTestBusy ? null : onRunSpeedTest,
        ),
        const SizedBox(height: 12),
        _PhoneSpeedTestCard(
          result: phoneSpeedTestResult,
          error: phoneSpeedTestError,
          busy: phoneSpeedTestBusy,
          onRun: phoneSpeedTestBusy ? null : onRunPhoneSpeedTest,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SignalCard(
                title: 'Enforcement',
                value: pulse.enforcementMode,
                detail: pulse.canApplySystem ? 'Can apply live' : 'Dry run or blocked',
                accent: pulse.canApplySystem ? WiFenceColors.mint : WiFenceColors.coral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SignalCard(
                title: 'Resolver path',
                value: pulse.dnsLockEnabled ? 'Locked' : 'Open',
                detail: pulse.encryptedDnsHardeningEnabled
                    ? 'Encrypted DNS hardening on'
                    : 'Hardening off',
                accent: pulse.dnsLockEnabled ? WiFenceColors.cobalt : WiFenceColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SignalCard(
                title: 'Profiles',
                value: '${pulse.activeProfileCount}',
                detail: '${pulse.deviceCount} devices tracked',
                accent: WiFenceColors.sky,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SignalCard(
                title: 'Readiness',
                value: pulse.readiness.status,
                detail: pulse.readiness.summary,
                accent: pulse.readiness.enforcementBlocked
                    ? WiFenceColors.danger
                    : pulse.readiness.status == 'warning'
                        ? WiFenceColors.coral
                        : WiFenceColors.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          title: 'What stands out',
          actionLabel: canOpenEnforcement
              ? 'Enforcement'
              : canViewAudit
                  ? 'Audit'
                  : null,
          onAction: canOpenEnforcement
              ? onOpenEnforcement
              : canViewAudit
                  ? onOpenAudit
                  : null,
        ),
        const SizedBox(height: 12),
        ...pulse.insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InsightCard(
              insight: insight,
              onTap: insight.actionRoute == null ? null : () => onInsightAction(insight),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Affected devices'),
        const SizedBox(height: 12),
        if (pulse.impactedDevices.isEmpty)
          const _EmptyStateCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'No device friction right now',
            summary: 'Pulse did not find paused, quota-exhausted, scheduled-off, or identity-warning devices.',
          )
        else
          ...pulse.impactedDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DevicePulseCard(
                device: device,
                onTap: () => onOpenDevice(device.id),
              ),
            ),
          ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Line checks'),
        const SizedBox(height: 12),
        ...pulse.probes.map(
          (probe) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProbeCard(probe: probe),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Recent gateway changes',
          actionLabel: canViewAudit ? 'Open audit' : null,
          onAction: canViewAudit ? onOpenAudit : null,
        ),
        const SizedBox(height: 12),
        if (pulse.recentEvents.isEmpty)
          const _EmptyStateCard(
            icon: Icons.history_toggle_off_rounded,
            title: 'No recent changes',
            summary: 'Pulse did not receive any recent gateway actions to show here.',
          )
        else
          ...pulse.recentEvents.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventCard(event: event),
            ),
          ),
      ],
    );
  }
}

class _PulseLoadingState extends StatelessWidget {
  const _PulseLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          height: index == 0 ? 180 : 96,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: WiFenceColors.line),
          ),
        ),
      ),
    );
  }
}

class _PulseErrorState extends StatelessWidget {
  const _PulseErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: WiFenceColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.portable_wifi_off_rounded, color: WiFenceColors.danger),
          ),
          const SizedBox(height: 18),
          Text(
            'Pulse is unavailable right now',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
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
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: WiFenceColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final String title;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SpeedTestCard extends StatelessWidget {
  const _SpeedTestCard({
    required this.title,
    required this.subtitle,
    required this.speedTest,
    required this.busy,
    required this.actionLabel,
    required this.onRun,
  });

  final String title;
  final String subtitle;
  final SpeedTestSnapshot speedTest;
  final bool busy;
  final String actionLabel;
  final Future<void> Function()? onRun;

  String _formatMbps(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} Mbps';
  }

  String _formatLatency(double? value) {
    if (value == null) return '--';
    return '${value.round()} ms';
  }

  @override
  Widget build(BuildContext context) {
    final accent = speedTest.error != null
        ? WiFenceColors.danger
        : speedTest.configured
            ? WiFenceColors.cobalt
            : WiFenceColors.coral;
    final measuredLabel = speedTest.measuredAt == null
        ? 'No measurement yet'
        : 'Last run ${speedTest.measuredAt!.hour.toString().padLeft(2, '0')}:${speedTest.measuredAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(22),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(Icons.speed_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '$measuredLabel • $subtitle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Download',
                  value: _formatMbps(speedTest.downloadMbps),
                  accent: WiFenceColors.cobalt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Upload',
                  value: _formatMbps(speedTest.uploadMbps),
                  accent: WiFenceColors.sky,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Ping',
                  value: _formatLatency(speedTest.latencyMs),
                  accent: WiFenceColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            speedTest.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (speedTest.error != null) ...[
            const SizedBox(height: 8),
            Text(
              speedTest.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WiFenceColors.danger,
                  ),
            ),
          ],
          if (!speedTest.configured) ...[
            const SizedBox(height: 8),
            Text(
              'Set gateway speed-test URLs first. This uses the gateway path, not the phone connection.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onRun == null
                  ? null
                  : () {
                      onRun!();
                    },
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneSpeedTestCard extends StatelessWidget {
  const _PhoneSpeedTestCard({
    required this.result,
    required this.error,
    required this.busy,
    required this.onRun,
  });

  final PhoneSpeedTestResult? result;
  final String? error;
  final bool busy;
  final Future<void> Function()? onRun;

  String _formatMbps(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} Mbps';
  }

  @override
  Widget build(BuildContext context) {
    final accent = error != null
        ? WiFenceColors.danger
        : result != null
            ? WiFenceColors.mint
            : WiFenceColors.sky;

    return Container(
      padding: const EdgeInsets.all(22),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(Icons.phone_android_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone speed check', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Measures the phone directly using a Fast.com-backed Flutter plugin.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Download',
                  value: _formatMbps(result?.downloadMbps),
                  accent: WiFenceColors.cobalt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Upload',
                  value: _formatMbps(result?.uploadMbps),
                  accent: WiFenceColors.sky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Use this when you want to compare what the phone sees versus what the gateway sees.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: error == null ? WiFenceColors.muted : WiFenceColors.danger,
                ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onRun == null
                  ? null
                  : () {
                      onRun!();
                    },
              child: Text(busy ? 'Running…' : 'Run phone'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    this.onTap,
  });

  final PulseInsight insight;
  final VoidCallback? onTap;

  Color get _toneColor {
    switch (insight.tone) {
      case 'danger':
        return WiFenceColors.danger;
      case 'warning':
        return WiFenceColors.coral;
      case 'mint':
        return WiFenceColors.mint;
      case 'cobalt':
      default:
        return WiFenceColors.cobalt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WiFenceColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _toneColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_graph_rounded, color: _toneColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    insight.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (insight.actionLabel != null && onTap != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      insight.actionLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _toneColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicePulseCard extends StatelessWidget {
  const _DevicePulseCard({
    required this.device,
    required this.onTap,
  });

  final Device device;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (device.status) {
      case 'paused':
        return WiFenceColors.coral;
      case 'quota_exhausted':
        return WiFenceColors.danger;
      case 'scheduled_off':
        return WiFenceColors.sky;
      case 'needs_attention':
        return WiFenceColors.cobalt;
      case 'offline':
        return WiFenceColors.muted;
      default:
        return WiFenceColors.mint;
    }
  }

  String get _statusLabel => device.status.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WiFenceColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${device.minutesUsedToday} min used today${device.dailyLimitMinutes == null ? '' : ' / ${device.dailyLimitMinutes}'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (device.profile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    device.profile!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbeCard extends StatelessWidget {
  const _ProbeCard({required this.probe});

  final PulseProbe probe;

  @override
  Widget build(BuildContext context) {
    final accent = probe.reachable ? WiFenceColors.mint : WiFenceColors.danger;
    final subtitle = probe.reachable
        ? '${probe.latencyMs?.round() ?? 0} ms'
        : (probe.error ?? 'No response');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              probe.reachable ? Icons.check_rounded : Icons.close_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(probe.label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final PulseRecentEvent event;

  @override
  Widget build(BuildContext context) {
    final timestamp =
        '${event.createdAt.hour.toString().padLeft(2, '0')}:${event.createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WiFenceColors.cobalt.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: WiFenceColors.cobalt),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.summary, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  event.actorDisplayName == null
                      ? timestamp
                      : '${event.actorDisplayName} • $timestamp',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.summary,
  });

  final IconData icon;
  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: WiFenceColors.mint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: WiFenceColors.mint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(summary, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
