import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';

/// Liste des services d’une catégorie (Métiers) — pas un nom de catégorie
/// passé comme identifiant de service.
class CategoryServicesScreen extends StatefulWidget {
  final String categorieId;
  final String nomcategorie;
  final String? imagecategorie;

  const CategoryServicesScreen({
    super.key,
    required this.categorieId,
    required this.nomcategorie,
    this.imagecategorie,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String _error = '';
  List<Service> _services = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final list = await _api.fetchServicesByCategorie(widget.categorieId);
      if (!mounted) return;
      setState(() {
        _services = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les services de cette catégorie.';
      });
    }
  }

  void _openService(Service service) {
    final image = normalizeMediaUrl(service.imageservice) ??
        normalizeMediaUrl(widget.imagecategorie) ??
        '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPage(
          title: service.nomservice,
          image: image,
          serviceId: service.idservice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(title: widget.nomcategorie),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_services.isEmpty) {
      return Center(
        child: Text(
          'Aucun service dans cette catégorie',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ServiceTile(
        service: _services[i],
        categoryImage: widget.imagecategorie,
        onTap: () => _openService(_services[i]),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final String? categoryImage;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.categoryImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = normalizeMediaUrl(service.imageservice) ??
        normalizeMediaUrl(categoryImage);
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: img != null
                    ? AppImage(
                        imageUrl: img,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: SDColors.primary50,
                        child: const Icon(
                          Icons.handyman_outlined,
                          color: SDColors.primary700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.nomservice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
