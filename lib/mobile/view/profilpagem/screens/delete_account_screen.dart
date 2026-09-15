import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/legal_urls.dart';
import '../../../../design_system/design_system.dart';

/// Profil → Paramètres → Supprimer mon compte (Play User Data).
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _busy = false;
  bool _confirmed = false;

  Future<void> _submit() async {
    if (_busy || !_confirmed) return;
    setState(() => _busy = true);
    try {
      final res =
          await ApiClient().post('/utilisateur/request-account-deletion');
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ApiException(
          message: 'Impossible d’enregistrer la suppression.',
          statusCode: res.statusCode,
        );
      }
      if (!mounted) return;
      await context.read<AuthCubit>().logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte supprimé. Vos données personnelles ont été anonymisées.',
          ),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Suppression impossible pour le moment. Réessayez.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(title: 'Supprimer mon compte'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Cette action est définitive',
              style:
                  SDTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'La suppression n’est pas une simple déconnexion. '
              'Vos données d’identité (nom, e-mail, téléphone, photo) seront '
              'anonymisées et vos sessions seront révoquées. '
              'Les avis et commandes déjà partagés peuvent être conservés '
              'sous forme anonymisée pour l’intégrité du service.',
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous pouvez aussi demander la suppression sans l’application :',
              style: SDTypography.bodyMedium,
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(LegalUrls.suppressionCompte),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Ouvrir la page web de suppression'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _confirmed,
              onChanged:
                  _busy ? null : (v) => setState(() => _confirmed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Je comprends que mon compte sera supprimé et que je ne pourrai plus me reconnecter avec ces identifiants.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_busy || !_confirmed) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmer la suppression'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
