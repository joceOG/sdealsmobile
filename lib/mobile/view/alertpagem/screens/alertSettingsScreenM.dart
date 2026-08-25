import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';
import '../../../../design_system/design_system.dart';

/// Préférences de notification — redesign DS STAB-13.
///
/// Sections : Canaux · Types d'alertes · Priorités.
/// Chaque ligne = icône + label + description courte + contrôle aligné à droite.
/// Titre complet, jamais tronqué. Sauvegarde automatique désactivée → bouton en AppBar.
class AlertSettingsScreenM extends StatefulWidget {
  const AlertSettingsScreenM({super.key});

  @override
  State<AlertSettingsScreenM> createState() => _AlertSettingsScreenMState();
}

class _AlertSettingsScreenMState extends State<AlertSettingsScreenM> {
  bool _emailEnabled = true;
  bool _pushEnabled = true;
  bool _smsEnabled = false;
  List<String> _typesEnabled = [];
  List<String> _prioritesEnabled = [];

  final _allTypes = const [
    _TypeItem('COMMANDE', 'Commandes', 'Suivi de vos commandes et livraisons',
        Icons.shopping_bag_outlined),
    _TypeItem('PRESTATION', 'Prestations', 'Demandes et statuts de prestation',
        Icons.handyman_outlined),
    _TypeItem('PAIEMENT', 'Paiements', 'Confirmations et rappels de paiement',
        Icons.payments_outlined),
    _TypeItem('VERIFICATION', 'Vérifications',
        'Codes OTP et confirmations de sécurité', Icons.verified_outlined),
    _TypeItem('MESSAGE', 'Messages', 'Nouveaux messages de prestataires',
        Icons.chat_bubble_outline),
    _TypeItem('PROMOTION', 'Promotions', 'Offres et réductions disponibles',
        Icons.local_offer_outlined),
    _TypeItem('RAPPEL', 'Rappels', 'Rappels de rendez-vous et d\'échéances',
        Icons.alarm_outlined),
    _TypeItem('SYSTEME', 'Système', 'Mises à jour et informations techniques',
        Icons.settings_outlined),
  ];

  final _allPriorites = const [
    _PrioriteItem('BASSE', 'Basse', 'Informations non urgentes',
        Icons.arrow_downward_rounded, SDColors.neutral500),
    _PrioriteItem('NORMALE', 'Normale', 'Alertes courantes',
        Icons.remove_rounded, SDColors.info600),
    _PrioriteItem('HAUTE', 'Haute', 'Alertes importantes à traiter rapidement',
        Icons.arrow_upward_rounded, SDColors.warning600),
    _PrioriteItem('CRITIQUE', 'Critique', 'Alertes urgentes nécessitant action',
        Icons.priority_high_rounded, SDColors.error600),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AlertPageBlocM>().add(const LoadAlertPreferencesM());
  }

  void _save() {
    context.read<AlertPageBlocM>().add(UpdateAlertPreferencesM(
          emailEnabled: _emailEnabled,
          pushEnabled: _pushEnabled,
          smsEnabled: _smsEnabled,
          typesEnabled: _typesEnabled,
          prioritesEnabled: _prioritesEnabled,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      appBar: SDWhiteAppBar.appBar(
        title: 'Préférences de notification',
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Enregistrer',
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.primary600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<AlertPageBlocM, AlertPageStateM>(
        listener: (context, state) {
          if (state is AlertPreferencesLoadedM) {
            setState(() {
              _emailEnabled = state.emailEnabled;
              _pushEnabled = state.pushEnabled;
              _smsEnabled = state.smsEnabled;
              _typesEnabled = List.from(state.typesEnabled);
              _prioritesEnabled = List.from(state.prioritesEnabled);
            });
          } else if (state is AlertPreferencesUpdatedM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Préférences enregistrées'),
                backgroundColor: SDColors.success600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AlertPageErrorM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Impossible d\'enregistrer les préférences. Réessayez.'),
                backgroundColor: SDColors.error600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Canaux ──────────────────────────────────────────────────
              _sectionTitle('Canaux'),
              const SizedBox(height: 8),
              _dsCard(
                children: [
                  _switchRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    description: 'Alertes envoyées à votre adresse email',
                    value: _emailEnabled,
                    onChanged: (v) => setState(() => _emailEnabled = v),
                  ),
                  _divider(),
                  _switchRow(
                    icon: Icons.phone_android_outlined,
                    label: 'Notifications push',
                    description: 'Alertes sur votre appareil en temps réel',
                    value: _pushEnabled,
                    onChanged: (v) => setState(() => _pushEnabled = v),
                  ),
                  _divider(),
                  _switchRow(
                    icon: Icons.sms_outlined,
                    label: 'SMS',
                    description: 'Alertes par message texte',
                    value: _smsEnabled,
                    onChanged: (v) => setState(() => _smsEnabled = v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Types d'alertes ─────────────────────────────────────────
              _sectionTitle('Types d\'alertes'),
              const SizedBox(height: 4),
              Text(
                'Choisissez les catégories que vous souhaitez recevoir.',
                style:
                    SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 8),
              _dsCard(
                children: List.generate(_allTypes.length, (i) {
                  final t = _allTypes[i];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _checkRow(
                        icon: t.icon,
                        iconColor: SDColors.primary600,
                        label: t.label,
                        description: t.description,
                        checked: _typesEnabled.contains(t.key),
                        onChanged: (v) => setState(() {
                          if (v) {
                            _typesEnabled.add(t.key);
                          } else {
                            _typesEnabled.remove(t.key);
                          }
                        }),
                      ),
                      if (i < _allTypes.length - 1) _divider(),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 24),

              // ── Priorités ───────────────────────────────────────────────
              _sectionTitle('Priorités'),
              const SizedBox(height: 4),
              Text(
                'Filtrez les alertes selon leur niveau d\'importance.',
                style:
                    SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 8),
              _dsCard(
                children: List.generate(_allPriorites.length, (i) {
                  final p = _allPriorites[i];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _checkRow(
                        icon: p.icon,
                        iconColor: p.color,
                        label: p.label,
                        description: p.description,
                        checked: _prioritesEnabled.contains(p.key),
                        onChanged: (v) => setState(() {
                          if (v) {
                            _prioritesEnabled.add(p.key);
                          } else {
                            _prioritesEnabled.remove(p.key);
                          }
                        }),
                      ),
                      if (i < _allPriorites.length - 1) _divider(),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Réinitialiser
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _emailEnabled = true;
                    _pushEnabled = true;
                    _smsEnabled = false;
                    _typesEnabled = _allTypes.map((t) => t.key).toList();
                    _prioritesEnabled =
                        _allPriorites.map((p) => p.key).toList();
                  }),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Réinitialiser les préférences'),
                  style: TextButton.styleFrom(
                    foregroundColor: SDColors.neutral600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers visuels ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: SDTypography.titleMedium.copyWith(
        color: SDColors.neutral900,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _dsCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 56,
        color: SDColors.neutral100,
      );

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SDColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: SDColors.neutral700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: SDTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  description,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: SDColors.primary600,
          ),
        ],
      ),
    );
  }

  Widget _checkRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
    required bool checked,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: SDTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    description,
                    style: SDTypography.bodySmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: SDColors.primary600,
              side: const BorderSide(color: SDColors.neutral400),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _TypeItem {
  const _TypeItem(this.key, this.label, this.description, this.icon);
  final String key;
  final String label;
  final String description;
  final IconData icon;
}

class _PrioriteItem {
  const _PrioriteItem(
      this.key, this.label, this.description, this.icon, this.color);
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}
