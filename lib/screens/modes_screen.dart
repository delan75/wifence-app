import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/modes.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  late Future<ModesOverview> _modesFuture;

  @override
  void initState() {
    super.initState();
    _modesFuture = widget.apiClient.fetchModes();
  }

  Future<void> _refresh() async {
    setState(() {
      _modesFuture = widget.apiClient.fetchModes();
    });
    await _modesFuture;
  }

  Future<void> _editRoutine(Device device, List<ModePreset> presets) async {
    final updated = await showModalBottomSheet<Device>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoutineEditorSheet(
        apiClient: widget.apiClient,
        device: device,
        presets: presets,
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved routine for ${updated.displayName}.')),
    );
    await _refresh();
  }

  Future<void> _editProfileRoutine(
    ModeProfile profile,
    List<Device> devices,
    List<ModePreset> presets,
  ) async {
    final selectedPreset = await showModalBottomSheet<ModePreset?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileRoutineSheet(
        profile: profile,
        devices: devices,
        presets: presets,
      ),
    );

    if (selectedPreset == null || !mounted) {
      return;
    }

    try {
      await widget.apiClient.updateProfileSchedule(
        profileId: profile.id,
        name: selectedPreset.label,
        daysOfWeek: selectedPreset.defaultDaysOfWeek,
        startsAtMinute: selectedPreset.defaultStartsAtMinute,
        endsAtMinute: selectedPreset.defaultEndsAtMinute,
        modeKey: selectedPreset.key,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied ${selectedPreset.label.toLowerCase()} to ${profile.name}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createProfile() async {
    final draft = await showModalBottomSheet<_ProfileDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfileEditorSheet(),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.apiClient.createProfile(
        name: draft.name,
        color: draft.color,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${draft.name}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editProfileMeta(ModeProfile profile) async {
    final draft = await showModalBottomSheet<_ProfileDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileEditorSheet(
        initialName: profile.name,
        initialColor: profile.color,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.apiClient.updateProfile(
        profileId: profile.id,
        name: draft.name,
        color: draft.color,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${draft.name}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _applyPresetToProfile(ModeProfile profile, ModePreset preset) async {
    try {
      await widget.apiClient.updateProfileSchedule(
        profileId: profile.id,
        name: preset.label,
        daysOfWeek: preset.defaultDaysOfWeek,
        startsAtMinute: preset.defaultStartsAtMinute,
        endsAtMinute: preset.defaultEndsAtMinute,
        modeKey: preset.key,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${preset.label} is ready for ${profile.name}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _togglePauseProfile(ModeProfile profile, List<Device> devices) async {
    final isPaused = devices.isNotEmpty && devices.every((device) => device.isPaused);

    try {
      if (isPaused) {
        await widget.apiClient.resumeProfile(profile.id);
      } else {
        await widget.apiClient.pauseProfile(profile.id);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isPaused ? 'Resumed' : 'Paused'} ${profile.name}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ModesOverview>(
      future: _modesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Text(
                'Modes',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'WiFence routines are not reachable right now.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
            ],
          );
        }

        final overview = snapshot.data!;
        final scheduledDevices = overview.devices.where((device) => device.schedule != null).toList();
        final activeNow = overview.devices.where((device) => device.status == 'scheduled_off').length;
        final bedtimePreset = _presetByKey(overview.presets, 'bedtime');
        final studyPreset = _presetByKey(overview.presets, 'study');

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Text(
                'Modes',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Set routines once, then let WiFence handle the repeat work in the background.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: WiFenceColors.muted,
                    ),
              ),
              const SizedBox(height: 22),
              _ModesHeroCard(
                totalDevices: overview.devices.length,
                scheduledDevices: scheduledDevices.length,
                activeNow: activeNow,
              ),
              const SizedBox(height: 20),
              Text(
                'Preset routines',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < overview.presets.length; i++) ...[
                      _PresetCard(preset: overview.presets[i]),
                      if (i != overview.presets.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Group routines',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _createProfile,
                    child: const Text('New group'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${overview.profiles.length} profiles',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (overview.profiles.isEmpty)
                const _EmptyGroupCard()
              else
                for (final profile in overview.profiles) ...[
                  _ProfileRoutineCard(
                    profile: profile,
                    schedule: _resolveProfileSchedule(
                      _devicesForProfile(overview.devices, profile.id),
                    ),
                    isPausedGroup: _devicesForProfile(overview.devices, profile.id).isNotEmpty &&
                        _devicesForProfile(overview.devices, profile.id)
                            .every((device) => device.isPaused),
                    onPauseToggle: () => _togglePauseProfile(
                      profile,
                      _devicesForProfile(overview.devices, profile.id),
                    ),
                    onBedtime: bedtimePreset == null
                        ? null
                        : () => _applyPresetToProfile(profile, bedtimePreset),
                    onStudy: studyPreset == null
                        ? null
                        : () => _applyPresetToProfile(profile, studyPreset),
                    onEdit: () => _editProfileMeta(profile),
                    onTap: () => _editProfileRoutine(
                      profile,
                      _devicesForProfile(overview.devices, profile.id),
                      overview.presets,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Device routines',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${scheduledDevices.length}/${overview.devices.length} active',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final device in overview.devices) ...[
                _RoutineDeviceCard(
                  device: device,
                  onTap: () => _editRoutine(device, overview.presets),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ModesHeroCard extends StatelessWidget {
  const _ModesHeroCard({
    required this.totalDevices,
    required this.scheduledDevices,
    required this.activeNow,
  });

  final int totalDevices;
  final int scheduledDevices;
  final int activeNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF101E2D), WiFenceColors.deepSea, WiFenceColors.cobalt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Routine canvas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Less tapping.\nMore automatic calm.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '$scheduledDevices of $totalDevices devices already follow a routine. $activeNow are currently in a scheduled quiet window.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
          ),
          const SizedBox(height: 22),
          const _TimelineBand(),
        ],
      ),
    );
  }
}

class _TimelineBand extends StatelessWidget {
  const _TimelineBand();

  @override
  Widget build(BuildContext context) {
    const segments = [
      ('After school', WiFenceColors.mint, 22),
      ('Unwind', WiFenceColors.coral, 18),
      ('Bedtime', WiFenceColors.sky, 34),
    ];

    return Column(
      children: [
        Row(
          children: [
            Text(
              '3 PM',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            const Spacer(),
            Text(
              'Midnight',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                Expanded(
                  flex: segments[i].$3,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: segments[i].$2.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      segments[i].$1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                if (i != segments.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset});

  final ModePreset preset;

  @override
  Widget build(BuildContext context) {
    final accent = _colorFromHex(preset.accent);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_iconForKey(preset.icon), color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            preset.label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _formatRoutineWindow(
              preset.defaultStartsAtMinute,
              preset.defaultEndsAtMinute,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            preset.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            _formatDaySet(preset.defaultDaysOfWeek),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileRoutineCard extends StatelessWidget {
  const _ProfileRoutineCard({
    required this.profile,
    required this.schedule,
    required this.isPausedGroup,
    required this.onPauseToggle,
    required this.onBedtime,
    required this.onStudy,
    required this.onEdit,
    required this.onTap,
  });

  final ModeProfile profile;
  final _DeviceSchedule? schedule;
  final bool isPausedGroup;
  final VoidCallback onPauseToggle;
  final VoidCallback? onBedtime;
  final VoidCallback? onStudy;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = profile.color == null ? WiFenceColors.cobalt : _colorFromHex(profile.color!);
    final resolvedSchedule = schedule;
    final statusText = schedule == null
        ? 'No shared routine yet'
        : '${resolvedSchedule!.name} - ${_formatRoutineWindow(resolvedSchedule.startsAtMinute, resolvedSchedule.endsAtMinute)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: WiFenceColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.people_alt_rounded, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${profile.deviceCount} devices',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: WiFenceColors.canvas,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: WiFenceColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: WiFenceColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule == null
                        ? 'Apply one preset routine to the whole group in a single step.'
                        : '${profile.scheduledDeviceCount}/${profile.deviceCount} devices currently follow this routine.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                        label: isPausedGroup ? 'Resume' : 'Pause now',
                        accent: WiFenceColors.coral,
                        onTap: onPauseToggle,
                      ),
                      _ActionChip(
                        label: 'Bedtime',
                        accent: WiFenceColors.cobalt,
                        onTap: onBedtime,
                      ),
                      _ActionChip(
                        label: 'Study mode',
                        accent: WiFenceColors.mint,
                        onTap: onStudy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: WiFenceColors.muted),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupCard extends StatelessWidget {
  const _EmptyGroupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Text(
        'Assign devices to profiles like Kids or Guests to unlock one-tap shared routines.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: onTap == null ? 0.08 : 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({
    required this.name,
    required this.color,
  });

  final String name;
  final String color;
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet({
    this.initialName,
    this.initialColor,
  });

  final String? initialName;
  final String? initialColor;

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  static const _palette = [
    '#F97316',
    '#2B63FF',
    '#29B98A',
    '#F48A55',
    '#0F766E',
    '#8C6BFF',
  ];

  late final TextEditingController _nameController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? _palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 20, 12, bottomInset + 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initialName == null ? 'New group' : 'Edit group',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Create a group like Kids, Guests, or Entertainment so routines apply faster.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _palette.map((hex) {
                  final selected = hex == _selectedColor;
                  final color = _colorFromHex(hex);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = hex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? WiFenceColors.ink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.length < 2) {
                    return;
                  }
                  Navigator.of(context).pop(
                    _ProfileDraft(
                      name: name,
                      color: _selectedColor,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(widget.initialName == null ? 'Create group' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineDeviceCard extends StatelessWidget {
  const _RoutineDeviceCard({
    required this.device,
    required this.onTap,
  });

  final Device device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final schedule = device.schedule;
    final accent = _deviceAccent(device.status);
    final summary = schedule == null
        ? 'No routine yet. Add one so WiFence can handle this device automatically.'
        : '${schedule.name} - ${_formatRoutineWindow(schedule.startsAtMinute, schedule.endsAtMinute)}';
    final supportingText = schedule == null
        ? (device.profile?.name ?? 'Unassigned profile')
        : _formatDaySet(schedule.scheduleDays);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WiFenceColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: WiFenceColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 92,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          schedule == null ? 'Open' : 'Routine on',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: WiFenceColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supportingText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: WiFenceColors.muted),
          ],
        ),
      ),
    );
  }
}

class _RoutineEditorSheet extends StatefulWidget {
  const _RoutineEditorSheet({
    required this.apiClient,
    required this.device,
    required this.presets,
  });

  final ApiClient apiClient;
  final Device device;
  final List<ModePreset> presets;

  @override
  State<_RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<_RoutineEditorSheet> {
  late List<int> _days;
  late int _startMinute;
  late int _endMinute;
  late ModePreset _selectedPreset;
  bool _saving = false;

  _DeviceSchedule? get _existingSchedule => widget.device.schedule;

  @override
  void initState() {
    super.initState();
    final existingSchedule = _existingSchedule;
    final preset = widget.presets.firstWhere(
      (candidate) => candidate.key == existingSchedule?.modeKey,
      orElse: () => widget.presets.first,
    );

    _selectedPreset = preset;
    _days = existingSchedule?.scheduleDays.toList() ?? preset.defaultDaysOfWeek.toList();
    _startMinute = existingSchedule?.startsAtMinute ?? preset.defaultStartsAtMinute;
    _endMinute = existingSchedule?.endsAtMinute ?? preset.defaultEndsAtMinute;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialMinute = isStart ? _startMinute : _endMinute;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinute ~/ 60,
        minute: initialMinute % 60,
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      final nextMinute = selected.hour * 60 + selected.minute;
      if (isStart) {
        _startMinute = nextMinute;
      } else {
        _endMinute = nextMinute;
      }
    });
  }

  void _applyPreset(ModePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _days = preset.defaultDaysOfWeek.toList();
      _startMinute = preset.defaultStartsAtMinute;
      _endMinute = preset.defaultEndsAtMinute;
    });
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one day for this routine.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final device = await widget.apiClient.updateSchedule(
        deviceId: widget.device.id,
        name: _selectedPreset.label,
        daysOfWeek: _days,
        startsAtMinute: _startMinute,
        endsAtMinute: _endMinute,
        modeKey: _selectedPreset.key,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(device);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _clear() async {
    setState(() {
      _saving = true;
    });

    try {
      final device = await widget.apiClient.clearSchedule(widget.device.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(device);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = _colorFromHex(_selectedPreset.accent);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 20, 12, bottomInset + 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.device.displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose when WiFence should automatically step in.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Routine style',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.presets.map((preset) {
                    final isSelected = preset.key == _selectedPreset.key;
                    final presetAccent = _colorFromHex(preset.accent);
                    return GestureDetector(
                      onTap: _saving ? null : () => _applyPreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? presetAccent.withValues(alpha: 0.14)
                              : WiFenceColors.canvas,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? presetAccent : WiFenceColors.line,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconForKey(preset.icon), color: presetAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              preset.label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: WiFenceColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                Text(
                  'Days',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final selected = _days.contains(index);
                    return GestureDetector(
                      onTap: _saving
                          ? null
                          : () {
                              setState(() {
                                if (selected) {
                                  _days.remove(index);
                                } else {
                                  _days.add(index);
                                  _days.sort();
                                }
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? accent : WiFenceColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _weekdayShort(index),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: selected ? Colors.white : WiFenceColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                Text(
                  'Window',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Starts',
                        value: _formatMinute(_startMinute),
                        onTap: _saving ? null : () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeButton(
                        label: 'Ends',
                        value: _formatMinute(_endMinute),
                        onTap: _saving ? null : () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconForKey(_selectedPreset.icon), color: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_selectedPreset.label} will run ${_formatDaySet(_days)} from ${_formatMinute(_startMinute)} to ${_formatMinute(_endMinute)}.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: WiFenceColors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save routine'),
                ),
                if (_existingSchedule != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _saving ? null : _clear,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('Clear routine'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRoutineSheet extends StatelessWidget {
  const _ProfileRoutineSheet({
    required this.profile,
    required this.devices,
    required this.presets,
  });

  final ModeProfile profile;
  final List<Device> devices;
  final List<ModePreset> presets;

  @override
  Widget build(BuildContext context) {
    final currentSchedule = _resolveProfileSchedule(devices);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WiFenceColors.card,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Apply a shared routine to all ${profile.deviceCount} devices in this group.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (currentSchedule != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: WiFenceColors.canvas,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current: ${currentSchedule.name} - ${_formatRoutineWindow(currentSchedule.startsAtMinute, currentSchedule.endsAtMinute)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WiFenceColors.ink,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              for (var i = 0; i < presets.length; i++) ...[
                _ProfilePresetTile(
                  preset: presets[i],
                  onTap: () => Navigator.of(context).pop(presets[i]),
                ),
                if (i != presets.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePresetTile extends StatelessWidget {
  const _ProfilePresetTile({
    required this.preset,
    required this.onTap,
  });

  final ModePreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _colorFromHex(preset.accent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WiFenceColors.canvas,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconForKey(preset.icon), color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatRoutineWindow(preset.defaultStartsAtMinute, preset.defaultEndsAtMinute)} · ${_formatDaySet(preset.defaultDaysOfWeek)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: WiFenceColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSchedule {
  const _DeviceSchedule({
    required this.name,
    required this.scheduleDays,
    required this.startsAtMinute,
    required this.endsAtMinute,
    required this.modeKey,
  });

  final String name;
  final List<int> scheduleDays;
  final int startsAtMinute;
  final int endsAtMinute;
  final String? modeKey;
}

extension _ScheduleLookup on Device {
  _DeviceSchedule? get schedule {
    Policy? match;
    for (final policy in policies) {
      if (policy.policyType == 'schedule') {
        match = policy;
        break;
      }
    }

    if (match == null || match.startsAtMinute == null || match.endsAtMinute == null) {
      return null;
    }

    return _DeviceSchedule(
      name: match.name,
      scheduleDays: match.scheduleDays,
      startsAtMinute: match.startsAtMinute!,
      endsAtMinute: match.endsAtMinute!,
      modeKey: match.modeKey,
    );
  }
}

List<Device> _devicesForProfile(List<Device> devices, int profileId) {
  return devices.where((device) => device.profile?.id == profileId).toList();
}

_DeviceSchedule? _resolveProfileSchedule(List<Device> devices) {
  for (final device in devices) {
    final schedule = device.schedule;
    if (schedule != null) {
      return schedule;
    }
  }
  return null;
}

ModePreset? _presetByKey(List<ModePreset> presets, String key) {
  for (final preset in presets) {
    if (preset.key == key) {
      return preset;
    }
  }
  return null;
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}

IconData _iconForKey(String key) {
  switch (key) {
    case 'bedtime':
      return Icons.bedtime_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color _deviceAccent(String status) {
  switch (status) {
    case 'scheduled_off':
      return WiFenceColors.cobalt;
    case 'paused':
      return WiFenceColors.coral;
    case 'quota_exhausted':
      return WiFenceColors.mint;
    default:
      return WiFenceColors.deepSea;
  }
}

String _formatRoutineWindow(int startMinute, int endMinute) {
  return '${_formatMinute(startMinute)} - ${_formatMinute(endMinute)}';
}

String _formatMinute(int minute) {
  final hour = (minute ~/ 60) % 24;
  final mins = minute % 60;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final paddedMinute = mins.toString().padLeft(2, '0');
  return '$displayHour:$paddedMinute $suffix';
}

String _formatDaySet(List<int> days) {
  if (days.length == 7) {
    return 'Every day';
  }

  const weekdaySet = {0, 1, 2, 3, 4};
  if (days.length == 5 && weekdaySet.containsAll(days)) {
    return 'Weekdays';
  }

  return days.map(_weekdayShort).join(' ');
}

String _weekdayShort(int day) {
  const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  return labels[day];
}
