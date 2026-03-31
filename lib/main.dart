import 'package:flutter/material.dart';

import 'models/auth.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
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

  late Future<_BootstrapState> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapState> _bootstrap() async {
    try {
      final token = await _sessionStore.readToken();
      _apiClient.setAccessToken(token);

      final setupStatus = await _apiClient.fetchSetupStatus();

      if (token != null && setupStatus.isConfigured) {
        try {
          final user = await _apiClient.fetchMe();
          return _BootstrapState(
            setupStatus: setupStatus,
            currentUser: user,
          );
        } catch (_) {
          await _sessionStore.clear();
          _apiClient.setAccessToken(null);
        }
      }

      return _BootstrapState(setupStatus: setupStatus);
    } catch (error) {
      return _BootstrapState(errorMessage: error.toString());
    }
  }

  Future<void> _handleAuthenticated(AuthSession session) async {
    await _sessionStore.saveToken(session.accessToken);
    _apiClient.setAccessToken(session.accessToken);

    setState(() {
      _bootstrapFuture = Future.value(
        _BootstrapState(
          setupStatus: const SetupStatus(
            isConfigured: true,
            requiresOwnerSetup: false,
          ),
          currentUser: session.user,
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
            return WiFenceAppShell(
              apiClient: _apiClient,
              currentUser: state.currentUser!,
              onLogout: _handleLogout,
            );
          }

          return AuthScreen(
            apiClient: _apiClient,
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
    this.setupStatus,
    this.currentUser,
    this.errorMessage,
  });

  final SetupStatus? setupStatus;
  final AuthUser? currentUser;
  final String? errorMessage;
}
