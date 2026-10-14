import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/security.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../../profilpagem/screens/edit_profile_screen.dart';
import '../../profilpagem/screens/help_support_screen.dart';
import '../../profilpagem/screens/profile_menu_item.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';
import 'securitySettingsScreenM.dart';
import 'twoFactorSetupScreenM.dart';

/// Sécurité du compte — parcours existants (mot de passe, sessions, téléphone, aide).
class SecurityPageScreenM extends StatefulWidget {
  const SecurityPageScreenM({super.key});

  @override
  State<SecurityPageScreenM> createState() => _SecurityPageScreenMState();
}

class _SecurityPageScreenMState extends State<SecurityPageScreenM> {
  static const double _hPad = 20;
  static const EdgeInsets _itemPad =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final showPhone = auth is AuthAuthenticated;
    final verified = showPhone && auth.utilisateur.telephoneVerified;

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: SDColors.primary700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gardez le contrôle de vos accès',
                                style: SDTypography.bodyLarge.copyWith(
                                  color: SDColors.neutral900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Retrouvez les réglages de sécurité de votre compte.',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _sectionLabel('Connexion'),
                  _group([
                    MenuItem(
                      icon: Icons.vpn_key_outlined,
                      leading: _iconWell(Icons.vpn_key_outlined),
                      title: 'Mot de passe',
                      subtitle: 'Modifier mon mot de passe',
                      padding: _itemPad,
                      onTap: () =>
                          _openWithBloc(const SecuritySettingsScreenM()),
                    ),
                    MenuItem(
                      icon: Icons.devices_outlined,
                      leading: _iconWell(Icons.devices_outlined),
                      title: 'Sessions',
                      subtitle: 'Consulter les appareils connectés',
                      padding: _itemPad,
                      onTap: () => _openWithBloc(const _SessionsSubScreen()),
                    ),
                    MenuItem(
                      icon: Icons.security_outlined,
                      leading: _iconWell(Icons.security_outlined),
                      title: 'Authentification à deux facteurs',
                      subtitle: 'Renforcer la connexion',
                      padding: _itemPad,
                      onTap: () => _openWithBloc(const TwoFactorSetupScreenM()),
                    ),
                  ]),
                  if (showPhone) ...[
                    _sectionLabel('Vérification'),
                    _group([
                      MenuItem(
                        icon: Icons.smartphone_outlined,
                        leading: _iconWell(Icons.smartphone_outlined),
                        title: 'Numéro de téléphone',
                        subtitle: verified
                            ? 'Numéro vérifié'
                            : 'Consulter mon statut de vérification',
                        padding: _itemPad,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _PhoneStatusSubScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                  ],
                  _sectionLabel('Besoin d’aide ?'),
                  _group([
                    MenuItem(
                      icon: Icons.headset_mic_outlined,
                      leading: _iconWell(Icons.headset_mic_outlined),
                      title: 'Un problème d’accès ?',
                      subtitle:
                          'Contactez l’assistance pour obtenir de l’aide.',
                      padding: _itemPad,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SDColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: SDColors.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ne partagez jamais votre mot de passe ni vos codes de vérification.',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SOUTRALI DEALS',
                    textAlign: TextAlign.center,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral400,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            tooltip: 'Retour',
          ),
          Expanded(
            child: Text(
              'Sécurité du compte',
              style: SDTypography.titleLarge.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: SDTypography.titleSmall.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: SDColors.neutral200,
                indent: 68,
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  static Widget _iconWell(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: SDColors.primary700, size: 20),
    );
  }

  void _openWithBloc(Widget child) {
    final bloc = context.read<SecurityPageBlocM>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: child,
        ),
      ),
    );
  }
}

class _SessionsSubScreen extends StatefulWidget {
  const _SessionsSubScreen();

  @override
  State<_SessionsSubScreen> createState() => _SessionsSubScreenState();
}

class _SessionsSubScreenState extends State<_SessionsSubScreen> {
  static const double _hPad = 20;

  @override
  void initState() {
    super.initState();
    context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocConsumer<SecurityPageBlocM, SecurityPageStateM>(
          listener: (context, state) {
            if (state is SecurityPageErrorStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.error500,
                ),
              );
            } else if (state is SessionTerminatedStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.success500,
                ),
              );
              context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
            }
          },
          builder: (context, state) {
            final loaded = state is SecurityPageLoadedStateM ? state : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: SDColors.neutral900,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Sessions',
                          style: SDTypography.titleLarge.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state is SecurityPageLoadingStateM && loaded == null)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary600,
                      ),
                    ),
                  )
                else if (loaded == null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(_hPad),
                        child: Text(
                          'Impossible de charger les sessions.',
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
                      children: [
                        Text(
                          'Appareils connectés',
                          style: SDTypography.titleSmall.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (loaded.sessions.isEmpty)
                          Text(
                            'Aucune session active',
                            style: SDTypography.bodyMedium.copyWith(
                              color: SDColors.neutral500,
                            ),
                          )
                        else
                          ..._buildSessionCards(loaded.sessions),
                        if (loaded.sessions.length > 1) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              final sorted = [...loaded.sessions]..sort((a, b) {
                                  final aT = a.lastActivity ?? a.createdAt;
                                  final bT = b.lastActivity ?? b.createdAt;
                                  return bT.compareTo(aT);
                                });
                              final currentId =
                                  sorted.isNotEmpty ? sorted.first.id : null;
                              context.read<SecurityPageBlocM>().add(
                                    TerminateAllOtherSessionsEventM(
                                      keepSessionId: currentId,
                                    ),
                                  );
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Déconnecter les autres appareils',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SDColors.error500,
                              side: BorderSide(
                                color: SDColors.error500.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<SecurityPageBlocM>(),
                                  child: const _HistorySubScreen(),
                                ),
                              ),
                            );
                          },
                          child: const Text('Historique des connexions'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSessionCards(List<SecuritySession> sessions) {
    final sorted = [...sessions]..sort((a, b) {
        final aT = a.lastActivity ?? a.createdAt;
        final bT = b.lastActivity ?? b.createdAt;
        return bT.compareTo(aT);
      });
    final currentId = sorted.isNotEmpty ? sorted.first.id : null;

    return [
      for (final session in sorted)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _sessionCard(
            session: session,
            isCurrent: session.id != null && session.id == currentId,
          ),
        ),
    ];
  }

  Widget _sessionCard({
    required SecuritySession session,
    required bool isCurrent,
  }) {
    final when = _formatActivity(session.lastActivity ?? session.createdAt);
    final loc = session.location.trim().isEmpty
        ? 'Localisation inconnue'
        : session.location;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _deviceIcon(session.deviceType),
            color: SDColors.neutral700,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: session.isActive
                            ? SDColors.primary600
                            : SDColors.neutral400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        session.deviceName,
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SDColors.primary600.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Appareil actuel',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$loc · $when',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent && session.id != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: SDColors.neutral500),
              onSelected: (value) {
                if (value == 'disconnect') {
                  context.read<SecurityPageBlocM>().add(
                        TerminateSessionEventM(sessionId: session.id!),
                      );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'disconnect',
                  child: Text(
                    'Déconnecter',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.error500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static IconData _deviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'phone':
      case 'android':
      case 'ios':
        return Icons.smartphone_outlined;
      case 'tablet':
        return Icons.tablet_outlined;
      case 'desktop':
      case 'web':
      case 'laptop':
        return Icons.laptop_outlined;
      default:
        return Icons.devices_outlined;
    }
  }

  static String _formatActivity(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 5) return 'Maintenant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hier à $h:$m';
    }
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _PhoneStatusSubScreen extends StatelessWidget {
  const _PhoneStatusSubScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.utilisateur : null;
    final verified = user?.telephoneVerified == true;
    final phone = user?.telephone.trim() ?? '';

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: SDColors.neutral900),
                  ),
                  Expanded(
                    child: Text(
                      'Numéro de téléphone',
                      style: SDTypography.titleLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phone.isEmpty ? 'Aucun numéro enregistré' : phone,
                    style: SDTypography.titleMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verified ? 'Numéro vérifié' : 'Numéro non vérifié',
                    style: SDTypography.bodyMedium.copyWith(
                      color:
                          verified ? SDColors.primary700 : SDColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Le statut provient de votre compte. Pour modifier le numéro, ouvrez vos informations personnelles.',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SDButton(
                    text: 'Informations personnelles',
                    fullWidth: true,
                    type: SDButtonType.outlined,
                    onPressed: user == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  initialUserData: {
                                    'nom': user.nom,
                                    'prenom': user.prenom ?? '',
                                    'telephone': user.telephone,
                                    'email': user.email ?? '',
                                    'genre': user.genre ?? '',
                                    'datedenaissance': user.dateNaissance ?? '',
                                    'photoProfil': user.photoProfil,
                                  },
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySubScreen extends StatefulWidget {
  const _HistorySubScreen();

  @override
  State<_HistorySubScreen> createState() => _HistorySubScreenState();
}

class _HistorySubScreenState extends State<_HistorySubScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SecurityPageBlocM>().add(LoadLoginHistoryEventM());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
        }
      },
      child: Scaffold(
        backgroundColor: SDColors.neutral50,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Historique des connexions',
                        style: SDTypography.displaySmall.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Effacer l\'historique ?'),
                            content: const Text(
                              'Tous les enregistrements d\'historique de connexion seront supprimés.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  context
                                      .read<SecurityPageBlocM>()
                                      .add(ClearLoginHistoryEventM());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SDColors.error500,
                                ),
                                child: const Text(
                                  'Effacer',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Effacer',
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.error500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<SecurityPageBlocM, SecurityPageStateM>(
                  builder: (context, state) {
                    if (state is LoginHistoryClearedStateM) {
                      return Center(
                        child: Text(
                          'Aucun historique',
                          style: SDTypography.bodyMedium
                              .copyWith(color: SDColors.neutral500),
                        ),
                      );
                    }
                    if (state is! LoginHistoryLoadedStateM) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: SDColors.primary600,
                        ),
                      );
                    }
                    final history = state.loginHistory;
                    if (history.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun historique',
                          style: SDTypography.bodyMedium
                              .copyWith(color: SDColors.neutral500),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final when = _SessionsSubScreenState._formatActivity(
                          item.lastActivity ?? item.createdAt,
                        );
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SDColors.neutral200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _SessionsSubScreenState._deviceIcon(
                                  item.deviceType,
                                ),
                                color: SDColors.neutral700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.deviceName,
                                      style: SDTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: SDColors.neutral900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.location.isEmpty ? '—' : item.location} · $when',
                                      style: SDTypography.bodySmall.copyWith(
                                        color: SDColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
