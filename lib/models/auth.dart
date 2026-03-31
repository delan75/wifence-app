class SetupStatus {
  const SetupStatus({
    required this.isConfigured,
    required this.requiresOwnerSetup,
  });

  final bool isConfigured;
  final bool requiresOwnerSetup;

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      isConfigured: json['is_configured'] as bool,
      requiresOwnerSetup: json['requires_owner_setup'] as bool,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
