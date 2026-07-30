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
    return Security.fromBackend({'security': json});
  }

  /// Accepte `{ security: doc }` (API) ou le document plat.
  factory Security.fromBackend(Map<String, dynamic> payload) {
    final root = payload['security'] is Map
        ? Map<String, dynamic>.from(payload['security'] as Map)
        : payload;

    final twoFa = root['twoFactorAuth'] is Map
        ? Map<String, dynamic>.from(root['twoFactorAuth'] as Map)
        : <String, dynamic>{};

    final userRaw = root['utilisateur'] ?? root['userId'] ?? '';
    final userId = userRaw is Map
        ? (userRaw['_id'] ?? userRaw['id'] ?? '').toString()
        : userRaw.toString();

    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    List<Map<String, dynamic>> asMapList(dynamic v) {
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final sessions = asMapList(root['activeSessions'] ?? root['sessions'])
        .map(SecuritySession.fromJson)
        .toList();
    final alerts = asMapList(root['securityAlerts'] ?? root['alerts'])
        .map(SecurityAlert.fromJson)
        .toList();
    final devices = asMapList(root['trustedDevices'])
        .map(TrustedDevice.fromJson)
        .toList();

    final settingsRaw = root['securitySettings'] ?? root['settings'] ?? {};
    final settings = SecuritySettings.fromJson(
      settingsRaw is Map
          ? Map<String, dynamic>.from(settingsRaw)
          : <String, dynamic>{},
    );

    return Security(
      id: root['_id']?.toString(),
      userId: userId,
      twoFactorEnabled: twoFa['enabled'] == true ||
          root['twoFactorEnabled'] == true,
      twoFactorSecret: twoFa['secret']?.toString() ??
          root['twoFactorSecret']?.toString(),
      sessions: sessions,
      alerts: alerts,
      trustedDevices: devices,
      settings: settings,
      lastPasswordChange: root['lastPasswordChange'] != null
          ? parseDt(root['lastPasswordChange'])
          : null,
      lastLogin: root['securityStats']?['lastLogin'] != null
          ? parseDt(root['securityStats']['lastLogin'])
          : (root['lastLogin'] != null ? parseDt(root['lastLogin']) : null),
      lastLoginIp: root['lastLoginIp']?.toString(),
      lastLoginLocation: root['lastLoginLocation']?.toString(),
      createdAt: parseDt(root['createdAt']),
      updatedAt: parseDt(root['updatedAt']),
    );
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
    DateTime parseDt(dynamic v) =>
        DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    return SecuritySession(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      deviceName: (json['deviceName'] ?? json['device'] ?? 'Appareil').toString(),
      deviceType: (json['deviceType'] ?? json['platform'] ?? 'unknown').toString(),
      ipAddress: (json['ipAddress'] ?? json['ip'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      userAgent: (json['userAgent'] ?? '').toString(),
      isActive: json['isActive'] ?? json['success'] ?? true,
      createdAt: parseDt(json['createdAt'] ?? json['loginTime']),
      lastActivity: json['lastActivity'] != null
          ? parseDt(json['lastActivity'])
          : (json['loginTime'] != null ? parseDt(json['loginTime']) : null),
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
      id: json['_id']?.toString() ?? json['id']?.toString(),
      type: (json['type'] ?? 'INFO').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      severity: (json['severity'] ?? 'LOW').toString(),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
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
    DateTime parseDt(dynamic v) =>
        DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    return TrustedDevice(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      deviceName: (json['deviceName'] ?? 'Appareil').toString(),
      deviceType: (json['deviceType'] ?? 'unknown').toString(),
      deviceId: (json['deviceId'] ?? json['_id'] ?? '').toString(),
      ipAddress: (json['ipAddress'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      addedAt: parseDt(json['addedAt'] ?? json['createdAt']),
      lastUsed:
          json['lastUsed'] != null ? parseDt(json['lastUsed']) : null,
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
    final emailNotifs = json['emailNotifications'];
    final loginNotif = json['loginNotifications'] ??
        (emailNotifs is Map ? emailNotifs['newLogin'] : null);

    final rawTimeout = json['sessionTimeout'];
    final timeoutMinutes = json['sessionTimeoutMinutes'] is num
        ? (json['sessionTimeoutMinutes'] as num).toInt()
        : (rawTimeout is num ? rawTimeout.toInt() : 30);

    return SecuritySettings(
      loginNotifications: loginNotif == true || loginNotif == null,
      twoFactorRequired: json['twoFactorRequired'] == true,
      sessionTimeout: rawTimeout is bool
          ? rawTimeout
          : (rawTimeout is num ? rawTimeout > 0 : true),
      sessionTimeoutMinutes: timeoutMinutes,
      allowMultipleSessions: json['allowMultipleSessions'] ??
          ((json['maxConcurrentSessions'] is num)
              ? (json['maxConcurrentSessions'] as num) > 1
              : true),
      requirePasswordChange: json['requirePasswordChange'] == true,
      passwordChangeDays: json['passwordChangeDays'] is num
          ? (json['passwordChangeDays'] as num).toInt()
          : 90,
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

