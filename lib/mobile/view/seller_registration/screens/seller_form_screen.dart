import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/registration_wizard_chrome.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_creation_status_presentation.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_registration_success_view.dart';

/// Inscription vendeur : la boutique reste portée par le profil Vendeur.
/// Contrat : POST /vendeur. Pas de formulaire Article ni de compte de paiement.
class SellerFormScreen extends StatefulWidget {
  const SellerFormScreen({
    super.key,
    this.preSelectedCategories,
    this.preSelectedProducts,
  });

  final Set<String>? preSelectedCategories;
  final Set<String>? preSelectedProducts;

  @override
  State<SellerFormScreen> createState() => _SellerFormScreenState();
}

class _SellerFormScreenState extends State<SellerFormScreen> {
  static const _labels = ['Boutique', 'Activité', 'Modalités', 'Récap'];
  static const _types = ['Particulier', 'Entreprise', 'Auto-entrepreneur'];
  static const _categories = [
    'Mode',
    'Électronique',
    'Beauté',
    'Maison',
    'Informatique',
    'Alimentation',
    'Artisanat',
  ];
  static const _shipping = ['Standard', 'Express', 'Same-Day', 'Pickup'];
  static const _payments = ['Mobile Money', 'Carte Bancaire', 'Virement', 'Espèces'];

  int _step = 0;
  bool _submitting = false;
  bool _created = false;
  bool _refreshing = false;
  bool _refreshFailed = false;
  ProfessionalProfileSnapshot? _snapshot;

  final _shopName = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _zoneInput = TextEditingController();

