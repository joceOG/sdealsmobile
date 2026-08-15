import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/authCubit.dart';
import '../preferencespageblocm/preferencesPageBlocM.dart';
import '../preferencespageblocm/preferencesPageEventM.dart';
import '../preferencespageblocm/preferencesPageStateM.dart';
import '../../../../design_system/design_system.dart';

class PreferencesPageScreenM extends StatefulWidget {
  const PreferencesPageScreenM({super.key});

  @override
  State<PreferencesPageScreenM> createState() => _PreferencesPageScreenMState();
}

class _PreferencesPageScreenMState extends State<PreferencesPageScreenM>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPreferences() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion requise pour les préférences')),
      );
      return;
    }
    _currentUserId = auth.utilisateur.idutilisateur;
    context
        .read<PreferencesPageBlocM>()
        .add(LoadPreferencesM(utilisateurId: _currentUserId));
  }

  // 🔧 OPTIONS DE CONFIGURATION
  final List<Map<String, dynamic>> _languageOptions = [
    {'value': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
    {'value': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'value': 'es', 'label': 'Español', 'flag': '🇪🇸'},
    {'value': 'pt', 'label': 'Português', 'flag': '🇵🇹'},
    {'value': 'ar', 'label': 'العربية', 'flag': '🇸🇦'},
  ];

  final List<Map<String, dynamic>> _currencyOptions = [
    {'value': 'FCFA', 'label': 'Franc CFA', 'symbol': 'FCFA', 'flag': '🇨🇮'},
    {'value': 'EUR', 'label': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'value': 'USD', 'label': 'Dollar US', 'symbol': '\$', 'flag': '🇺🇸'},
    {'value': 'XOF', 'label': 'Franc CFA (XOF)', 'symbol': 'F', 'flag': '🇸🇳'},
    {'value': 'XAF', 'label': 'Franc CFA (XAF)', 'symbol': 'F', 'flag': '🇨🇲'},
  ];

  final List<Map<String, dynamic>> _countryOptions = [
    {'value': 'CI', 'label': 'Côte d\'Ivoire', 'flag': '🇨🇮'},
    {'value': 'FR', 'label': 'France', 'flag': '🇫🇷'},
    {'value': 'US', 'label': 'États-Unis', 'flag': '🇺🇸'},
    {'value': 'SN', 'label': 'Sénégal', 'flag': '🇸🇳'},
    {'value': 'ML', 'label': 'Mali', 'flag': '🇲🇱'},
    {'value': 'BF', 'label': 'Burkina Faso', 'flag': '🇧🇫'},
    {'value': 'NE', 'label': 'Niger', 'flag': '🇳🇪'},
    {'value': 'TG', 'label': 'Togo', 'flag': '🇹🇬'},
    {'value': 'BJ', 'label': 'Bénin', 'flag': '🇧🇯'},
    {'value': 'GH', 'label': 'Ghana', 'flag': '🇬🇭'},
    {'value': 'NG', 'label': 'Nigeria', 'flag': '🇳🇬'},
  ];

  final List<Map<String, dynamic>> _timezoneOptions = [
    {'value': 'Africa/Abidjan', 'label': 'Abidjan (GMT+0)'},
    {'value': 'Europe/Paris', 'label': 'Paris (GMT+1)'},
    {'value': 'America/New_York', 'label': 'New York (GMT-5)'},
    {'value': 'Africa/Dakar', 'label': 'Dakar (GMT+0)'},
    {'value': 'Africa/Bamako', 'label': 'Bamako (GMT+0)'},
  ];

  final List<Map<String, dynamic>> _dateFormatOptions = [
    {'value': 'DD/MM/YYYY', 'label': 'DD/MM/YYYY (31/12/2023)'},
    {'value': 'MM/DD/YYYY', 'label': 'MM/DD/YYYY (12/31/2023)'},
    {'value': 'YYYY-MM-DD', 'label': 'YYYY-MM-DD (2023-12-31)'},
  ];

  final List<Map<String, dynamic>> _timeFormatOptions = [
    {'value': '12h', 'label': '12 heures (AM/PM)'},
    {'value': '24h', 'label': '24 heures'},
  ];

  final List<Map<String, dynamic>> _monetaryFormatOptions = [
    {'value': '1,234.56', 'label': '1,234.56 (Anglais)'},
    {'value': '1 234,56', 'label': '1 234,56 (Français)'},
    {'value': '1.234,56', 'label': '1.234,56 (Allemand)'},
  ];

  final List<Map<String, dynamic>> _themeOptions = [
    {'value': 'light', 'label': 'Clair', 'icon': '☀️'},
    {'value': 'dark', 'label': 'Sombre', 'icon': '🌙'},
    {'value': 'auto', 'label': 'Automatique', 'icon': '🔄'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SDWhiteAppBar.appBar(
        title: 'Langue & Devise',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPreferences,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SDColors.primary700,
          unselectedLabelColor: SDColors.neutral500,
          indicatorColor: SDColors.primary600,
          indicatorWeight: 3,
          dividerColor: SDColors.neutral200,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Langue', icon: Icon(Icons.language_outlined)),
            Tab(text: 'Devise', icon: Icon(Icons.attach_money)),
            Tab(text: 'Localisation', icon: Icon(Icons.public_outlined)),
            Tab(text: 'Affichage', icon: Icon(Icons.palette_outlined)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications_outlined)),
            Tab(text: 'Sécurité', icon: Icon(Icons.security)),
          ],
        ),
      ),
      body: BlocListener<PreferencesPageBlocM, PreferencesPageStateM>(
        listener: (context, state) {
          if (state is PreferencesPageErrorM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.message}', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                backgroundColor: SDColors.error500,
              ),
            );
          } else if (state is LanguageUpdatedM ||
              state is CurrencyUpdatedM ||
              state is CountryUpdatedM ||
              state is ThemeUpdatedM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Préférences mises à jour avec succès', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                backgroundColor: SDColors.success500,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLanguageTab(),
            _buildCurrencyTab(),
            _buildLocationTab(),
            _buildDisplayTab(),
            _buildNotificationsTab(),
            _buildSecurityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageErrorM) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: SDColors.error500.withOpacity(0.5)),
                SizedBox(height: SDSpacing.md),
                Text('Erreur: ${state.message}', style: SDTypography.bodyMedium.copyWith(color: SDColors.error500)),
                SizedBox(height: SDSpacing.md),
                ElevatedButton(
                  onPressed: _loadPreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '🌍 Langue de l\'interface',
                  'Choisissez votre langue préférée',
                  DropdownButtonFormField<String>(
                    value: state.preferences.langue,
                    decoration: const InputDecoration(
                      labelText: 'Langue',
                      border: OutlineInputBorder(),
                    ),
                    items: _languageOptions.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang['value'],
                        child: Row(
                          children: [
                            Text(lang['flag'],
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(lang['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateLanguageM(
                                  utilisateurId: _currentUserId, langue: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  '🌍 Pays',
                  'Sélectionnez votre pays',
                  DropdownButtonFormField<String>(
                    value: state.preferences.pays,
                    decoration: const InputDecoration(
                      labelText: 'Pays',
                      border: OutlineInputBorder(),
                    ),
                    items: _countryOptions.map((country) {
                      return DropdownMenuItem<String>(
                        value: country['value'],
                        child: Row(
                          children: [
                            Text(country['flag'],
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(country['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateCountryM(
                                  utilisateurId: _currentUserId, pays: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  '🕐 Fuseau horaire',
                  'Définissez votre fuseau horaire',
                  DropdownButtonFormField<String>(
                    value: state.preferences.fuseauHoraire,
                    decoration: const InputDecoration(
                      labelText: 'Fuseau horaire',
                      border: OutlineInputBorder(),
                    ),
                    items: _timezoneOptions.map((tz) {
                      return DropdownMenuItem<String>(
                        value: tz['value'],
                        child: Text(tz['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateTimezoneM(
                                  utilisateurId: _currentUserId,
                                  fuseauHoraire: value),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildCurrencyTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '💰 Devise par défaut',
                  'Choisissez votre devise préférée',
                  DropdownButtonFormField<String>(
                    value: state.preferences.devise,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencyOptions.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency['value'],
                        child: Row(
                          children: [
                            Text(currency['flag'],
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                                '${currency['label']} (${currency['symbol']})'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateCurrencyM(
                                  utilisateurId: _currentUserId, devise: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  '💰 Format monétaire',
                  'Choisissez le format d\'affichage des prix',
                  DropdownButtonFormField<String>(
                    value: state.preferences.formatMonetaire,
                    decoration: const InputDecoration(
                      labelText: 'Format monétaire',
                      border: OutlineInputBorder(),
                    ),
                    items: _monetaryFormatOptions.map((format) {
                      return DropdownMenuItem<String>(
                        value: format['value'],
                        child: Text(format['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateMonetaryFormatM(
                                  utilisateurId: _currentUserId,
                                  formatMonetaire: value),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildLocationTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '📍 Localisation',
                  'Configurez votre localisation',
                  Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateLocationM(
                                  utilisateurId: _currentUserId,
                                  ville: value,
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Code postal',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateLocationM(
                                  utilisateurId: _currentUserId,
                                  codePostal: value,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDisplayTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '🎨 Thème',
                  'Choisissez votre thème préféré',
                  DropdownButtonFormField<String>(
                    value: state.preferences.theme,
                    decoration: const InputDecoration(
                      labelText: 'Thème',
                      border: OutlineInputBorder(),
                    ),
                    items: _themeOptions.map((theme) {
                      return DropdownMenuItem<String>(
                        value: theme['value'],
                        child: Row(
                          children: [
                            Text(theme['icon'],
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(theme['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateThemeM(
                                  utilisateurId: _currentUserId, theme: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  '📅 Format de date',
                  'Choisissez le format d\'affichage des dates',
                  DropdownButtonFormField<String>(
                    value: state.preferences.formatDate,
                    decoration: const InputDecoration(
                      labelText: 'Format de date',
                      border: OutlineInputBorder(),
                    ),
                    items: _dateFormatOptions.map((format) {
                      return DropdownMenuItem<String>(
                        value: format['value'],
                        child: Text(format['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateDateFormatM(
                                  utilisateurId: _currentUserId,
                                  formatDate: value),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  '🕐 Format d\'heure',
                  'Choisissez le format d\'affichage des heures',
                  DropdownButtonFormField<String>(
                    value: state.preferences.formatHeure,
                    decoration: const InputDecoration(
                      labelText: 'Format d\'heure',
                      border: OutlineInputBorder(),
                    ),
                    items: _timeFormatOptions.map((format) {
                      return DropdownMenuItem<String>(
                        value: format['value'],
                        child: Text(format['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PreferencesPageBlocM>().add(
                              UpdateTimeFormatM(
                                  utilisateurId: _currentUserId,
                                  formatHeure: value),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildNotificationsTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '🔔 Notifications',
                  'Configurez vos préférences de notification',
                  Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notifications par email'),
                        subtitle:
                            const Text('Recevoir les notifications par email'),
                        value: state.preferences.notifications.email,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateNotificationsM(
                                  utilisateurId: _currentUserId,
                                  email: value,
                                  push: state.preferences.notifications.push,
                                  sms: state.preferences.notifications.sms,
                                  langue:
                                      state.preferences.notifications.langue,
                                ),
                              );
                        },
                        activeColor: SDColors.primary600,
                      ),
                      SwitchListTile(
                        title: const Text('Notifications push'),
                        subtitle: const Text('Recevoir les notifications push'),
                        value: state.preferences.notifications.push,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateNotificationsM(
                                  utilisateurId: _currentUserId,
                                  email: state.preferences.notifications.email,
                                  push: value,
                                  sms: state.preferences.notifications.sms,
                                  langue:
                                      state.preferences.notifications.langue,
                                ),
                              );
                        },
                        activeColor: SDColors.primary600,
                      ),
                      SwitchListTile(
                        title: const Text('Notifications SMS'),
                        subtitle:
                            const Text('Recevoir les notifications par SMS'),
                        value: state.preferences.notifications.sms,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateNotificationsM(
                                  utilisateurId: _currentUserId,
                                  email: state.preferences.notifications.email,
                                  push: state.preferences.notifications.push,
                                  sms: value,
                                  langue:
                                      state.preferences.notifications.langue,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSecurityTab() {
    return BlocBuilder<PreferencesPageBlocM, PreferencesPageStateM>(
      builder: (context, state) {
        if (state is PreferencesPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PreferencesPageLoadedM) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  '🔒 Sécurité',
                  'Configurez vos préférences de sécurité',
                  Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Authentification à deux facteurs'),
                        subtitle: const Text(
                            'Activer l\'authentification à deux facteurs'),
                        value: state
                            .preferences.securite.authentificationDoubleFacteur,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateSecurityPreferencesM(
                                  utilisateurId: _currentUserId,
                                  authentificationDoubleFacteur: value,
                                  notificationsConnexion: state.preferences
                                      .securite.notificationsConnexion,
                                  partageDonnees:
                                      state.preferences.securite.partageDonnees,
                                ),
                              );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Notifications de connexion'),
                        subtitle: const Text(
                            'Recevoir des notifications de connexion'),
                        value:
                            state.preferences.securite.notificationsConnexion,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateSecurityPreferencesM(
                                  utilisateurId: _currentUserId,
                                  authentificationDoubleFacteur: state
                                      .preferences
                                      .securite
                                      .authentificationDoubleFacteur,
                                  notificationsConnexion: value,
                                  partageDonnees:
                                      state.preferences.securite.partageDonnees,
                                ),
                              );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Partage de données'),
                        subtitle: const Text(
                            'Autoriser le partage de données anonymisées'),
                        value: state.preferences.securite.partageDonnees,
                        onChanged: (value) {
                          context.read<PreferencesPageBlocM>().add(
                                UpdateSecurityPreferencesM(
                                  utilisateurId: _currentUserId,
                                  authentificationDoubleFacteur: state
                                      .preferences
                                      .securite
                                      .authentificationDoubleFacteur,
                                  notificationsConnexion: state.preferences
                                      .securite.notificationsConnexion,
                                  partageDonnees: value,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSectionCard(String title, String subtitle, Widget content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: SDSpacing.xs),
            Text(
              subtitle,
              style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
            ),
            SizedBox(height: SDSpacing.md),
            content,
          ],
        ),
      ),
    );
  }
}
