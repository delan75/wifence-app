import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';
import 'device_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _ranges = [7, 14, 30];

  int _selectedRange = 14;
  late Future<HouseholdAnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<HouseholdAnalyticsSnapshot> _load() {
    return widget.apiClient.fetchHouseholdAnalytics(days: _selectedRange);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _setRange(int days) async {
    if (_selectedRange == days) return;
    setState(() {
      _selectedRange = days;
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<HouseholdAnalyticsSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            return RefreshIndicator(
              color: WiFenceColors.cobalt,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: WiFenceColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: WiFenceColors.line),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: WiFenceColors.deepSea,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Household trends',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Schedule hits, daily summaries, and where routines are landing.',
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
                            : _refresh,
                        icon: Container(
                          width: 46,
                          height: 46,
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
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final days in _ranges)
                        _RangeChip(
                          label: '$days days',
                          selected: _selectedRange == days,
                          onTap: () => _setRange(days),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _AnalyticsLoadingState()
                  else if (snapshot.hasError)
                    _AnalyticsErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    )
                  else if (snapshot.hasData)
                    _AnalyticsLoadedState(
                      analytics: snapshot.data!,
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
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticsLoadedState extends StatelessWidget {
  const _AnalyticsLoadedState({
    required this.analytics,
    required this.onOpenDevice,
  });

  final HouseholdAnalyticsSnapshot analytics;
  final Future<void> Function(int deviceId) onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final today = analytics.today;
    final peakDay = analytics.dailySummaries.fold<AnalyticsDaySummary>(
      analytics.dailySummaries.first,
      (best, item) => item.usageMinutes > best.usageMinutes ? item : best,
    );
    final busiestProfile = analytics.profileTrends.isEmpty ? null : analytics.profileTrends.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [WiFenceColors.deepSea, Color(0xFF153C64), WiFenceColors.cobalt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today so far',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_formatMinutes(today.usageMinutes)} online across ${today.activeDeviceCount} active devices.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Peak day in this range: ${peakDay.weekdayLabel} with ${_formatMinutes(peakDay.usageMinutes)}. ${busiestProfile == null ? 'No profile trend yet.' : '${busiestProfile.profileName} is carrying the heaviest routine load.'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'Schedule hits',
                      value: '${today.scheduleHitCount}',
                      accent: WiFenceColors.sky,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Pause actions',
                      value: '${today.manualPauseCount}',
                      accent: WiFenceColors.coral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Quota hits',
                      value: '${today.quotaHitCount}',
                      accent: WiFenceColors.mint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Daily summaries',
          subtitle: 'Usage minutes and schedule pressure over the selected range.',
        ),
        const SizedBox(height: 12),
        _UsageTrendCard(dailySummaries: analytics.dailySummaries),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Household rhythm',
          subtitle: 'Which days are seeing the most routine activity and intervention.',
        ),
        const SizedBox(height: 12),
        ...analytics.weekdayTrends.map(
          (trend) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WeekdayTrendCard(trend: trend),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Profiles',
          subtitle: 'Which groups are using the most time and taking the most schedule hits.',
        ),
        const SizedBox(height: 12),
        if (analytics.profileTrends.isEmpty)
          const _AnalyticsEmptyCard(
            icon: Icons.groups_outlined,
            title: 'No profile trend yet',
            summary: 'Assign devices to profiles and let WiFence run for a while to build grouped household trends.',
          )
        else
          ...analytics.profileTrends.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProfileTrendCard(profile: profile),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Devices carrying the load',
          subtitle: 'The devices seeing the most time, schedule hits, or quota pressure.',
        ),
        const SizedBox(height: 12),
        if (analytics.deviceTrends.isEmpty)
          const _AnalyticsEmptyCard(
            icon: Icons.devices_other_outlined,
            title: 'No device analytics yet',
            summary: 'Once WiFence has a little more live activity, this section will surface the devices that need the most attention.',
          )
        else
          ...analytics.deviceTrends.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DeviceTrendCard(
                device: device,
                onTap: () => onOpenDevice(device.deviceId),
              ),
            ),
          ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WiFenceColors.deepSea : WiFenceColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? WiFenceColors.deepSea : WiFenceColors.line,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : WiFenceColors.deepSea,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WiFenceColors.muted,
              ),
        ),
      ],
    );
  }
}

class _UsageTrendCard extends StatelessWidget {
  const _UsageTrendCard({
    required this.dailySummaries,
  });

