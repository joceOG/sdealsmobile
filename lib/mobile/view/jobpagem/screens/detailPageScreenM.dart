import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/ai_provider_matcher_widget.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/service_request_summary_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/mini_map_widget.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

// Page de détails de service (2025) avec header moderne, prestataires réels, et CTA sticky
class DetailPage extends StatefulWidget {
  final String title;
  final String image;

  const DetailPage({
    required this.title,
    required this.image,
    super.key,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  List<Map<String, dynamic>> _providers = [];
  bool _filterVerifiedOnly = false;
  bool _isFavorited = false;
  LatLng? _userLocation;
  String? _serviceId;
  String? _selectedProviderId;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Position par défaut (Abidjan) si géolocalisation échoue
      setState(() {
        _userLocation = const LatLng(5.3599, -4.0083);
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loading = true;
    });
    try {
      final results = await _api.fetchPrestatairesByService(
        serviceName: widget.title,
        verified: _filterVerifiedOnly ? true : null,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _providers = results;
        // Récupérer l'ID du service depuis le premier prestataire
        if (_providers.isNotEmpty && _providers.first['service'] != null) {
          _serviceId = _providers.first['service']['_id']?.toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement prestataires: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SDWhiteAppBar.appBar(
        title: widget.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _onShareTap,
          ),
          IconButton(
            icon: Icon(
              _isFavorited
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            onPressed: _onFavoriteTap,
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _onReportTap,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceImage(widget.image),
                  SizedBox(height: SDSpacing.sm),
                  Text(
                    widget.title,
                    style: SDTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral900,
                    ),
                  ),
                  SizedBox(height: SDSpacing.sm),
                  _buildServiceDescription(),
                  SizedBox(height: SDSpacing.md),
                  SizedBox(height: SDSpacing.lg),

                  // Mini carte avec emplacement du prestataire
                  if (_providers.isNotEmpty && _userLocation != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 100,
                        maxHeight: 200,
                      ),
                      child: MiniMapWidget(
                        provider: _providers.first,
                        userLocation: _userLocation,
                      ),
                    ),

                  SizedBox(height: SDSpacing.md),
                  AIProviderMatcherWidget(
                    serviceType: widget.title,
                    location: "Abidjan",
                    preferences: const [],
                  ),
                  SizedBox(height: SDSpacing.md),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: SDSpacing.xs),
                child: Center(
                    child: CircularProgressIndicator(
                        color: SDColors.primary700)),
              ),
            )
          else if (_providers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xs),
                child: Text('Aucun prestataire trouvé pour ce service.',
                    style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                child: _buildProvidersStories(),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: SDSpacing.xxl)),
        ],
      ),
      bottomNavigationBar: _buildStickyCta(context),
    );
  }

  void _onShareTap() async {
    final text = 'Découvrez ${widget.title} sur Soutrali Deals';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Texte copié dans le presse-papiers',
          style: SDTypography.bodyMedium)),
    );
  }

  void _onFavoriteTap() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Connectez-vous pour ajouter en favoris.',
                style: SDTypography.bodyMedium)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
      );
      return;
    }

    setState(() => _isFavorited = !_isFavorited);
    final msg = _isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: SDTypography.bodyMedium),
        backgroundColor: SDColors.success500));

    // Appel backend (fire-and-forget)
    if (_isFavorited) {
      final token = auth.token;
      _api
          .addFavorite(
            token: token,
            title: widget.title,
            image: widget.image,
          )
          .catchError((e) => debugPrint('Erreur favoris: $e'));
    }
  }

  void _onReportTap() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Signaler le service', style: SDTypography.titleMedium),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: SDTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Décrivez le problème…',
              hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: SDTypography.labelMedium),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Veuillez saisir un motif.',
                        style: SDTypography.bodyMedium)),
                  );
                  return;
                }
                // envoyer au backend si connecté
                final auth = context.read<AuthCubit>().state;
                if (auth is AuthAuthenticated) {
                  try {
                    await _api.createReport(
                      token: auth.token,
                      targetType: 'SERVICE',
                      targetId: 'unknown',
                      reason: controller.text.trim(),
                    );
                    // succès
                  } catch (e) {
                    debugPrint('Erreur signalement: $e');
                  }
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.error500,
                foregroundColor: SDColors.white,
              ),
              child: Text('Envoyer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signalement envoyé. Merci.',
            style: SDTypography.bodyMedium),
            backgroundColor: SDColors.success500),
      );
    }
  }

  Widget _buildStickyCta(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(SDSpacing.sm, SDSpacing.xs, SDSpacing.sm, SDSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.primary700,
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
              ),
              elevation: 6,
            ),
            icon: Icon(Icons.shopping_cart_checkout_rounded,
                color: SDColors.white),
            label: Text(
              "Commander ce service",
              style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.white),
            ),
            onPressed: () {
              final auth = context.read<AuthCubit>().state;
              if (auth is! AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Veuillez vous connecter pour commander.',
                          style: SDTypography.bodyMedium)),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
                );
                return;
              }
              _openCheckoutSheet();
            },
          ),
        ),
      ),
    );
  }

  void _openCheckoutSheet() {
    final adresseCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SDSpacing.xxxl)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + SDSpacing.sm,
            left: SDSpacing.md,
            right: SDSpacing.md,
            top: SDSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête moderne
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(SDSpacing.xs),
                          decoration: BoxDecoration(
                            color: SDColors.primary700.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: SDColors.primary700,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: SDSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commander',
                                style: SDTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: SDColors.neutral900,
                                ),
                              ),
                              Text(
                                widget.title,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: SDColors.neutral400),
                        ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Sélecteur de prestataire moderne
                    if (_providers.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.person, color: SDColors.neutral700, size: 20),
                          SizedBox(width: SDSpacing.xs),
                          Text(
                            'Choisir un prestataire',
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(' *', style: SDTypography.titleSmall.copyWith(color: SDColors.error500)),
                        ],
                      ),
                      SizedBox(height: SDSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: SDColors.neutral300),
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedProviderId,
                          style: SDTypography.bodyMedium,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                            prefixIcon: Icon(Icons.person_pin_circle, color: SDColors.primary700),
                          ),
                          hint: Text('Sélectionnez un prestataire', style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
                          items: _providers.map((provider) {
                            final prenom = provider['utilisateur']?['prenom'] ?? '';
                            final nom = provider['utilisateur']?['nom'] ?? 'Inconnu';
                            final price = provider['prixprestataire'] ?? 0;
                            final note = provider['note'] ?? 'N/A';
                            return DropdownMenuItem<String>(
                              value: provider['_id']?.toString(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$prenom $nom',
                                      style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.star, size: 14, color: SDColors.warning500),
                                  SizedBox(width: SDSpacing.xxxs),
                                  Text(
                                    '$note',
                                    style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
                                  ),
                                  SizedBox(width: SDSpacing.xs),
                                  Text(
                                    '${price}F',
                                    style: SDTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: SDColors.primary700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              _selectedProviderId = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: SDSpacing.sm),
                    ],
                    
                    // Adresse
                    TextField(
                      controller: adresseCtrl,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ex: Rue 12, Cocody',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Icon(Icons.home, color: SDColors.primary700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Ville
                    TextField(
                      controller: villeCtrl,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ex: Abidjan',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Icon(Icons.location_city, color: SDColors.primary700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Date/Heure
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: SDColors.neutral300),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: SDColors.primary700),
                          SizedBox(width: SDSpacing.xs),
                          Expanded(
                            child: Text(
                              selectedDateTime == null
                                  ? 'Choisir une date et heure (optionnel)'
                                  : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} à ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                              style: SDTypography.bodyMedium.copyWith(
                                color: selectedDateTime == null ? SDColors.neutral500 : SDColors.neutral900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (date == null) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time == null) return;
                              final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              setSheetState(() => selectedDateTime = dt);
                            },
                            child: Text('Choisir', style: SDTypography.labelMedium.copyWith(color: SDColors.primary700)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Notes / Instructions (optionnel)',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ajoutez des détails supplémentaires...',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: SDSpacing.lg),
                          child: Icon(Icons.note_alt, color: SDColors.primary700),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Message GRATUIT amélioré et plus visible
                    Container(
                      padding: EdgeInsets.all(SDSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SDColors.success100, SDColors.success50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        border: Border.all(color: SDColors.success200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: SDColors.success200.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(SDSpacing.xs),
                            decoration: BoxDecoration(
                              color: SDColors.success500,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle, color: SDColors.white, size: 24),
                          ),
                          SizedBox(width: SDSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service 100% GRATUIT',
                                  style: SDTypography.titleSmall.copyWith(
                                    color: SDColors.success700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SDSpacing.xxxs),
                                Text(
                                  'Aucun paiement requis • Accès immédiat',
                                  style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.success600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Bouton de soumission moderne
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.primary700,
                          foregroundColor: SDColors.white,
                          elevation: 3,
                          shadowColor: SDColors.primary700.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          ),
                        ),
                        onPressed: () async {
                          final auth = context.read<AuthCubit>().state
                              as AuthAuthenticated;

                          // Validation simplifiée - seulement les champs essentiels
                          if (_selectedProviderId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez sélectionner un prestataire',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.warning500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          // Validation adresse et ville (requis)
                          if (adresseCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.location_off, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez renseigner votre adresse',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          if (villeCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.location_city_outlined, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez renseigner votre ville',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          // Date/heure optionnels - utiliser valeur par défaut si non renseigné
                          final dateTimeToUse = selectedDateTime ?? DateTime.now().add(Duration(days: 1));

                          // Montrer un loader
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(SDSpacing.md),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: SDColors.primary700),
                                      SizedBox(height: SDSpacing.sm),
                                      Text('Envoi en cours...', style: SDTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          try {
                            final created = await _api.createPrestation(
                              token: auth.token,
                              utilisateurId: auth.utilisateur.idutilisateur,
                              prestataireId: _selectedProviderId,
                              serviceId: _serviceId,
                              adresse: adresseCtrl.text.trim(),
                              ville: villeCtrl.text.trim(),
                              dateHeure: dateTimeToUse,
                              notesClient: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              moyenPaiement: 'GRATUIT',
                            );
                            
                            if (!mounted) return;
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Commande confirmée ! 🎉',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.primary700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            
                            final id = created['_id']?.toString();
                            if (id != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceRequestSummaryScreen(
                                    requestId: id,
                                    token: auth.token,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Erreur: ${e.toString()}',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 22, color: SDColors.white),
                            SizedBox(width: SDSpacing.xs),
                            Text(
                              'Confirmer la commande',
                              style: SDTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SDColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceImage(String path) {
    final isUrl = path.toLowerCase().startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
      child: isUrl
          ? Image.network(
              path,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SDColors.neutral200,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                  ),
                  child:
                      CircularProgressIndicator(color: SDColors.primary700),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: SDColors.neutral200,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported,
                      size: 48, color: SDColors.neutral500),
                );
              },
            )
          : Image.asset(
              path,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: SDColors.neutral200,
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported,
                    size: 48, color: SDColors.neutral500),
              ),
            ),
    );
  }

  Widget _buildServiceDescription() {
    // Utiliser la description du premier prestataire si disponible
    String description = "Ce service est assuré par un professionnel qualifié.";
    if (_providers.isNotEmpty && _providers.first['description'] != null) {
      description = _providers.first['description'];
    }

    return Text(
      description,
      style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
    );
  }

  Widget _buildProvidersStories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prestataires disponibles',
          style: SDTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: SDColors.neutral900,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        SizedBox(
          height: 120, // Hauteur pour les stories
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _providers.length,
            itemBuilder: (context, index) {
              final provider = _providers[index];
              return _buildProviderStory(provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderStory(Map<String, dynamic> provider) {
    final utilisateur = provider['utilisateur'];
    final nom = (utilisateur is Map<String, dynamic>)
        ? '${utilisateur['nom'] ?? ''} ${utilisateur['prenom'] ?? ''}'.trim()
        : 'Prestataire';
    final photo = (utilisateur is Map<String, dynamic>)
        ? (utilisateur['photoProfil'] ?? '')
        : '';
    final isUrl = photo.toString().toLowerCase().startsWith('http');
    final verified =
        provider['verifier'] == true || provider['verified'] == true;
    final price = provider['prixprestataire']?.toString() ?? '-';

    return Container(
      width: 80,
      margin: EdgeInsets.only(right: SDSpacing.sm),
      child: Column(
        children: [
          // Story ronde avec photo
          GestureDetector(
            onTap: () {
              // Action pour voir le profil du prestataire
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil de $nom',
                    style: SDTypography.bodyMedium)),
              );
            },
            child: Stack(
              children: [
                // Cercle principal
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: verified
                          ? SDColors.primary700
                          : SDColors.neutral300,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.neutral900.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: isUrl && photo.isNotEmpty
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: SDColors.primary700.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: SDColors.primary700,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: SDColors.primary700.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: SDColors.primary700,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                // Badge vérifié
                if (verified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: SDColors.primary700,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        color: SDColors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          // Nom du prestataire
          Text(
            nom.length > 10 ? '${nom.substring(0, 10)}...' : nom,
            style: SDTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: SDColors.neutral900,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SDSpacing.xxxs),
          // Prix
          Text(
            '$price FCFA',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