  String _businessType = 'Particulier';
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedShipping = {'Standard'};
  final Set<String> _selectedPayments = {'Mobile Money'};
  final List<String> _zones = [];
  String? _logoPath;
  String? _cni1;
  String? _license;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      _phone.text = auth.utilisateur.telephone;
      _email.text = auth.utilisateur.email ?? '';
    }
    final preset = widget.preSelectedCategories;
    if (preset != null) {
      for (final name in preset) {
        if (_categories.contains(name)) _selectedCategories.add(name);
      }
    }
  }

  @override
  void dispose() {
    _shopName.dispose();
    _description.dispose();
    _phone.dispose();
    _email.dispose();
    _street.dispose();
    _city.dispose();
    _zoneInput.dispose();
    super.dispose();
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_shopName.text.trim().length < 3) {
          _err('Le nom de la boutique doit contenir au moins 3 caractères');
          return false;
        }
        if (_description.text.trim().length < 50) {
          _err('La description doit contenir au moins 50 caractères');
          return false;
        }
        if (_selectedCategories.isEmpty) {
          _err('Choisissez au moins une catégorie');
          return false;
        }
        return true;
      case 1:
        if (_city.text.trim().isEmpty) {
          _err('Indiquez la ville de la boutique');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _err(String message) => AppSnackBar.error(context, message);

  void _next() {
    if (_created || _submitting) return;
    if (!_validateStep()) return;
    if (_step < _labels.length - 1) {
      setState(() => _step++);
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    if (_created || _submitting) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      _err('Connectez-vous pour créer votre boutique');
      return;
    }
    setState(() => _submitting = true);
    try {
      final response = await ApiClient().sendAuthorizedMultipart(
        (access) async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiClient().apiUrl}/vendeur'),
          );
          if (access != null && access.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $access';
          }
          void field(String k, String v) => request.fields[k] = v;
          field('utilisateur', auth.utilisateur.idutilisateur);
          field('shopName', _shopName.text.trim());
          field('shopDescription', _description.text.trim());
          field('businessType', _businessType);
          field('businessCategories', jsonEncode(_selectedCategories.toList()));
          field('businessPhone', _phone.text.trim());
          field('businessEmail', _email.text.trim());
          field(
            'businessAddress',
            jsonEncode({
              'street': _street.text.trim(),
              'city': _city.text.trim(),
              'country': "Côte d'Ivoire",
            }),
          );
          field('deliveryZones', jsonEncode(_zones.isEmpty ? [_city.text.trim()] : _zones));
          field('shippingMethods', jsonEncode(_selectedShipping.toList()));
          field('paymentMethods', jsonEncode(_selectedPayments.toList()));
          field('source', 'sdealsmobile');
          await _attach(request, 'shopLogo', _logoPath);
          await _attach(request, 'cni1', _cni1);
          if (_businessType != 'Particulier') {
            await _attach(request, 'businessLicense', _license);
          }
          return request;
        },
        token: auth.token,
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _created = true;
          _submitting = false;
        });
        await _refresh();
        return;
      }
      setState(() => _submitting = false);
      _err(_message(response));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _err('Création non confirmée. Vérifiez la connexion puis réessayez.');
    }
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {}
    if (response.statusCode == 409) {
      return 'Une boutique existe déjà pour ce compte.';
    }
    return 'La création de la boutique a échoué.';
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      await context.read<AuthCubit>().refreshRoles();
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      setState(() {
        _refreshing = false;
        _snapshot = auth is AuthAuthenticated ? auth.professional?.vendeur : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshFailed = true;
      });
    }
  }

  void _leave() {
    context.go('/homepage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClientShellProfileTab.show();
    });
  }

  Future<void> _pick(void Function(String) setPath) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => setPath(file.path));
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: ProviderRegistrationSuccessView(
          statusPresentation: ProviderCreationStatusPresentation.resolve(
            snapshot: _snapshot,
            rolesRefreshFailed: _refreshFailed,
          ),
          pageTitle: 'Boutique',
          headline: 'Votre profil a été créé',
          subhead: 'Vos informations ont bien été enregistrées.',
          activityTitle: 'Votre boutique',
          primaryLabel: 'Nom',
          secondaryLabel: 'Catégories',
          serviceName: _shopName.text.trim().isEmpty ? '—' : _shopName.text.trim(),
          zonesLabel: _selectedCategories.isEmpty ? '—' : _selectedCategories.join(', '),
          refreshingStatus: _refreshing,
          onBackToProfile: _leave,
        ),
      );
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Créer ma boutique',
        titleStyle: SDTypography.titleLarge,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: RegistrationStepProgress(currentStep: _step, labels: _labels),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: _body(),
            ),
          ),
          RegistrationWizardFooter(
            primaryLabel: _step == _labels.length - 1 ? 'Créer ma boutique' : 'Continuer',
            loading: _submitting,
            onPrimary: _next,
            onBack: _step == 0 ? null : () => setState(() => _step--),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _shop();
      case 1:
        return _activity();
      case 2:
        return _terms();
      default:
        return _recap();
    }
  }

  Widget _shop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Votre boutique'),
        Center(
          child: InkWell(
            onTap: () => _pick((p) => _logoPath = p),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: SDColors.neutral100,
              backgroundImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
              child: _logoPath == null
                  ? const Icon(Icons.storefront_outlined, color: SDColors.neutral400)
                  : null,
            ),
          ),
        ),
        Center(
          child: Text(
            'Logo public (facultatif)',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
        const SizedBox(height: 12),
        SDInput(label: 'Nom de la boutique *', controller: _shopName),
        const SizedBox(height: 12),
        Text('Type de commerce', style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _types.map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _businessType == t,
              onSelected: (_) => setState(() => _businessType = t),
              selectedColor: SDColors.primary50,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text('Catégories *', style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final on = _selectedCategories.contains(c);
            return FilterChip(
              label: Text(c),
              selected: on,
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedCategories.add(c);
                } else {
                  _selectedCategories.remove(c);
                }
              }),
              selectedColor: SDColors.primary50,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Description *',
          controller: _description,
          maxLines: 4,
          maxLength: 1000,
        ),
      ],
    );
  }

  Widget _activity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Coordonnées et activité'),
        SDInput(label: 'Téléphone professionnel', controller: _phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        SDInput(label: 'E-mail professionnel', controller: _email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        SDInput(label: 'Adresse', controller: _street),
        const SizedBox(height: 12),
        SDInput(label: 'Ville *', controller: _city),
        const SizedBox(height: 16),
        Text(
          'Le propriétaire est le compte connecté.',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
        ),
      ],
    );
  }

  Widget _terms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Modalités'),
        Text(
          'Moyens acceptés par la boutique. Cela ne connecte pas un prestataire de paiement.',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600, height: 1.35),
        ),
        const SizedBox(height: 12),
        _checks('Livraison', _shipping, _selectedShipping),
        const SizedBox(height: 12),
        _checks('Paiements acceptés', _payments, _selectedPayments),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SDInput(label: 'Zone', controller: _zoneInput)),
            IconButton(
              onPressed: () {
                final z = _zoneInput.text.trim();
                if (z.isEmpty) return;
                setState(() {
                  if (!_zones.contains(z)) _zones.add(z);
                  _zoneInput.clear();
                });
              },
              icon: const Icon(Icons.add, color: SDColors.primary700),
            ),
          ],
        ),
        Text(_zones.isEmpty ? 'Aucune zone ajoutée' : _zones.join(', ')),
        const SizedBox(height: 16),
        _title('Documents privés'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pièce d’identité'),
          subtitle: Text(_cni1 == null ? 'Facultatif' : 'Fichier sélectionné'),
          onTap: () => _pick((p) => _cni1 = p),
        ),
        if (_businessType != 'Particulier')
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Justificatif d’activité'),
            subtitle: Text(_license == null ? 'Facultatif' : 'Fichier sélectionné'),
            onTap: () => _pick((p) => _license = p),
          ),
      ],
    );
  }

  Widget _recap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Récapitulatif'),
        _line('Boutique', _shopName.text, 0),
        _line('Type', _businessType, 0),
        _line('Catégories', _selectedCategories.join(', '), 0),
        _line('Ville', _city.text, 1),
        _line('Livraison', _selectedShipping.join(', '), 2),
        _line('Paiements', _selectedPayments.join(', '), 2),
      ],
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _checks(String label, List<String> values, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            return FilterChip(
              label: Text(v),
              selected: selected.contains(v),
              selectedColor: SDColors.primary50,
              onSelected: (on) => setState(() {
                if (on) {
                  selected.add(v);
                } else if (selected.length > 1) {
                  selected.remove(v);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _line(String label, String value, int step) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500)),
      subtitle: Text(value.isEmpty ? '—' : value, style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      trailing: TextButton(onPressed: () => setState(() => _step = step), child: const Text('Modifier')),
    );
  }
}

Future<void> _attach(http.MultipartRequest request, String field, String? path) async {
  if (path == null || path.isEmpty) return;
  final file = File(path);
  if (!await file.exists()) return;
  request.files.add(await http.MultipartFile.fromPath(field, path));
}