  final List<AnalyticsDaySummary> dailySummaries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _DailyTrendPainter(dailySummaries: dailySummaries),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _LegendChip(
                  label: 'Usage minutes',
                  color: WiFenceColors.cobalt,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _LegendChip(
                  label: 'Schedule hits',
                  color: WiFenceColors.sky,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _LegendChip(
                  label: 'Pause actions',
                  color: WiFenceColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayTrendCard extends StatelessWidget {
  const _WeekdayTrendCard({
    required this.trend,
  });

  final AnalyticsWeekdayTrend trend;

  @override
  Widget build(BuildContext context) {
    final totalPressure =
        trend.scheduleHitCount + trend.manualPauseCount + trend.quotaHitCount;
    final usageRatio = math.min(1, trend.usageMinutes / 600);
    final pressureRatio = math.min(1, totalPressure / 8);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              trend.weekdayLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _LinearSignalBar(
                  label: _formatMinutes(trend.usageMinutes),
                  ratio: usageRatio,
                  color: WiFenceColors.cobalt,
                ),
                const SizedBox(height: 10),
                _LinearSignalBar(
                  label: '$totalPressure routine events',
                  ratio: pressureRatio,
                  color: WiFenceColors.coral,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniStat(label: 'Sched', value: '${trend.scheduleHitCount}'),
                _MiniStat(label: 'Pause', value: '${trend.manualPauseCount}'),
                _MiniStat(label: 'Quota', value: '${trend.quotaHitCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTrendCard extends StatelessWidget {
  const _ProfileTrendCard({
    required this.profile,
  });

  final AnalyticsProfileTrend profile;

  @override
  Widget build(BuildContext context) {
    final accent = _parseHexColor(profile.color) ?? WiFenceColors.cobalt;
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                width: 12,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.profileName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.deviceCount} devices • ${profile.activeDays} active days',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                _formatMinutes(profile.usageMinutes),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Avg/day',
                  value: _formatMinutes(profile.averageUsageMinutes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  label: 'Schedule hits',
                  value: '${profile.scheduleHitCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  label: 'Pause actions',
                  value: '${profile.manualPauseCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceTrendCard extends StatelessWidget {
  const _DeviceTrendCard({
    required this.device,
    required this.onTap,
  });

  final AnalyticsDeviceTrend device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(device.currentStatus);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.displayName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (device.profileName != null) device.profileName,
                          if (device.currentStatus != null)
                            device.currentStatus!.replaceAll('_', ' '),
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatMinutes(device.usageMinutes),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(label: 'Avg/day', value: _formatMinutes(device.averageUsageMinutes)),
                _InfoPill(label: 'Sched', value: '${device.scheduleHitCount}'),
                _InfoPill(label: 'Pause', value: '${device.manualPauseCount}'),
                _InfoPill(label: 'Quota', value: '${device.quotaHitCount}'),
                if (device.dailyLimitMinutes != null)
                  _InfoPill(label: 'Limit', value: '${device.dailyLimitMinutes} min'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinearSignalBar extends StatelessWidget {
  const _LinearSignalBar({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WiFenceColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WiFenceColors.deepSea,
              ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsEmptyCard extends StatelessWidget {
  const _AnalyticsEmptyCard({
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WiFenceColors.sky.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: WiFenceColors.sky),
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

class _AnalyticsLoadingState extends StatelessWidget {
  const _AnalyticsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: index == 0 ? 210 : 120,
            decoration: BoxDecoration(
              color: WiFenceColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: WiFenceColors.line),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
              color: WiFenceColors.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.analytics_outlined, color: WiFenceColors.coral),
          ),
          const SizedBox(height: 18),
          Text(
            'Analytics are unavailable right now',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message.replaceFirst('Exception: ', ''),
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

class _DailyTrendPainter extends CustomPainter {
  const _DailyTrendPainter({
    required this.dailySummaries,
  });

  final List<AnalyticsDaySummary> dailySummaries;

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySummaries.isEmpty) {
      return;
    }

    final chartTop = 18.0;
    final chartBottom = size.height - 24;
    final chartHeight = chartBottom - chartTop;
    final step = size.width / dailySummaries.length;
    final maxUsage = math.max<int>(
      60,
      dailySummaries.fold(0, (maxValue, item) => math.max(maxValue, item.usageMinutes)),
    );
    final maxPressure = math.max<int>(
      1,
      dailySummaries.fold(
        0,
        (maxValue, item) => math.max(
          maxValue,
          item.scheduleHitCount + item.manualPauseCount,
        ),
      ),
    );

    final gridPaint = Paint()
      ..color = WiFenceColors.line
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = chartTop + (chartHeight / 3) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final usagePaint = Paint()
      ..color = WiFenceColors.cobalt.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final schedulePaint = Paint()
      ..color = WiFenceColors.sky
      ..style = PaintingStyle.fill;
    final pausePaint = Paint()
      ..color = WiFenceColors.coral
      ..style = PaintingStyle.fill;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < dailySummaries.length; index++) {
      final item = dailySummaries[index];
      final left = step * index + 6;
      final width = math.max(10.0, step - 12);
      final usageHeight = (item.usageMinutes / maxUsage) * (chartHeight - 24);
      final top = chartBottom - usageHeight;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, usageHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(barRect, usagePaint);

      final scheduleRadius = 4 + (item.scheduleHitCount / maxPressure) * 6;
      final pauseRadius = 3 + (item.manualPauseCount / maxPressure) * 5;
      canvas.drawCircle(
        Offset(left + width / 2, math.max(chartTop + 8, top - 12)),
        scheduleRadius,
        schedulePaint,
      );
      canvas.drawCircle(
        Offset(left + width / 2, math.max(chartTop + 18, top - 28)),
        pauseRadius,
        pausePaint,
      );

      if (index.isEven || dailySummaries.length <= 10) {
        labelPainter.text = TextSpan(
          text: item.weekdayLabel,
          style: const TextStyle(
            color: WiFenceColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );
        labelPainter.layout(maxWidth: step);
        labelPainter.paint(
          canvas,
          Offset(left + (width - labelPainter.width) / 2, size.height - 18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailyTrendPainter oldDelegate) {
    return oldDelegate.dailySummaries != dailySummaries;
  }
}

String _formatMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours <= 0) return '${remainder}m';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}m';
}

Color _statusColor(String? status) {
  switch (status) {
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

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final normalized = hex.replaceFirst('#', '');
  final buffer = StringBuffer();
  if (normalized.length == 6) {
    buffer.write('ff');
  }
  buffer.write(normalized);
  if (buffer.length != 8) return null;
  return Color(int.parse(buffer.toString(), radix: 16));
}
