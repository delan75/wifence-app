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

class TrustedDevice {
  const TrustedDevice({
    required this.id,
    required this.displayName,
    required this.deviceKey,
    required this.role,
    required this.pairedAt,
    required this.lastSeenAt,
    this.platform,
  });

  final String id;
  final String displayName;
  final String deviceKey;
  final String role;
  final String? platform;
  final DateTime pairedAt;
  final DateTime lastSeenAt;

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      deviceKey: json['device_key'] as String,
      role: json['role'] as String,
      platform: json['platform'] as String?,
      pairedAt: DateTime.parse(json['paired_at'] as String),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
    );
  }
}

class AuthContext {
  const AuthContext({
    required this.user,
    required this.trustedDevice,
  });

  final AuthUser user;
  final TrustedDevice trustedDevice;

  factory AuthContext.fromJson(Map<String, dynamic> json) {
    return AuthContext(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      trustedDevice:
          TrustedDevice.fromJson(json['trusted_device'] as Map<String, dynamic>),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    required this.trustedDevice,
  });

  final String accessToken;
  final String tokenType;
  final AuthUser user;
  final TrustedDevice trustedDevice;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      trustedDevice:
          TrustedDevice.fromJson(json['trusted_device'] as Map<String, dynamic>),
    );
  }
}

class PairingCodeSession {
  const PairingCodeSession({
    required this.pairingCode,
    required this.expiresAt,
    required this.pairingUri,
    required this.assignedRole,
    required this.trustedDevice,
  });

  final String pairingCode;
  final DateTime expiresAt;
  final String pairingUri;
  final String assignedRole;
  final TrustedDevice trustedDevice;

  factory PairingCodeSession.fromJson(Map<String, dynamic> json) {
    return PairingCodeSession(
      pairingCode: json['pairing_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      pairingUri: json['pairing_uri'] as String,
      assignedRole: json['assigned_role'] as String,
      trustedDevice:
          TrustedDevice.fromJson(json['trusted_device'] as Map<String, dynamic>),
    );
  }
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.action,
    required this.summary,
    required this.createdAt,
    required this.details,
    this.targetType,
    this.targetId,
    this.actorDisplayName,
    this.actorDeviceName,
    this.actorDeviceRole,
  });

  final int id;
  final String action;
  final String summary;
  final String? targetType;
  final String? targetId;
  final String? actorDisplayName;
  final String? actorDeviceName;
  final String? actorDeviceRole;
  final DateTime createdAt;
  final Map<String, dynamic> details;

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as int,
      action: json['action'] as String,
      summary: json['summary'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      actorDisplayName: json['actor_display_name'] as String?,
      actorDeviceName: json['actor_device_name'] as String?,
      actorDeviceRole: json['actor_device_role'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      details: Map<String, dynamic>.from(
        json['details'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
