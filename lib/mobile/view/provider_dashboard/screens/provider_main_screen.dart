import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/cache_service.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/missions_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/planning_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/messages_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/notifications_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_missions_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_planning_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_messages_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_notifications_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_profile_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_edit_service_tariff_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/models/provider_mission.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/provider_profile_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_settings_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_statistics_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/provider_statistics_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/widgets/provider_home_dashboard.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/professional_dossier_status.dart';
import 'package:sdealsmobile/mobile/view/common/role_shell_navigation.dart';

class ProviderMainScreen extends StatefulWidget {
  final Utilisateur? utilisateur; // ⚡ reçoit le prestataire (nullable)

  const ProviderMainScreen({Key? key, this.utilisateur}) : super(key: key);

  @override
  _ProviderMainScreenState createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();
  
  // 📊 Données réelles du dashboard
  int _pendingMissionsCount = 0;
  int _ongoingMissionsCount = 0;
  double _monthlyRevenue = 0.0;
  bool _isLoadingStats = true;
  bool _statsKnown = false;
  bool _docLookupDone = false;
  bool _docUnavailable = false;
  bool _docStale = false;

  // 🆔 ID du document prestataire (différent de l'ID utilisateur)
  String? _prestataireDocId;
  String _prestataireStatus = '';
  int _unreadNotificationsCount = 0;
  int _unreadMessagesCount = 0;
  Timer? _notifPollTimer;
  /// Poll léger uniquement tant que le dossier n'est pas actif.
  Timer? _statusPollTimer;

  // Profil Accueil (Figma)
  Map<String, dynamic>? _prestataireDoc;
  bool _isAvailable = true;
  List<Map<String, dynamic>> _recentMissions = [];
  List<Map<String, dynamic>> _pendingToProcess = [];
  Map<String, dynamic>? _nextIntervention;
  int _missionsEnCoursCount = 0;
  List<Map<String, dynamic>> _recentReviews = [];
  List<int> _weeklyActivity = List.filled(7, 0);
  double _soldeDisponible = 0;
  double _soldeEnAttente = 0;
  int _totalDemandesMois = 0;
  double _rating = 0;
  int _reviewCount = 0;

  /// Onglets stables (évite de recréer les BLoC à chaque setState).
  String? _tabsBoundDocId;
  Widget? _missionsTab;
  Widget? _planningTab;
  Widget? _messagesTab;
  Widget? _profileTab;
  final GlobalKey<ProviderMissionsScreenState> _missionsKey =
      GlobalKey<ProviderMissionsScreenState>();
  final GlobalKey<ProviderPlanningScreenState> _planningKey =
      GlobalKey<ProviderPlanningScreenState>();
  final GlobalKey<ProviderMessagesScreenState> _messagesKey =
      GlobalKey<ProviderMessagesScreenState>();
  final GlobalKey<ProviderProfileScreenState> _profileKey =
      GlobalKey<ProviderProfileScreenState>();

