/// DASH-8E — Profils professionnels et `capabilities[]` (backend source de vérité).
class ProfessionalProfileSnapshot {
  const ProfessionalProfileSnapshot({
    required this.exists,
    this.id,
    this.status,
    this.canOperate = false,
  });

  final bool exists;
  final String? id;
  /// pending | active | rejected | suspended | null
  final String? status;
  final bool canOperate;

  factory ProfessionalProfileSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const ProfessionalProfileSnapshot(exists: false);
    }
    return ProfessionalProfileSnapshot(
      exists: json['exists'] == true || json['id'] != null,
      id: json['id']?.toString(),
      status: json['status']?.toString(),
      canOperate: json['canOperate'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'exists': exists,
        if (id != null) 'id': id,
        if (status != null) 'status': status,
        'canOperate': canOperate,
      };
}

class UserProfessionalCapabilities {
  const UserProfessionalCapabilities({
    this.capabilities = const [],
    this.prestataire = const ProfessionalProfileSnapshot(exists: false),
    this.freelance = const ProfessionalProfileSnapshot(exists: false),
    this.vendeur = const ProfessionalProfileSnapshot(exists: false),
    this.inconsistencies = const [],
  });

  /// Labels backend : Prestataire, Freelance, Vendeur (opérationnels uniquement).
  final List<String> capabilities;
  final ProfessionalProfileSnapshot prestataire;
  final ProfessionalProfileSnapshot freelance;
  final ProfessionalProfileSnapshot vendeur;
  final List<dynamic> inconsistencies;

  bool canOperateAs(String label) {
    final normalized = _normalizeLabel(label);
    return capabilities.any((c) => _normalizeLabel(c) == normalized);
  }

  bool hasProfile(String label) {
    switch (_normalizeLabel(label)) {
      case 'PRESTATAIRE':
        return prestataire.exists;
      case 'FREELANCE':
        return freelance.exists;
      case 'VENDEUR':
        return vendeur.exists;
      default:
        return false;
    }
  }

  ProfessionalProfileSnapshot profileFor(String label) {
    switch (_normalizeLabel(label)) {
      case 'PRESTATAIRE':
        return prestataire;
      case 'FREELANCE':
        return freelance;
      case 'VENDEUR':
        return vendeur;
      default:
        return const ProfessionalProfileSnapshot(exists: false);
    }
  }

  /// Rôles UI legacy (CLIENT + caps opérationnelles en majuscules).
  List<String> toLegacyRolesList({bool includeAdmin = false}) {
    final out = <String>['CLIENT'];
    if (includeAdmin) out.add('ADMIN');
    for (final c in capabilities) {
      out.add(_normalizeLabel(c));
    }
    return out;
  }

  factory UserProfessionalCapabilities.fromRolesApiResponse(
    Map<String, dynamic> body,
  ) {
    final capRaw = body['capabilities'];
    final capabilities = capRaw is List
        ? capRaw.map((e) => e.toString()).toList()
        : <String>[];

    Map<String, dynamic>? profilesMap;
    final data = body['data'];
    if (data is Map && data['profiles'] is Map) {
      profilesMap = Map<String, dynamic>.from(data['profiles'] as Map);
    }

    Map<String, dynamic>? details;
    if (body['details'] is Map) {
      details = Map<String, dynamic>.from(body['details'] as Map);
    }

    ProfessionalProfileSnapshot readProfile(String key) {
      if (profilesMap != null && profilesMap[key] is Map) {
        return ProfessionalProfileSnapshot.fromJson(
          Map<String, dynamic>.from(profilesMap[key] as Map),
        );
      }
      if (details != null && details[key] is Map) {
        final d = Map<String, dynamic>.from(details[key] as Map);
        return ProfessionalProfileSnapshot(
          exists: d['id'] != null,
          id: d['id']?.toString(),
          status: d['status']?.toString(),
          canOperate: d['canOperate'] == true,
        );
      }
      return const ProfessionalProfileSnapshot(exists: false);
    }

    final inconsistencies = body['inconsistencies'] is List
        ? List<dynamic>.from(body['inconsistencies'] as List)
        : (data is Map && data['inconsistencies'] is List)
            ? List<dynamic>.from(data['inconsistencies'] as List)
            : <dynamic>[];

    return UserProfessionalCapabilities(
      capabilities: capabilities,
      prestataire: readProfile('prestataire'),
      freelance: readProfile('freelance'),
      vendeur: readProfile('vendeur'),
      inconsistencies: inconsistencies,
    );
  }

  factory UserProfessionalCapabilities.fromJson(Map<String, dynamic> json) {
    final caps = json['capabilities'];
    return UserProfessionalCapabilities(
      capabilities: caps is List
          ? caps.map((e) => e.toString()).toList()
          : const [],
      prestataire: ProfessionalProfileSnapshot.fromJson(
        json['prestataire'] is Map
            ? Map<String, dynamic>.from(json['prestataire'] as Map)
            : null,
      ),
      freelance: ProfessionalProfileSnapshot.fromJson(
        json['freelance'] is Map
            ? Map<String, dynamic>.from(json['freelance'] as Map)
            : null,
      ),
      vendeur: ProfessionalProfileSnapshot.fromJson(
        json['vendeur'] is Map
            ? Map<String, dynamic>.from(json['vendeur'] as Map)
            : null,
      ),
      inconsistencies: json['inconsistencies'] is List
          ? List<dynamic>.from(json['inconsistencies'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'capabilities': capabilities,
        'prestataire': prestataire.toJson(),
        'freelance': freelance.toJson(),
        'vendeur': vendeur.toJson(),
        'inconsistencies': inconsistencies,
      };

  static String _normalizeLabel(String label) {
    final u = label.trim().toUpperCase();
    if (u == 'PRESTATAIRE' || u == 'MÉTIERS' || u == 'METIERS') {
      return 'PRESTATAIRE';
    }
    if (u == 'FREELANCE') return 'FREELANCE';
    if (u == 'VENDEUR' || u == 'BOUTIQUE') return 'VENDEUR';
    return u;
  }
}
