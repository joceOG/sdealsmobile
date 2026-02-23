class Security {
  final String? id;
  final String userId;
  final bool twoFactorEnabled;
  final String? twoFactorSecret;
  final List<SecuritySession> sessions;
  final List<SecurityAlert> alerts;
  final List<TrustedDevice> trustedDevices;
  final SecuritySettings settings;
  final DateTime? lastPasswordChange;
  final DateTime? lastLogin;
  final String? lastLoginIp;
  final String? lastLoginLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  Security({
    this.id,
    required this.userId,
    this.twoFactorEnabled = false,
    this.twoFactorSecret,
    this.sessions = const [],
    this.alerts = const [],
    this.trustedDevices = const [],
    required this.settings,
    this.lastPasswordChange,
    this.lastLogin,
    this.lastLoginIp,
    this.lastLoginLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Security.fromJson(Map<String, dynamic> json) {
    return Security(
      id: json['_id'],
      userId: json['userId'],
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      twoFactorSecret: json['twoFactorSecret'],
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((session) => SecuritySession.fromJson(session))
              .toList() ??
          [],
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((alert) => SecurityAlert.fromJson(alert))
              .toList() ??
          [],
      trustedDevices: (json['trustedDevices'] as List<dynamic>?)
              ?.map((device) => TrustedDevice.fromJson(device))
              .toList() ??
          [],
      settings: SecuritySettings.fromJson(json['settings'] ?? {}),
      lastPasswordChange: json['lastPasswordChange'] != null
          ? DateTime.parse(json['lastPasswordChange'])
          : null,
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      lastLoginIp: json['lastLoginIp'],
      lastLoginLocation: json['lastLoginLocation'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorSecret': twoFactorSecret,
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'alerts': alerts.map((alert) => alert.toJson()).toList(),
      'trustedDevices':
          trustedDevices.map((device) => device.toJson()).toList(),
      'settings': settings.toJson(),
      'lastPasswordChange': lastPasswordChange?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'lastLoginLocation': lastLoginLocation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SecuritySession {
  final String? id;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String location;
  final String userAgent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastActivity;

  SecuritySession({
    this.id,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.location,
    required this.userAgent,
    this.isActive = true,
    required this.createdAt,
    this.lastActivity,
  });

  factory SecuritySession.fromJson(Map<String, dynamic> json) {
    return SecuritySession(
      id: json['_id'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      userAgent: json['userAgent'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'location': location,
      'userAgent': userAgent,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }
}

class SecurityAlert {
  final String? id;
  final String type;
  final String title;
  final String message;
  final String severity;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  SecurityAlert({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      severity: json['severity'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'message': message,
      'severity': severity,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class TrustedDevice {
  final String? id;
  final String deviceName;
  final String deviceType;
  final String deviceId;
  final String ipAddress;
  final String location;
  final DateTime addedAt;
  final DateTime? lastUsed;

  TrustedDevice({
    this.id,
    required this.deviceName,
    required this.deviceType,
    required this.deviceId,
    required this.ipAddress,
    required this.location,
    required this.addedAt,
    this.lastUsed,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['_id'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      deviceId: json['deviceId'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      addedAt: DateTime.parse(json['addedAt']),
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'location': location,
      'addedAt': addedAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
}

class SecuritySettings {
  final bool loginNotifications;
  final bool twoFactorRequired;
  final bool sessionTimeout;
  final int sessionTimeoutMinutes;
  final bool allowMultipleSessions;
  final bool requirePasswordChange;
  final int passwordChangeDays;

  SecuritySettings({
    this.loginNotifications = true,
    this.twoFactorRequired = false,
    this.sessionTimeout = true,
    this.sessionTimeoutMinutes = 30,
    this.allowMultipleSessions = true,
    this.requirePasswordChange = false,
    this.passwordChangeDays = 90,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      loginNotifications: json['loginNotifications'] ?? true,
      twoFactorRequired: json['twoFactorRequired'] ?? false,
      sessionTimeout: json['sessionTimeout'] ?? true,
      sessionTimeoutMinutes: json['sessionTimeoutMinutes'] ?? 30,
      allowMultipleSessions: json['allowMultipleSessions'] ?? true,
      requirePasswordChange: json['requirePasswordChange'] ?? false,
      passwordChangeDays: json['passwordChangeDays'] ?? 90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loginNotifications': loginNotifications,
      'twoFactorRequired': twoFactorRequired,
      'sessionTimeout': sessionTimeout,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'allowMultipleSessions': allowMultipleSessions,
      'requirePasswordChange': requirePasswordChange,
      'passwordChangeDays': passwordChangeDays,
    };
  }
}

