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
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E7D32),
                const Color(0xFF4CAF50),
              ],
            ),
          ),
        ),
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceImage(widget.image),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildServiceDescription(),
                  const SizedBox(height: 18),
                  const SizedBox(height: 28),

                  // Mini carte avec emplacement du prestataire
                  if (_providers.isNotEmpty)
                    MiniMapWidget(
                      provider:
                          _providers.first, // Premier prestataire comme exemple
                      userLocation: _userLocation,
                    ),

                  const SizedBox(height: 20),
                  AIProviderMatcherWidget(
                    serviceType: widget.title,
                    location: "Abidjan",
                    preferences: const [],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                    child: CircularProgressIndicator(
                        color: const Color(0xFF2E7D32))),
              ),
            )
          else if (_providers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text('Aucun prestataire trouvé pour ce service.'),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildProvidersStories(),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
      const SnackBar(content: Text('Texte copié dans le presse-papiers')),
    );
  }

  void _onFavoriteTap() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connectez-vous pour ajouter en favoris.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
      );
      return;
    }

    setState(() => _isFavorited = !_isFavorited);
    final msg = _isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
          title: const Text('Signaler le service'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Décrivez le problème…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir un motif.')),
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
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
  }

  Widget _buildStickyCta(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            icon: const Icon(Icons.shopping_cart_checkout_rounded,
                color: Colors.white),
            label: const Text(
              "Commander ce service",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            onPressed: () {
              final auth = context.read<AuthCubit>().state;
              if (auth is! AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez vous connecter pour commander.')),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commander ${widget.title}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  // Sélecteur de prestataire
                  if (_providers.isNotEmpty) ...[
                    const Text('Choisir un prestataire:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProviderId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Sélectionnez un prestataire',
                      ),
                      items: _providers.map((provider) {
                        final name =
                            provider['utilisateur']?['nom'] ?? 'Inconnu';
                        final price = provider['prixprestataire'] ?? 0;
                        return DropdownMenuItem<String>(
                          value: provider['_id']?.toString(),
                          child: Text('$name - ${price}FCFA'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() {
                          _selectedProviderId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: adresseCtrl,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: villeCtrl,
                    decoration: const InputDecoration(labelText: 'Ville'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(selectedDateTime == null
                            ? 'Date/heure non choisie'
                            : 'Le ${selectedDateTime!.toLocal()}'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                            initialDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time == null) return;
                          final dt = DateTime(date.year, date.month, date.day,
                              time.hour, time.minute);
                          setSheetState(() => selectedDateTime = dt);
                        },
                        icon: const Icon(Icons.calendar_today,
                            color: Color(0xFF2E7D32)),
                        label: const Text('Choisir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          )),
                      onPressed: () async {
                        final auth = context.read<AuthCubit>().state
                            as AuthAuthenticated;

                        // Validation
                        if (_selectedProviderId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Veuillez sélectionner un prestataire'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        try {
                          final created = await _api.createPrestation(
                            token: auth.token,
                            utilisateurId: auth.utilisateur.idutilisateur,
                            prestataireId: _selectedProviderId,
                            serviceId: _serviceId,
                            adresse: adresseCtrl.text.trim().isEmpty
                                ? null
                                : adresseCtrl.text.trim(),
                            ville: villeCtrl.text.trim().isEmpty
                                ? null
                                : villeCtrl.text.trim(),
                            dateHeure: selectedDateTime,
                            notesClient: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                            moyenPaiement: 'GRATUIT',
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Commande confirmée ! Demande envoyée aux prestataires.'),
                            backgroundColor: Colors.green,
                          ));
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
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')));
                        }
                      },
                      child: const Text('Confirmer la commande',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
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
      borderRadius: BorderRadius.circular(16),
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
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      size: 48, color: Colors.grey),
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
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported,
                    size: 48, color: Colors.grey),
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
      style: const TextStyle(fontSize: 15.5, color: Colors.black54),
    );
  }

  Widget _buildProvidersStories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prestataires disponibles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          // Story ronde avec photo
          GestureDetector(
            onTap: () {
              // Action pour voir le profil du prestataire
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil de $nom')),
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
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF2E7D32),
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF2E7D32),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Nom du prestataire
          Text(
            nom.length > 10 ? '${nom.substring(0, 10)}...' : nom,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Prix
          Text(
            '$price FCFA',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF2E7D32),
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
