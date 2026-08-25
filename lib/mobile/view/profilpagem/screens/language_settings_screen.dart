import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../../preferencespagem/preferencespageblocm/preferencesPageBlocM.dart';
import '../../preferencespagem/preferencespageblocm/preferencesPageEventM.dart';
import '../../preferencespagem/preferencespageblocm/preferencesPageStateM.dart';

/// Langue & Devise — style Figma, sans inventer « langues de contenu » ni appareils.
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const double _hPad = 20;

  static const _languages = [
    ('fr', 'Français'),
    ('en', 'English'),
  ];

  static const _currencies = [
    ('FCFA', 'Franc CFA (FCFA)'),
    ('XOF', 'Franc CFA (XOF)'),
    ('EUR', 'Euro (€)'),
    ('USD', 'Dollar US (\$)'),
  ];

  String? _userId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      _userId = auth.utilisateur.idutilisateur;
    }
    if (_userId != null && _userId!.isNotEmpty) {
      context
          .read<PreferencesPageBlocM>()
          .add(LoadPreferencesM(utilisateurId: _userId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 8),
              child: Text(
                'Langue & Devise',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 16),
              child: Text(
                'Choisissez la langue et la devise affichées dans l’app.',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<PreferencesPageBlocM, PreferencesPageStateM>(
                listener: (context, state) {
                  // Erreurs → affichées inline uniquement (pas de SnackBar).
                  // Succès seulement.
                  if (state is LanguageUpdatedM || state is CurrencyUpdatedM) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Préférences mises à jour'),
                        backgroundColor: SDColors.success500,
                      ),
                    );
                  }
                },
                buildWhen: (prev, next) =>
                    next is PreferencesPageLoadingM ||
                    next is PreferencesPageLoadedM ||
                    next is PreferencesPageErrorM ||
                    next is PreferencesPageInitialM,
                builder: (context, state) {
                  if (_userId == null || _userId!.isEmpty) {
                    return _centeredMessage(
                      'Connectez-vous pour enregistrer vos préférences.',
                    );
                  }
                  if (state is PreferencesPageLoadingM ||
                      state is PreferencesPageInitialM) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary600,
                      ),
                    );
                  }
                  if (state is PreferencesPageErrorM) {
                    // Masquer les messages techniques bruts — toujours message humain.
                    return _centeredMessage(
                      'Impossible de charger ces paramètres.',
                      retry: () => context.read<PreferencesPageBlocM>().add(
                            LoadPreferencesM(utilisateurId: _userId!),
                          ),
                    );
                  }
                  if (state is! PreferencesPageLoadedM) {
                    return const SizedBox.shrink();
                  }

                  final prefs = state.preferences;
                  final lang = prefs.langue == 'en' ? 'en' : 'fr';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 32),
                    children: [
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              icon: Icons.language_outlined,
                              title: 'Langue de l’application',
                            ),
                            const SizedBox(height: 8),
                            ..._languages.map((opt) {
                              final selected = lang == opt.$1;
                              return _radioRow(
                                label: opt.$2,
                                selected: selected,
                                onTap: () {
                                  if (!selected) {
                                    context.read<PreferencesPageBlocM>().add(
                                          UpdateLanguageM(
                                            utilisateurId: _userId!,
                                            langue: opt.$1,
                                          ),
                                        );
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              icon: Icons.payments_outlined,
                              title: 'Devise',
                            ),
                            const SizedBox(height: 8),
                            ..._currencies.map((opt) {
                              final selected = prefs.devise == opt.$1;
                              return _radioRow(
                                label: opt.$2,
                                selected: selected,
                                onTap: () {
                                  if (!selected) {
                                    context.read<PreferencesPageBlocM>().add(
                                          UpdateCurrencyM(
                                            utilisateurId: _userId!,
                                            devise: opt.$1,
                                          ),
                                        );
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'La langue de l’interface sera appliquée progressivement. '
                        'Les appareils connectés se gèrent dans Sécurité.',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centeredMessage(String message, {VoidCallback? retry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_hPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            if (retry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: retry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: child,
    );
  }

  Widget _cardHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: SDColors.primary600, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SDTypography.bodyLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? SDColors.primary600 : SDColors.neutral400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
