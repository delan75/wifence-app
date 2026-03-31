import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../services/api_client.dart';
import '../theme/wifence_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.apiClient,
    required this.onAuthenticated,
    this.initialStatus,
    this.initialErrorMessage,
  });

  final ApiClient apiClient;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final SetupStatus? initialStatus;
  final String? initialErrorMessage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  SetupStatus? _setupStatus;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _setupStatus = widget.initialStatus;
    _errorMessage = widget.initialErrorMessage;
    if (_setupStatus == null) {
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
      final status = await widget.apiClient.fetchSetupStatus();
      if (!mounted) {
        return;
      }
      setState(() {
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
            )
          : await widget.apiClient.login(
              displayName: displayName,
              password: password,
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
