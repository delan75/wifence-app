import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/device.dart';
import '../models/onboarding.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({
    super.key,
    required this.apiClient,
    required this.onClosed,
    this.allowLater = true,
    this.showBackButton = false,
  });

  final ApiClient apiClient;
  final Future<void> Function(bool completed) onClosed;
  final bool allowLater;
  final bool showBackButton;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  static const int _totalSteps = 5;

  final Map<int, TextEditingController> _nameControllers = {};
  OnboardingSummary? _summary;
  int _stepIndex = 0;
  int? _selectedDeviceId;
  bool _loading = true;
  bool _scanBusy = false;
  bool _actionBusy = false;
  bool _pauseAttempted = false;
  bool _pauseReviewComplete = false;
  bool _pauseAppliedByWizard = false;
  String? _pauseFeedback;
  bool _blockAttempted = false;
  bool _blockReviewComplete = false;
  String? _blockFeedback;
  String? _wizardCategoryKey;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Device? get _selectedDevice {
    final summary = _summary;
    if (summary == null || _selectedDeviceId == null) {
      return null;
    }
    for (final device in summary.devices) {
      if (device.id == _selectedDeviceId) {
        return device;
      }
    }
    return null;
  }

  List<Device> get _orderedDevices {
    final devices = [...?_summary?.devices];
    devices.sort((left, right) {
      final leftScore = left.isOnline ? 0 : 1;
      final rightScore = right.isOnline ? 0 : 1;
      if (leftScore != rightScore) {
        return leftScore.compareTo(rightScore);
      }
      return left.displayName.toLowerCase().compareTo(right.displayName.toLowerCase());
    });
    return devices;
  }

  CategoryOption? get _suggestedCategory {
    final summary = _summary;
    final device = _selectedDevice;
    if (summary == null || device == null) {
      return null;
    }

    final existingKeys = device.policies
        .where((policy) => policy.policyType == 'category_block')
        .map((policy) => policy.categoryKey)
        .whereType<String>()
        .toSet();

    for (final category in summary.categories) {
      if (!existingKeys.contains(category.key)) {
        return category;
      }
    }
    return summary.categories.isEmpty ? null : summary.categories.first;
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final summary = await widget.apiClient.fetchOnboardingSummary();
      for (final device in summary.devices.take(5)) {
        _nameControllers.putIfAbsent(
          device.id,
          () => TextEditingController(text: device.displayName),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _selectedDeviceId = _resolveSelectedDeviceId(summary);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? _resolveSelectedDeviceId(OnboardingSummary summary) {
    if (_selectedDeviceId != null &&
        summary.devices.any((device) => device.id == _selectedDeviceId)) {
      return _selectedDeviceId;
    }
    final onlineDevice = summary.devices.where((device) => device.isOnline);
    if (onlineDevice.isNotEmpty) {
      return onlineDevice.first.id;
    }
    return summary.devices.isEmpty ? null : summary.devices.first.id;
  }

  Future<void> _refreshSummary() async {
    final summary = await widget.apiClient.fetchOnboardingSummary();
    for (final device in summary.devices.take(5)) {
      final controller = _nameControllers.putIfAbsent(
        device.id,
        () => TextEditingController(text: device.displayName),
      );
      if (controller.text.trim().isEmpty || controller.text == device.displayName) {
        controller.text = device.displayName;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _summary = summary;
      _selectedDeviceId = _resolveSelectedDeviceId(summary);
    });
  }

  Future<void> _scanAgain() async {
    setState(() {
      _scanBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.refreshDiscovery();
      await _refreshSummary();
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
          _scanBusy = false;
        });
      }
    }
  }

  Future<void> _saveDeviceName(Device device) async {
    final controller = _nameControllers[device.id];
    final nextName = controller?.text.trim() ?? '';
    if (nextName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use at least 2 characters for a device name.')),
      );
      return;
    }

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.updateDevice(
        deviceId: device.id,
        displayName: nextName,
      );
      await _refreshSummary();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $nextName')),
      );
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
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _runPauseTest() async {
    final device = _selectedDevice;
    if (device == null) {
      return;
    }

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      if (!device.isPaused) {
        await widget.apiClient.pauseDevice(device.id);
        _pauseAppliedByWizard = true;
      }
      await _refreshSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _pauseAttempted = true;
      });
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
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _resumePauseTest() async {
    final device = _selectedDevice;
    if (device == null || !_pauseAppliedByWizard) {
      return;
    }

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.resumeDevice(device.id);
      _pauseAppliedByWizard = false;
      await _refreshSummary();
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
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _runBlockTest() async {
    final device = _selectedDevice;
    final category = _suggestedCategory;
    if (device == null || category == null) {
      return;
    }

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      final alreadyBlocked = device.policies.any(
        (policy) =>
            policy.policyType == 'category_block' &&
            policy.categoryKey == category.key,
      );
      if (!alreadyBlocked) {
        await widget.apiClient.addCategoryPolicy(device.id, category.key);
        _wizardCategoryKey = category.key;
      }
      await _refreshSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _blockAttempted = true;
      });
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
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _clearBlockTest() async {
    final device = _selectedDevice;
    final categoryKey = _wizardCategoryKey;
    if (device == null || categoryKey == null) {
      return;
    }

    setState(() {
      _actionBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.removeCategoryPolicy(device.id, categoryKey);
      _wizardCategoryKey = null;
      await _refreshSummary();
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
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _cleanupWizardArtifacts() async {
    if (_pauseAppliedByWizard) {
      final device = _selectedDevice;
      if (device != null) {
        try {
          await widget.apiClient.resumeDevice(device.id);
        } catch (_) {}
      }
      _pauseAppliedByWizard = false;
    }
    if (_wizardCategoryKey != null) {
      final device = _selectedDevice;
      final categoryKey = _wizardCategoryKey!;
      if (device != null) {
        try {
          await widget.apiClient.removeCategoryPolicy(device.id, categoryKey);
        } catch (_) {}
      }
      _wizardCategoryKey = null;
    }
  }

  Future<void> _closeWizard(bool completed) async {
    setState(() {
      _actionBusy = true;
    });
    await _cleanupWizardArtifacts();
    await widget.onClosed(completed);
  }

  bool get _canContinue {
    switch (_stepIndex) {
      case 0:
        return (_summary?.devices.isNotEmpty ?? false);
      case 1:
        return _selectedDevice != null;
      case 2:
        return _pauseReviewComplete && !_pauseAppliedByWizard;
      case 3:
        return _blockReviewComplete && _wizardCategoryKey == null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _goNext() {
    if (!_canContinue) {
      return;
    }
    if (_stepIndex < _totalSteps - 1) {
      setState(() {
        _stepIndex += 1;
      });
    }
  }

  void _goBack() {
    if (_stepIndex == 0) {
      return;
    }
    setState(() {
      _stepIndex -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _WizardBackground(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _summary == null
                    ? _WizardFailureState(
                        message: _errorMessage!,
                        onRetry: _loadSummary,
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: _WizardHeader(
                              stepIndex: _stepIndex,
                              totalSteps: _totalSteps,
                              allowLater: widget.allowLater,
                              showBackButton: widget.showBackButton,
                              onLater: () => _closeWizard(false),
                              onBack: widget.showBackButton
                                  ? () => Navigator.of(context).maybePop()
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: ListView(
                                key: ValueKey(_stepIndex),
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                children: [
                                  if (_errorMessage != null) ...[
                                    _InlineNotice(
                                      tone: _NoticeTone.warning,
                                      title: 'Something needs attention',
                                      body: _errorMessage!,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildStepCard(context),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: _WizardFooter(
                              stepIndex: _stepIndex,
                              totalSteps: _totalSteps,
                              canContinue: _canContinue,
                              actionBusy: _actionBusy || _scanBusy,
                              onBack: _stepIndex == 0 ? null : _goBack,
                              onNext: _stepIndex == _totalSteps - 1
                                  ? () => _closeWizard(true)
                                  : _goNext,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context) {
    switch (_stepIndex) {
      case 0:
        return _buildGatewayStep(context);
      case 1:
        return _buildNamingStep(context);
      case 2:
        return _buildPauseStep(context);
      case 3:
        return _buildBlockStep(context);
      default:
        return _buildFinishStep(context);
    }
  }

  Widget _buildGatewayStep(BuildContext context) {
    final summary = _summary!;
    final devicePreview = _orderedDevices.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHero(
          eyebrow: 'Step 1',
          title: 'Check the gateway and scan the network',
          body:
              'This confirms whether WiFence can prove live controls on this host and gives you a fresh view of devices to work with.',
          icon: Icons.router_rounded,
        ),
        const SizedBox(height: 18),
        _InlineNotice(
          tone: summary.canVerifyLiveControls
              ? _NoticeTone.success
              : _NoticeTone.info,
          title: summary.canVerifyLiveControls
              ? 'Live verification is available'
              : 'This host is still a staged environment',
          body: summary.verificationSummary,
        ),
        const SizedBox(height: 18),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gateway readiness', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                summary.readiness.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(label: 'Mode', value: summary.gatewayMode),
                  _MetricChip(
                    label: 'Enforcement',
                    value: summary.enforcement.canApplySystem ? 'Live' : 'Staged',
                  ),
                  _MetricChip(
                    label: 'Devices',
                    value: '${summary.devices.length}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _scanBusy ? null : _scanAgain,
                child: Text(_scanBusy ? 'Scanning...' : 'Scan network again'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (devicePreview.isEmpty)
          const _InlineNotice(
            tone: _NoticeTone.warning,
            title: 'No devices found yet',
            body: 'Run a scan first so you have something real to name and test.',
          )
        else
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What WiFence found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...devicePreview.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DevicePreviewRow(device: device),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNamingStep(BuildContext context) {
    final devices = _orderedDevices.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHero(
          eyebrow: 'Step 2',
          title: 'Name devices and pick one to test',
          body:
              'Rename the main devices you recognize, then choose one device you can physically test right now.',
          icon: Icons.draw_rounded,
        ),
        const SizedBox(height: 18),
        if (devices.isEmpty)
          const _InlineNotice(
            tone: _NoticeTone.warning,
            title: 'There are still no devices to work with',
            body: 'Go back one step and run another scan so WiFence has something to name.',
          )
        else
          ...devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<int>(
                          value: device.id,
                          groupValue: _selectedDeviceId,
                          onChanged: (value) {
                            setState(() {
                              _selectedDeviceId = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                device.hostname ?? device.currentIp ?? 'Unknown host',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(
                          label: device.isOnline ? 'Online' : 'Offline',
                          color: device.isOnline ? WiFenceColors.mint : WiFenceColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameControllers[device.id],
                      decoration: const InputDecoration(
                        labelText: 'Friendly name',
                        hintText: 'John phone, Office laptop, Living room TV...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _actionBusy ? null : () => _saveDeviceName(device),
                        child: const Text('Save name'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPauseStep(BuildContext context) {
    final summary = _summary!;
    final device = _selectedDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHero(
          eyebrow: 'Step 3',
          title: 'Pause a real device and verify the cut',
          body:
              'Use a device you can hold right now. WiFence will pause it, then you confirm whether internet access actually stopped.',
          icon: Icons.pause_circle_filled_rounded,
        ),
        const SizedBox(height: 18),
        if (device == null)
          const _InlineNotice(
            tone: _NoticeTone.warning,
            title: 'Choose a device first',
            body: 'Go back and pick a device to use for the live pause test.',
          )
        else ...[
          _SelectedDeviceCard(device: device),
          const SizedBox(height: 18),
          _InlineNotice(
            tone: summary.canVerifyLiveControls
                ? _NoticeTone.success
                : _NoticeTone.warning,
            title: summary.canVerifyLiveControls
                ? 'This can be a live enforcement proof'
                : 'This is only a staged policy-path test on this host',
            body: summary.canVerifyLiveControls
                ? 'Tap pause, then try to load a website on ${device.displayName}. After you confirm, resume the device before you continue.'
                : 'Tap pause to confirm the gateway accepts and syncs the rule. To prove actual internet blocking, run WiFence on a supported Linux gateway.',
          ),
          const SizedBox(height: 18),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pause test', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (!_pauseAttempted)
                  FilledButton(
                    onPressed: _actionBusy ? null : _runPauseTest,
                    child: const Text('Pause this device now'),
                  )
                else ...[
                  _StatusPill(
                    label: device.isPaused ? 'Device shows paused' : 'Device resumed',
                    color: device.isPaused ? WiFenceColors.coral : WiFenceColors.mint,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _pauseReviewComplete = true;
                            _pauseFeedback =
                                'Great. WiFence paused the device and you saw internet access stop on the test device.';
                          });
                        },
                        child: const Text('Yes, internet stopped'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _pauseReviewComplete = true;
                            _pauseFeedback = summary.canVerifyLiveControls
                                ? 'If the device stayed online, recheck the gateway conflicts and whether WiFence is really in the traffic path.'
                                : 'That result is expected on a staged host. WiFence stored the policy, but this host cannot prove live blocking yet.';
                          });
                        },
                        child: const Text('No, it still worked'),
                      ),
                    ],
                  ),
                  if (_pauseFeedback != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _pauseFeedback!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WiFenceColors.ink,
                          ),
                    ),
                  ],
                  if (_pauseAppliedByWizard) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: _actionBusy ? null : _resumePauseTest,
                      child: const Text('Resume test device'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBlockStep(BuildContext context) {
    final summary = _summary!;
    final device = _selectedDevice;
    final category = _suggestedCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHero(
          eyebrow: 'Step 4',
          title: 'Block a category and test a real domain',
          body:
              'WiFence will add one temporary category rule to the selected device so you can confirm that blocked domains stop resolving.',
          icon: Icons.domain_disabled_rounded,
        ),
        const SizedBox(height: 18),
        if (device == null || category == null)
          const _InlineNotice(
            tone: _NoticeTone.warning,
            title: 'There is no category test available yet',
            body: 'Pick a device first. If every category is already blocked on that device, remove one and try again.',
          )
        else ...[
          _SelectedDeviceCard(device: device),
          const SizedBox(height: 18),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temporary block test', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  'WiFence will test with ${category.label.toLowerCase()}. Try one of the example domains below on ${device.displayName}, then confirm the result.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: category.exampleDomains
                      .map((domain) => _DomainChip(domain: domain))
                      .toList(),
                ),
                const SizedBox(height: 18),
                if (!_blockAttempted)
                  FilledButton(
                    onPressed: _actionBusy ? null : _runBlockTest,
                    child: Text('Apply ${category.label.toLowerCase()} block'),
                  )
                else ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _blockReviewComplete = true;
                            _blockFeedback =
                                'Good. The domain test matched the rule and WiFence blocked the chosen category on the target device.';
                          });
                        },
                        child: const Text('Yes, domains were blocked'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _blockReviewComplete = true;
                            _blockFeedback = summary.canVerifyLiveControls
                                ? 'If the domains still resolve, check the gateway readiness and make sure the device traffic really depends on the WiFence path.'
                                : 'That result is expected on a staged host. The gateway accepted the rule, but this host cannot prove live DNS blocking yet.';
                          });
                        },
                        child: const Text('No, they still resolved'),
                      ),
                    ],
                  ),
                  if (_blockFeedback != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _blockFeedback!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WiFenceColors.ink,
                          ),
                    ),
                  ],
                  if (_wizardCategoryKey != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: _actionBusy ? null : _clearBlockTest,
                      child: const Text('Remove test block'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinishStep(BuildContext context) {
    final device = _selectedDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHero(
          eyebrow: 'Step 5',
          title: 'You now have a working first setup',
          body:
              'WiFence found your gateway, helped you name devices, and walked through the first pause and domain-block checks.',
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 18),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is done', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              const _ChecklistRow(text: 'The gateway was checked before controls were tested.'),
              _ChecklistRow(
                text: device == null
                    ? 'A target device was selected for testing.'
                    : '${device.displayName} was used as the first test device.',
              ),
              const _ChecklistRow(text: 'Pause and block tests were guided from the phone.'),
              const _ChecklistRow(
                text:
                    'Temporary test rules were cleaned up so you can keep building the real setup from a clean state.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WizardBackground extends StatelessWidget {
  const _WizardBackground();

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
          bottom: 80,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: WiFenceColors.coral.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.stepIndex,
    required this.totalSteps,
    required this.allowLater,
    required this.showBackButton,
    required this.onLater,
    this.onBack,
  });

  final int stepIndex;
  final int totalSteps;
  final bool allowLater;
  final bool showBackButton;
  final VoidCallback onLater;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBackButton)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [WiFenceColors.cobalt, WiFenceColors.sky],
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setup wizard', style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    'Find, name, and test the first household controls.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (allowLater)
              TextButton(
                onPressed: onLater,
                child: const Text('Do this later'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= stepIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? WiFenceColors.cobalt : WiFenceColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.stepIndex,
    required this.totalSteps,
    required this.canContinue,
    required this.actionBusy,
    required this.onBack,
    required this.onNext,
  });

  final int stepIndex;
  final int totalSteps;
  final bool canContinue;
  final bool actionBusy;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLastStep = stepIndex == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: actionBusy ? null : onBack,
                child: const Text('Back'),
              ),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: actionBusy || !canContinue ? null : onNext,
              child: Text(isLastStep ? 'Finish setup' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardFailureState extends StatelessWidget {
  const _WizardFailureState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const SizedBox(height: 32),
        _InlineNotice(
          tone: _NoticeTone.warning,
          title: 'The setup wizard could not load',
          body: message,
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _StepHero extends StatelessWidget {
  const _StepHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: WiFenceColors.cobalt.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: WiFenceColors.cobalt),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WiFenceColors.cobalt,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: child,
    );
  }
}

enum _NoticeTone { info, success, warning }

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.tone,
    required this.title,
    required this.body,
  });

  final _NoticeTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _NoticeTone.success => WiFenceColors.mint,
      _NoticeTone.warning => WiFenceColors.coral,
      _NoticeTone.info => WiFenceColors.cobalt,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: WiFenceColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: WiFenceColors.ink),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
        color: WiFenceColors.canvas,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DevicePreviewRow extends StatelessWidget {
  const _DevicePreviewRow({
    required this.device,
  });

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.displayName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                device.hostname ?? device.currentIp ?? 'Unknown host',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _StatusPill(
          label: device.isOnline ? 'Online' : 'Offline',
          color: device.isOnline ? WiFenceColors.mint : WiFenceColors.muted,
        ),
      ],
    );
  }
}

class _SelectedDeviceCard extends StatelessWidget {
  const _SelectedDeviceCard({
    required this.device,
  });

  final Device device;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: WiFenceColors.sky.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.devices_rounded, color: WiFenceColors.cobalt),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.displayName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  device.hostname ?? device.currentIp ?? 'Unknown host',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _StatusPill(
            label: device.status.replaceAll('_', ' '),
            color: device.isPaused ? WiFenceColors.coral : WiFenceColors.cobalt,
          ),
        ],
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  const _DomainChip({
    required this.domain,
  });

  final String domain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WiFenceColors.canvas,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        domain,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WiFenceColors.ink,
            ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: WiFenceColors.mint, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
