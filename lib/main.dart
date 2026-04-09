import 'package:flutter/material.dart';

import 'models/auth.dart';
import 'models/gateway.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/setup_wizard_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'theme/wifence_theme.dart';

void main() {
  runApp(const WiFenceApp());
}

class WiFenceApp extends StatefulWidget {
  const WiFenceApp({super.key});

  @override
  State<WiFenceApp> createState() => _WiFenceAppState();
}

class _WiFenceAppState extends State<WiFenceApp> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  String? _deviceId;

  late Future<_BootstrapState> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapState> _bootstrap() async {
    try {
      final deviceId = await _sessionStore.getOrCreateDeviceId();
      _deviceId = deviceId;
      _apiClient.setDeviceIdentity(
        deviceId: deviceId,
        deviceName: 'This phone',
        devicePlatform: 'android',
      );
      final token = await _sessionStore.readToken();
      _apiClient.setAccessToken(token);

      final readiness = await _apiClient.fetchGatewayReadiness();
      final setupStatus = await _apiClient.fetchSetupStatus();

      if (token != null && setupStatus.isConfigured) {
        try {
          final authContext = await _apiClient.fetchMe();
          final shouldShowSetupWizard =
              authContext.trustedDevice.role == 'owner' &&
              !(await _sessionStore.isSetupWizardCompleted(
                authContext.trustedDevice.id,
              ));
          return _BootstrapState(
            readiness: readiness,
            setupStatus: setupStatus,
            currentUser: authContext.user,
            currentTrustedDevice: authContext.trustedDevice,
            shouldShowSetupWizard: shouldShowSetupWizard,
          );
        } catch (_) {
          await _sessionStore.clear();
          _apiClient.setAccessToken(null);
        }
      }

      return _BootstrapState(
        readiness: readiness,
        setupStatus: setupStatus,
      );
    } catch (error) {
      return _BootstrapState(errorMessage: error.toString());
    }
  }

  Future<void> _handleAuthenticated(AuthSession session) async {
    await _sessionStore.saveToken(session.accessToken);
    _apiClient.setAccessToken(session.accessToken);
    final shouldShowSetupWizard =
        session.trustedDevice.role == 'owner' &&
        !(await _sessionStore.isSetupWizardCompleted(session.trustedDevice.id));

    setState(() {
      _bootstrapFuture = Future.value(
        _BootstrapState(
          setupStatus: const SetupStatus(
            isConfigured: true,
            requiresOwnerSetup: false,
          ),
          currentUser: session.user,
          currentTrustedDevice: session.trustedDevice,
          shouldShowSetupWizard: shouldShowSetupWizard,
        ),
      );
    });
  }

  Future<void> _handleSetupWizardClosed(_BootstrapState state, bool completed) async {
    final trustedDevice = state.currentTrustedDevice;
    final currentUser = state.currentUser;
    if (trustedDevice == null || currentUser == null) {
      return;
    }

    await _sessionStore.markSetupWizardCompleted(trustedDevice.id);
    setState(() {
      _bootstrapFuture = Future.value(
        _BootstrapState(
          readiness: state.readiness,
          setupStatus: state.setupStatus,
          currentUser: currentUser,
          currentTrustedDevice: trustedDevice,
          shouldShowSetupWizard: false,
        ),
      );
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _apiClient.logout();
    } catch (_) {
      // If logout fails remotely, we still clear the local session.
    }
    await _sessionStore.clear();
    _apiClient.setAccessToken(null);
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFence',
      debugShowCheckedModeBanner: false,
      theme: buildWiFenceTheme(),
      home: FutureBuilder<_BootstrapState>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final state = snapshot.data ?? const _BootstrapState();
          if (state.currentUser != null && state.setupStatus?.isConfigured == true) {
            if (state.shouldShowSetupWizard && state.currentTrustedDevice != null) {
              return SetupWizardScreen(
                apiClient: _apiClient,
                onClosed: (completed) => _handleSetupWizardClosed(state, completed),
              );
            }
            return WiFenceAppShell(
              apiClient: _apiClient,
              currentUser: state.currentUser!,
              currentTrustedDevice: state.currentTrustedDevice,
              currentDeviceId: _deviceId ?? '',
              onOpenSetupWizard: state.currentTrustedDevice != null &&
                      state.currentTrustedDevice!.role != 'viewer'
                  ? () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SetupWizardScreen(
                            apiClient: _apiClient,
                            allowLater: false,
                            showBackButton: true,
                            onClosed: (_) async {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    }
                  : null,
              onLogout: _handleLogout,
            );
          }

          return AuthScreen(
            apiClient: _apiClient,
            deviceId: _deviceId ?? '',
            deviceName: 'This phone',
            devicePlatform: 'android',
            initialReadiness: state.readiness,
            initialStatus: state.setupStatus,
            initialErrorMessage: state.errorMessage,
            onAuthenticated: _handleAuthenticated,
          );
        },
      ),
    );
  }
}

class _BootstrapState {
  const _BootstrapState({
    this.readiness,
    this.setupStatus,
    this.currentUser,
    this.currentTrustedDevice,
    this.shouldShowSetupWizard = false,
    this.errorMessage,
  });

  final GatewayReadiness? readiness;
  final SetupStatus? setupStatus;
  final AuthUser? currentUser;
  final TrustedDevice? currentTrustedDevice;
  final bool shouldShowSetupWizard;
  final String? errorMessage;
}