  // Titres des écrans pour l'AppBar (hors Accueil)
  final List<String> _titles = [
    'Espace Prestataire',
    'Missions',
    'Planning',
    'Messagerie',
    'Profil'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initPrestataireData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifPollTimer?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Retour app / multitâche → statut à jour sans bouton
      _initPrestataireData();
      // STAB-05 : reprise Socket seulement si déconnecté.
      WebSocketService().resumeIfNeeded();
    }
  }

  void _syncStatusPolling() {
    final status = _resolveDashboardStatus();
    final waiting = status == 'pending' || status == 'incomplete';
    if (waiting) {
      _statusPollTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
        if (!mounted) return;
        _refreshPrestataireStatusOnly();
      });
    } else {
      _statusPollTimer?.cancel();
      _statusPollTimer = null;
    }
  }

  /// Recharge uniquement le doc prestataire (léger, pour passage pending → active).
  Future<void> _refreshPrestataireStatusOnly() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final userId = auth.utilisateur.idutilisateur;
    if (userId == null) return;
    try {
      final prestataireDoc =
          await _apiClient.getPrestataireByUserId(userId, auth.token);
      if (prestataireDoc == null || !mounted) return;
      final previous = _resolveDashboardStatus();
      setState(() {
        _prestataireDoc = prestataireDoc;
        _prestataireDocId = prestataireDoc['_id']?.toString();
        _prestataireStatus =
            (prestataireDoc['status']?.toString() ?? 'pending').toLowerCase();
        if (prestataireDoc['verifier'] == true ||
            prestataireDoc['verified'] == true) {
          _prestataireStatus = 'active';
        }
      });
      _syncStatusPolling();
      if (previous != 'active' && _resolveDashboardStatus() == 'active') {
        await _loadDashboardStats();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('refresh statut prestataire échoué');
    }
  }

  void _applyPrestataireDoc(Map<String, dynamic> doc, {required bool stale}) {
    _prestataireDoc = doc;
    _prestataireDocId = doc['_id']?.toString();
    _prestataireStatus = (doc['status']?.toString() ?? '').toLowerCase();
    if (doc['verifier'] == true || doc['verified'] == true) {
      _prestataireStatus = 'active';
    }
    _isAvailable = doc['disponible'] != false &&
        doc['disponibilite']?.toString().toLowerCase() != 'indisponible';
    _rating = _asDouble(doc['note']);
    final reviews = doc['nbAvis'] ?? doc['nombreAvis'];
    _reviewCount = reviews is int ? reviews : int.tryParse('$reviews') ?? _reviewCount;
    _docLookupDone = true;
    _docUnavailable = false;
    _docStale = stale;
  }

  // 🆔 Initialiser les données prestataire (id réel + stats)
  Future<void> _initPrestataireData() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    final userId = auth.utilisateur.idutilisateur;
    final token = auth.token;

    // Récupérer le document prestataire par userId
    try {
      var prestataireDoc =
          await _apiClient.getPrestataireByUserId(userId, token);
      if (prestataireDoc != null) {
        final docId = prestataireDoc['_id']?.toString();
        if (docId != null && docId.isNotEmpty) {
          try {
            final detail = await _apiClient.get(
              '/prestataire/$docId',
              token: token,
            );
            if (detail.statusCode == 200) {
              final decoded = jsonDecode(detail.body);
              if (decoded is Map) {
                prestataireDoc = Map<String, dynamic>.from(decoded);
              }
            }
          } catch (_) {}
        }
      }
      final doc = prestataireDoc;
      if (!mounted) return;
      if (doc != null) {
        try {
          await CacheService().cacheData('private_prestataire_$userId', doc);
        } catch (_) {}
        setState(() => _applyPrestataireDoc(doc, stale: false));
        _syncStatusPolling();
      } else {
        setState(() {
          _docLookupDone = true;
          _docUnavailable = false;
          if (_prestataireDoc == null) _docStale = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('prestataire doc indisponible');
      Map<String, dynamic>? saved;
      try {
        final retained =
            await CacheService().readRetained('private_prestataire_$userId');
        final data = retained?.data;
        if (data is Map) saved = Map<String, dynamic>.from(data);
      } catch (_) {}
      if (!mounted) return;
      if (saved != null) {
        setState(() => _applyPrestataireDoc(saved!, stale: true));
        _syncStatusPolling();
      } else if (_prestataireDoc != null) {
        setState(() {
          _docLookupDone = true;
          _docStale = true;
        });
      } else {
        setState(() {
          _docLookupDone = true;
          _docUnavailable = true;
          _docStale = false;
        });
      }
    }

    if (!mounted) return;

    // Charger les stats dashboard
    await _loadDashboardStats();

    if (!mounted) return;

    // Charger le nombre de notifications / messages non lus
    await Future.wait([
      _loadUnreadNotificationsCount(),
      _loadUnreadMessagesCount(),
      _loadRecentReviews(),
    ]);
    if (!mounted) return;
    _notifPollTimer?.cancel();
    _notifPollTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (!mounted) return;
      _loadUnreadNotificationsCount();
      _loadUnreadMessagesCount();
    });
  }

  /// Persiste le toggle disponibilité via PUT `/prestataire/:id`.
  Future<void> _setAvailability(bool value) async {
    final previous = _isAvailable;
    setState(() => _isAvailable = value);

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      setState(() => _isAvailable = previous);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée — reconnectez-vous'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final id = _prestataireDocId;
    if (id == null || id.isEmpty) {
      setState(() => _isAvailable = previous);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil prestataire introuvable'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final response = await _apiClient.put(
        '/prestataire/$id',
        body: {'disponible': value},
        token: auth.token,
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Vous êtes maintenant disponible'
                  : 'Vous êtes maintenant indisponible',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isAvailable = previous);
        String message = 'Impossible de mettre à jour la disponibilité';
        try {
          final data = ApiClient.decodeJson(response);
          if (data is Map && (data['error'] != null || data['message'] != null)) {
            message = (data['error'] ?? data['message']).toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAvailable = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🔔 Charger le nombre de notifications non lues
  Future<void> _loadUnreadNotificationsCount() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    try {
      final count = await _apiClient.getUserUnreadNotificationCount(
        token: auth.token,
        userId: auth.utilisateur.idutilisateur,
      );
      if (!mounted) return;
      setState(() => _unreadNotificationsCount = count);
    } catch (e) {
      print('Erreur unread count: $e');
    }
  }

  Future<void> _loadUnreadMessagesCount() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final userId = auth.utilisateur.idutilisateur;
    if (userId.isEmpty) {
      if (mounted) setState(() => _unreadMessagesCount = 0);
      return;
    }
    try {
      final messages = await _apiClient.getUnreadMessages(
        userId,
        token: auth.token,
        limit: 50,
      );
      if (!mounted) return;
      setState(() => _unreadMessagesCount = messages.length);
    } catch (e) {
      print('Erreur unread messages: $e');
      if (mounted) setState(() => _unreadMessagesCount = 0);
    }
  }

  Future<void> _loadRecentReviews() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final objetId = _prestataireDocId;
    if (objetId == null || objetId.isEmpty) {
      if (mounted) setState(() => _recentReviews = []);
      return;
    }
    try {
      final response = await _apiClient.get(
        '/avis?objetType=PRESTATAIRE&objetId=$objetId&limit=5',
        token: auth.token,
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = const [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = (decoded['avis'] ??
                  decoded['data'] ??
                  decoded['results'] ??
                  []) as List<dynamic>? ??
              [];
        }
        setState(() {
          _recentReviews = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } else {
        setState(() => _recentReviews = []);
      }
    } catch (e) {
      print('Erreur avis récents: $e');
      if (mounted) setState(() => _recentReviews = []);
    }
  }

  // 🚀 Charger les statistiques du dashboard
  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        final token = auth.token;
        final prestataireId = _prestataireDocId ?? auth.utilisateur.idutilisateur;
        
        // Charger les missions en attente pour ce prestataire
        final pendingMissions = await _apiClient.getPrestationsByStatus(
          token: token,
          status: 'EN_ATTENTE',
          prestataireId: _prestataireDocId,
        );
        
        // Charger les missions en cours
        final ongoingMissions = await _apiClient.getPrestationsByStatus(
          token: token,
          status: 'EN_COURS',
          prestataireId: _prestataireDocId,
        );

        // Missions acceptées / récentes pour la liste Figma
        List<Map<String, dynamic>> accepted = [];
        try {
          accepted = await _apiClient.getPrestationsByStatus(
            token: token,
            status: 'ACCEPTEE',
            prestataireId: _prestataireDocId,
          );
        } catch (_) {}

        final recent = <Map<String, dynamic>>[
          ...pendingMissions,
          ...ongoingMissions,
          ...accepted,
        ];
        recent.sort((a, b) {
          final da = DateTime.tryParse('${a['createdAt'] ?? a['date'] ?? ''}');
          final db = DateTime.tryParse('${b['createdAt'] ?? b['date'] ?? ''}');
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        
        // Charger les statistiques (endpoint correct)
        Map<String, dynamic> stats = {};
        if (prestataireId != null) {
          try {
            final statsResponse = await _apiClient.get(
              '/prestations/stats?prestataireId=$prestataireId',
              token: token,
            );
            if (statsResponse.statusCode == 200) {
              stats = jsonDecode(statsResponse.body) as Map<String, dynamic>;
            }
          } catch (e) {
            print('Erreur stats: $e');
          }
        }

        final weekly = _buildWeeklyActivityFromMissions(recent);
        final totalDemandes = (stats['total'] ??
                stats['totalPrestations'] ??
                pendingMissions.length +
                    ongoingMissions.length +
                    accepted.length) is num
            ? ((stats['total'] ??
                    stats['totalPrestations'] ??
                    pendingMissions.length +
                        ongoingMissions.length +
                        accepted.length) as num)
                .toInt()
            : pendingMissions.length + ongoingMissions.length + accepted.length;
        
        final nextIntervention = _pickNextIntervention([
          ...accepted,
          ...ongoingMissions,
        ]);

        if (mounted) {
          setState(() {
            _pendingMissionsCount = pendingMissions.length;
            _ongoingMissionsCount = ongoingMissions.length;
            _missionsEnCoursCount =
                accepted.length + ongoingMissions.length;
            _pendingToProcess = pendingMissions;
            _nextIntervention = nextIntervention;
            _monthlyRevenue = (stats['revenueTotal'] ??
                    stats['revenus'] ??
                    _prestataireDoc?['revenus'] ??
                    0)
                .toDouble();
            _recentMissions = recent.take(5).toList();
            _weeklyActivity = weekly;
            _totalDemandesMois = totalDemandes;
            _soldeDisponible = _asDouble(
              stats['soldeDisponible'] ??
                  _prestataireDoc?['solde'] ??
                  _monthlyRevenue,
            );
            _soldeEnAttente = _asDouble(stats['soldeEnAttente'] ?? 0);
            _isLoadingStats = false;
            _statsKnown = true;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement stats dashboard: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }
  
  double _asDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  Map<String, dynamic>? _pickNextIntervention(
    List<Map<String, dynamic>> missions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<String, dynamic>? best;
    DateTime? bestMoment;

    for (final m in missions) {
      final statut =
          (m['statut'] ?? m['status'] ?? '').toString().toUpperCase();
      if (statut != 'ACCEPTEE' &&
          statut != 'EN_COURS' &&
          statut != 'CONFIRMEE') {
        continue;
      }
      final raw = m['datePrestation'] ?? m['date'];
      final day = DateTime.tryParse('$raw')?.toLocal();
      if (day == null) continue;
      final dayOnly = DateTime(day.year, day.month, day.day);
      if (dayOnly.isBefore(today) && statut != 'EN_COURS') continue;

      final start = _parsePrestationTime(day, m['heureDebut']);
      final moment = start ?? dayOnly;
      if (bestMoment == null || moment.isBefore(bestMoment)) {
        bestMoment = moment;
        best = m;
      }
    }
    return best;
  }

  DateTime? _parsePrestationTime(DateTime day, dynamic heureDebut) {
    if (heureDebut == null) return null;
    final s = heureDebut.toString().trim();
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);
    if (h == null || min == null) return null;
    return DateTime(day.year, day.month, day.day, h, min);
  }

  String _cleanMetierLabel(dynamic raw) {
    var s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return 'Prestataire';
    if (s.startsWith('[') && s.endsWith(']')) {
      s = s.substring(1, s.length - 1).trim();
    }
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s.isEmpty ? 'Prestataire' : s;
  }

  List<int> _buildWeeklyActivityFromMissions(List<Map<String, dynamic>> missions) {
    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    for (final m in missions) {
      final raw = m['createdAt'] ?? m['date'] ?? m['datePrestation'];
      final d = DateTime.tryParse('$raw');
      if (d == null) continue;
      final local = d.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final diff = day.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    // Zéros honnêtes si aucune activité (pas de silhouette fictive)
    return counts;
  }

  // ✅ DASHBOARD AVEC VÉRIFICATION DU STATUT
  Widget _buildSimpleDashboard() {
    if (!_docLookupDone && _prestataireDoc == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_prestataireDoc == null && _docUnavailable) {
      return SDConnectionRequired(onRetry: _initPrestataireData);
    }
    if (_prestataireDoc == null) {
      return _buildIncompleteProfileDashboard();
    }

    final prestataireStatus = _resolveDashboardStatus();

    if (prestataireStatus == 'incomplete') {
      return _buildIncompleteProfileDashboard();
    } else if (prestataireStatus == 'pending') {
      return _buildPendingValidationDashboard();
    } else if (prestataireStatus == 'rejected' ||
        prestataireStatus == 'suspended') {
      return _buildBlockedDashboard(prestataireStatus);
    } else {
      return _buildActiveDashboard();
    }
  }

  /// Statut UI : `verifier: true` ou `active` → dashboard actif.
  String _resolveDashboardStatus() {
    final raw = (_prestataireDoc?['status'] ?? _prestataireStatus)
        .toString()
        .toLowerCase()
        .trim();
    final verified = _prestataireDoc?['verifier'] == true ||
        _prestataireDoc?['verified'] == true;

    if (raw == 'rejected' || raw == 'suspended') return raw;
    if (verified || raw == 'active' || raw == 'valide' || raw == 'validated') {
      return 'active';
    }
    if (raw == 'incomplete') return 'incomplete';
    if (raw == 'pending') return 'pending';
    // Doc présent mais statut inconnu : ne pas bloquer si vérifié
    return verified ? 'active' : (raw.isEmpty ? 'pending' : raw);
  }

  // 🚨 DASHBOARD POUR PROFIL INCOMPLET (body only — pas de Scaffold imbriqué)
  Widget _buildIncompleteProfileDashboard() {
    return ColoredBox(
      color: SDColors.neutral50,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBoutiqueHomeHeader(showActions: true),
              SizedBox(height: SDSpacing.lg),
              IncompleteProviderDossier(
                items: missingProviderCompletionItems(_prestataireDoc),
                onComplete: () {
                  context.push(
                    '/prestataire-finalization',
                    extra: _prestataireDocId,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚫 Compte rejeté / suspendu — UI dédiée (pas le dashboard actif)
  Widget _buildBlockedDashboard(String status) {
    final isSuspended = status == 'suspended';
    final motif = _prestataireDoc?['motifRejet']?.toString();
    final copy = ProfessionalDossierCopy.resolve(
      status: status,
      motif: motif,
    )!;

    return ColoredBox(
      color: SDColors.neutral50,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _initPrestataireData,
          color: SDColors.primary600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBoutiqueHomeHeader(showActions: true),
                SizedBox(height: SDSpacing.lg),
                ProfessionalDossierCard(
                  copy: copy,
                  onAction: isSuspended
                      ? null
                      : () {
                          context.push(
                            '/prestataire-finalization',
                            extra: _prestataireDocId,
                          );
                        },
                ),
                SizedBox(height: SDSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => goToClientShell(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.neutral900,
                      side: BorderSide(color: SDColors.neutral300),
                      padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Retour au mode Client',
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⏳ DASHBOARD POUR VALIDATION EN COURS (body only)
  Widget _buildPendingValidationDashboard() {
    return ColoredBox(
      color: SDColors.neutral50,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _initPrestataireData,
          color: SDColors.primary600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBoutiqueHomeHeader(showActions: true),
                SizedBox(height: SDSpacing.lg),
                ProfessionalDossierCard(
                  copy: ProfessionalDossierCopy.resolve(status: 'pending')!,
                ),
                SizedBox(height: SDSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => goToClientShell(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.neutral900,
                      side: BorderSide(color: SDColors.neutral300),
                      padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Retour au mode Client',
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Accueil actif — maquette Figma prestataire
  Widget _buildActiveDashboard() {
    final user = widget.utilisateur;
    final auth = context.read<AuthCubit>().state;
    final authUser = auth is AuthAuthenticated ? auth.utilisateur : null;
    final displayName = [
      user?.prenom ?? authUser?.prenom,
      user?.nom ?? authUser?.nom,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    final metier = prestataireMetierLabel(_prestataireDoc);

    String location = 'Abidjan';
    final loc = _prestataireDoc?['localisation'];
    if (loc is Map) {
      location = (loc['adresse'] ?? loc['commune'] ?? loc['ville'] ?? location)
          .toString();
    } else if (loc != null && loc.toString().isNotEmpty) {
      location = loc.toString();
    }

    final photo = providerPhotoUrl(
      photoProfil: user?.photoProfil ?? authUser?.photoProfil,
      utilisateurMap: {
        'photoProfil': user?.photoProfil ?? authUser?.photoProfil,
      },
      prestataireMap: _prestataireDoc,
    );

    final verified = _prestataireDoc?['verifier'] == true ||
        _prestataireStatus == 'active' ||
        _prestataireStatus == 'VALIDE';

    final demandesRecues = _totalDemandesMois > 0
        ? _totalDemandesMois
        : _pendingMissionsCount + _missionsEnCoursCount;

    return Column(
      children: [
        if (_docStale)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SDOfflineSavedBanner(),
          ),
        Expanded(
          child: ProviderHomeDashboard(
      fullName: displayName.isEmpty ? 'Prestataire' : displayName,
      photoUrl: photo,
      metier: metier,
      location: location,
      isVerified: verified,
      isAvailable: _isAvailable,
      availabilityLocalOnly: false,
      onAvailabilityChanged: _setAvailability,
      pendingMissions: _pendingToProcess,
      nextIntervention: _nextIntervention,
      demandesRecues: demandesRecues,
      missionsEnCours: _missionsEnCoursCount,
      isLoadingStats: _isLoadingStats || !_statsKnown,
      unreadMessages: _unreadMessagesCount,
      unreadNotifications: _unreadNotificationsCount,
      onRefresh: _initPrestataireData,
      onOpenStats: _showProviderStatistics,
      onOpenServices: _openServiceTariff,
      onOpenMessages: () => setState(() => _currentIndex = 3),
      onOpenPlanning: () => setState(() => _currentIndex = 2),
      onOpenProfile: () => setState(() => _currentIndex = 4),
      onOpenMissions: () => setState(() => _currentIndex = 1),
      onOpenMission: _openMissionDetail,
      expertMenuAction: _buildExpertMenu(context, circle: true),
      onOpenNotifications: _showNotificationsScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildBoutiqueHomeHeader({required bool showActions}) {
    final name = (widget.utilisateur?.prenom ?? 'Prestataire').toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: SDColors.neutral200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline_rounded, color: SDColors.neutral900, size: 28),
        ),
        SizedBox(width: SDSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Espace prestataire',
                style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
            ],
          ),
        ),
        if (showActions) ...[
          _buildRoundIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: _showNotificationsScreen,
            badge: _unreadNotificationsCount,
          ),
          SizedBox(width: SDSpacing.xs),
          _buildRoundIconButton(
            icon: Icons.close,
            onTap: () => goToClientShell(context),
          ),
        ],
      ],
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: SDColors.neutral100,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: SDColors.neutral900, size: 20),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: SDColors.error500,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badge',
                textAlign: TextAlign.center,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ✅ Onglets stables — missions/planning/profil si docId change ; messages une seule fois
  void _ensureTabScreens() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;

    // Messagerie ne dépend pas du docId → ne pas recréer (évite spam WebSocket).
    _messagesTab ??= BlocProvider<MessagesBloc>(
      create: (_) {
        final bloc = MessagesBloc();
        if (token != null) bloc.setToken(token);
        return bloc;
      },
      child: ProviderMessagesScreen(key: _messagesKey),
    );

    final bind = '$_prestataireDocId|$_docLookupDone';
    if (_missionsTab != null && _tabsBoundDocId == bind) return;
    _tabsBoundDocId = bind;

    _missionsTab = BlocProvider(
      create: (_) {
        final bloc = MissionsBloc();
        if (token != null) bloc.setToken(token);
        if (_prestataireDocId != null) bloc.setPrestataireId(_prestataireDocId!);
        return bloc;
      },
      child: ProviderMissionsScreen(
        key: _missionsKey,
        prestataireDocId: _prestataireDocId,
      ),
    );

    _planningTab = BlocProvider<PlanningBloc>(
      create: (_) {
        final bloc = PlanningBloc();
        if (token != null) bloc.setToken(token);
        if (_prestataireDocId != null) bloc.setPrestataireId(_prestataireDocId!);
        return bloc;
      },
      child: ProviderPlanningScreen(
        key: _planningKey,
        prestataireDocId: _prestataireDocId,
      ),
    );

    _profileTab = BlocProvider<ProviderProfileBloc>(
      create: (_) {
        final bloc = ProviderProfileBloc();
        if (token != null) bloc.setToken(token);
        return bloc;
      },
      child: ProviderProfileScreen(
        key: _profileKey,
        prestataireDocId: _prestataireDocId,
        lookupSettled: _docLookupDone,
        embeddedInTab: true,
      ),
    );
  }

  PreferredSizeWidget _buildProAppBar(BuildContext context) {
    // Chrome clair type Yango / Meta : blanc, texte sombre, vert seulement en accent ailleurs
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: SDColors.white,
      foregroundColor: SDColors.neutral900,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 64,
      title: Text(
        _titles[_currentIndex],
        style: SDTypography.displayMedium.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (_currentIndex == 1) ...[
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search_rounded, color: SDColors.neutral900),
            onPressed: () => _missionsKey.currentState?.toggleSearch(),
          ),
          IconButton(
            tooltip: 'Filtrer',
            icon: const Icon(Icons.tune_rounded, color: SDColors.neutral900),
            onPressed: () => _missionsKey.currentState?.openFilters(),
          ),
        ],
        if (_currentIndex == 2) ...[
          IconButton(
            tooltip: "Aujourd'hui",
            icon: const Icon(Icons.today_outlined, color: SDColors.neutral900),
            onPressed: () => _planningKey.currentState?.goToToday(),
          ),
          IconButton(
            tooltip: 'Disponibilités',
            icon: const Icon(Icons.event_available_outlined,
                color: SDColors.neutral900),
            onPressed: () => _planningKey.currentState?.openDisponibilites(),
          ),
        ],
        if (_currentIndex == 3) ...[
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search_rounded, color: SDColors.neutral900),
            onPressed: () => _messagesKey.currentState?.toggleSearch(),
          ),
          IconButton(
            tooltip: 'Filtrer',
            icon: const Icon(Icons.tune_rounded, color: SDColors.neutral900),
            onPressed: () => _messagesKey.currentState?.openFilters(),
          ),
        ],
        if (_currentIndex == 4) ...[
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, color: SDColors.neutral900),
            onPressed: () => _profileKey.currentState?.openEdit(),
          ),
        ],
        IconButton(
          icon: Badge(
            isLabelVisible: _unreadNotificationsCount > 0,
            backgroundColor: SDColors.error500,
            label: Text(
              '$_unreadNotificationsCount',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            child: const Icon(Icons.notifications_none_rounded),
          ),
          onPressed: _showNotificationsScreen,
        ),
        _buildExpertMenu(context, circle: false),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: SDColors.neutral200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureTabScreens();

    // Retour Android : un onglet pro autre qu'Accueil revient à l'Accueil
    // pro (jamais vers le shell client). Les sous-écrans poussés au-dessus
    // gardent leur propre pop. Sur l'Accueil pro : sortie normale.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted || _currentIndex == 0) return;
        _selectProTab(0);
      },
      child: Scaffold(
        backgroundColor: SDColors.neutral50,
        // Accueil a son propre header (style boutique) → pas d'AppBar parent
        appBar: _currentIndex == 0 ? null : _buildProAppBar(context),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildSimpleDashboard(),
            _missionsTab!,
            _planningTab!,
            _messagesTab!,
            _profileTab!,
          ],
        ),
        bottomNavigationBar: _buildProBottomNavBar(),
      ),
    );
  }

  void _selectProTab(int index) {
    final wasHome = _currentIndex == 0;
    setState(() => _currentIndex = index);
    if (index == 0 && !wasHome) {
      _refreshPrestataireStatusOnly();
    }
  }

  Widget _buildProBottomNavBar() {
    return ProviderBottomNavigation(
      currentIndex: _currentIndex,
      onTap: _selectProTab,
    );
  }

  void _onExpertMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'profil':
        _showProviderProfile();
        break;
      case 'parametres':
        _showProviderSettings();
        break;
      case 'statistiques':
        _showProviderStatistics();
        break;
      case 'retour_client':
        _switchToClientMode(context);
        break;
      case 'deconnexion':
        _logout(context);
        break;
    }
  }

  List<PopupMenuEntry<String>> _expertMenuItems() {
    return [
      PopupMenuItem<String>(
        value: 'profil',
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: SDColors.neutral900),
            const SizedBox(width: 12),
            const Text('Mon Profil'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'parametres',
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: SDColors.neutral900),
            const SizedBox(width: 12),
            const Text('Paramètres'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'statistiques',
        child: Row(
          children: [
            Icon(Icons.bar_chart_outlined, color: SDColors.neutral900),
            const SizedBox(width: 12),
            const Text('Statistiques'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'retour_client',
        child: Row(
          children: [
            Icon(Icons.home_outlined, color: SDColors.neutral900),
            const SizedBox(width: 12),
            const Text('Retour Client'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'deconnexion',
        child: Row(
          children: [
            Icon(Icons.logout_rounded, color: SDColors.error600),
            const SizedBox(width: 12),
            Text('Déconnexion', style: TextStyle(color: SDColors.error600)),
          ],
        ),
      ),
    ];
  }

  Widget _buildExpertMenu(BuildContext context, {required bool circle}) {
    final icon = const Icon(Icons.more_vert, color: SDColors.neutral900, size: 22);
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      padding: circle ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
      tooltip: 'Plus d’options',
      onSelected: (value) => _onExpertMenuSelected(context, value),
      itemBuilder: (BuildContext context) => _expertMenuItems(),
      child: circle
          ? Material(
              color: SDColors.neutral50,
              shape: const CircleBorder(),
              child: SizedBox(width: 40, height: 40, child: icon),
            )
          : icon,
    );
  }

  // 🔄 SWITCH VERS MODE CLIENT
  // go (pas push) : le shell client remplace le shell pro, sans pile croisée.
  void _switchToClientMode(BuildContext context) {
    if (!mounted) return;
    goToClientShell(this.context);
  }

  // 🚪 DÉCONNEXION
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
              context.go('/login');
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  // (ancien build / bottom nav vert — remplacés par IndexedStack + _buildPro*)

  // 🔔 AFFICHER L'ÉCRAN DE NOTIFICATIONS
  void _showNotificationsScreen() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<NotificationsBloc>(
          create: (context) {
            final bloc = NotificationsBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderNotificationsScreen(
            prestataireDocId: _prestataireDocId,
            onOpenMissions: () {
              if (mounted) setState(() => _currentIndex = 1);
            },
            onOpenMessages: () {
              if (mounted) setState(() => _currentIndex = 3);
            },
          ),
        ),
      ),
    ).then((_) => _loadUnreadNotificationsCount());
  }

  Future<void> _openMissionDetail(Map<String, dynamic> mission) async {
    final id = prestationIdOf(mission);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission introuvable')),
      );
      return;
    }
    final changed = await context.push<bool>(
      '/mission-details/$id',
      extra: _prestataireDocId == null
          ? null
          : {'prestataireDocId': _prestataireDocId},
    );
    if (changed == true && mounted) {
      _initPrestataireData();
      _missionsKey.currentState?.reload();
    }
  }

  Future<void> _openServiceTariff() async {
    final id = _prestataireDocId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire non chargé')),
      );
      return;
    }
    final doc = _prestataireDoc ?? {};
    final service = doc['service'];
    var serviceName = prestataireMetierLabel(doc);
    String? serviceId;
    String? categoryLabel;
    String? categoryId;
    if (service is Map) {
      serviceId = service['_id']?.toString();
      serviceName =
          cleanDisplayPart(service['nomservice'] ?? service['nom']) ??
              serviceName;
      final cat = service['categorie'];
      if (cat is Map) {
        categoryId = cat['_id']?.toString();
        categoryLabel = cleanDisplayPart(
          cat['nomcategorie'] ?? cat['nom'],
        );
      }
    }
    final rate = doc['prixprestataire'];
    double? dailyRate;
    if (rate is num) dailyRate = rate.toDouble();

    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) {
            final bloc = ProviderProfileBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderEditServiceTariffScreen(
            prestataireId: id,
            serviceName: serviceName,
            serviceId: serviceId,
            categoryLabel: categoryLabel,
            categoryId: categoryId,
            initialDailyRate: dailyRate,
          ),
        ),
      ),
    );
    if (mounted) _initPrestataireData();
  }

  // SoutraPay V1 : pas de simulation financière (Random / fake balance).
  void _showSoutraPayScreen() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SoutraPay arrive bientôt'),
        content: const Text(
          'Les paiements, soldes et retraits seront disponibles '
          'lorsque le service sera branché. Aucune opération fictive '
          'n’est proposée pour le moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // 👤 AFFICHER L'ÉCRAN PROFIL PRESTATAIRE
  void _showProviderProfile() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderProfileBloc>(
          create: (context) {
            final bloc = ProviderProfileBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderProfileScreen(prestataireDocId: _prestataireDocId),
        ),
      ),
    );
  }

  // ⚙️ AFFICHER L'ÉCRAN PARAMÈTRES
  void _showProviderSettings() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderProfileBloc>(
          create: (context) {
            final bloc = ProviderProfileBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderSettingsScreen(prestataireDocId: _prestataireDocId),
        ),
      ),
    );
  }

  // 📊 AFFICHER L'ÉCRAN STATISTIQUES
  void _showProviderStatistics() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderStatisticsBloc>(
          create: (context) {
            final bloc = ProviderStatisticsBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderStatisticsScreen(prestataireDocId: _prestataireDocId),
        ),
      ),
    );
  }

  // 🎯 MÉTHODE POUR VÉRIFIER LE STATUT DU PRESTATAIRE
  String _getPrestataireStatus() => _resolveDashboardStatus();
}

/// Barre d’onglets prestataire. La marge système est hors du contenu
/// (pas de hauteur fixe partagée avec l’inset Android).
class ProviderBottomNavigation extends StatelessWidget {
  const ProviderBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (Icons.work_outline_rounded, Icons.work_rounded, 'Missions'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Planning'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final sysBottom = SDResponsive.systemBottomInset(context);
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        border: Border(top: BorderSide(color: SDColors.neutral200)),
      ),
      padding: EdgeInsets.fromLTRB(4, 6, 4, 6 + sysBottom),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItem(
                selected: currentIndex == i,
                outline: _items[i].$1,
                filled: _items[i].$2,
                label: _items[i].$3,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.outline,
    required this.filled,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData outline;
  final IconData filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? SDColors.neutral900 : SDColors.neutral900.withOpacity(0.45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? filled : outline, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: SDTypography.labelSmall.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
                height: 1.15,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 16 : 0,
              decoration: BoxDecoration(
                color: SDColors.neutral900,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
