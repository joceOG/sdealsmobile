import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/freelance_model.dart';
import '../../chatpagem/screens/chatPageScreenM.dart';
import '../../chatpagem/chatpageblocm/chatPageBlocM.dart';
import '../../../data/models/conversation_model.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/conversation_id.dart';
import '../../../../design_system/design_system.dart';
import 'package:go_router/go_router.dart';

/// 📄 Page de détails d'un freelance
class FreelanceDetailsScreen extends StatelessWidget {
  final FreelanceModel freelance;

  const FreelanceDetailsScreen({
    super.key,
    required this.freelance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec image de profil
          _buildSliverAppBar(context),

          // Contenu principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section principale : Nom, job, badges
                _buildHeaderSection(context),

                const SizedBox(height: 16),

                // Section statistiques
                _buildStatsSection(context),

                const Divider(height: 32),

                // Section À propos
                _buildAboutSection(context),

                const Divider(height: 32),

                // Section Compétences
                _buildSkillsSection(context),

                const Divider(height: 32),

                // Section Portfolio
                if (freelance.portfolioItems.isNotEmpty) ...[
                  _buildPortfolioSection(context),
                  const Divider(height: 32),
                ],

                // Section Tarifs et disponibilité
                _buildPricingSection(context),

                const Divider(height: 32),

                // Section Vérification
                _buildVerificationSection(context),

                const SizedBox(
                    height: 100), // Espace pour les boutons flottants
              ],
            ),
          ),
        ],
      ),

      // Boutons d'action flottants
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  /// AppBar avec image en fond
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: SDColors.white,
      foregroundColor: SDColors.neutral900,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de profil
            freelance.imagePath.startsWith('http')
                ? Image.network(
                    freelance.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: SDColors.neutral100,
                      child: Icon(Icons.person,
                          size: 100, color: SDColors.neutral500),
                    ),
                  )
                : Image.asset(
                    freelance.imagePath.isNotEmpty
                        ? freelance.imagePath
                        : 'assets/profile_picture.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: SDColors.neutral100,
                      child: Icon(Icons.person,
                          size: 100, color: SDColors.neutral500),
                    ),
                  ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Statut de disponibilité
            Positioned(
              top: 60,
              right: 16,
              child: _buildAvailabilityBadge(),
            ),
          ],
        ),
      ),
    );
  }

  /// Badge de disponibilité
  Widget _buildAvailabilityBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (freelance.availabilityStatus) {
      case 'Disponible':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'Occupé':
        badgeColor = Colors.orange;
        badgeIcon = Icons.schedule;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            freelance.availabilityStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Section en-tête avec nom, job, badges
  Widget _buildHeaderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom
          Row(
            children: [
              Expanded(
                child: Text(
                  freelance.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (freelance.verificationDocuments?.isVerified == true)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified,
                      color: Colors.blue.shade700, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Job + Catégorie
          Row(
            children: [
              Icon(Icons.work, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  freelance.job,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  freelance.category,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Localisation
          if (freelance.location.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  freelance.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (freelance.isTopRated)
                _buildBadge('⭐ Top Rated', Colors.amber.shade700),
              if (freelance.isFeatured)
                _buildBadge('👑 Featured', Colors.purple.shade700),
              if (freelance.isNew)
                _buildBadge('🆕 Nouveau', Colors.green.shade700),
              _buildBadge(freelance.experienceLevel, Colors.blue.shade700),
              _buildBadge(freelance.workingHours, Colors.teal.shade700),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget badge
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Section statistiques
  Widget _buildStatsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.star,
            value: freelance.rating.toStringAsFixed(1),
            label: 'Note',
            color: Colors.amber.shade700,
          ),
          Container(width: 1, height: 40, color: Colors.green.shade200),
          _buildStatItem(
            icon: Icons.check_circle,
            value: '${freelance.completedJobs}',
            label: 'Projets',
            color: Colors.green.shade700,
          ),
          Container(width: 1, height: 40, color: Colors.green.shade200),
          _buildStatItem(
            icon: Icons.schedule,
            value: '${freelance.responseTime}h',
            label: 'Réponse',
            color: Colors.blue.shade700,
          ),
          if (freelance.clientSatisfaction > 0) ...[
            Container(width: 1, height: 40, color: Colors.green.shade200),
            _buildStatItem(
              icon: Icons.thumb_up,
              value: '${freelance.clientSatisfaction.toStringAsFixed(0)}%',
              label: 'Satisfaction',
              color: Colors.purple.shade700,
            ),
          ],
        ],
      ),
    );
  }

  /// Widget statistique individuelle
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Section À propos
  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            freelance.description.isNotEmpty
                ? freelance.description
                : 'Aucune description disponible',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Compétences
  Widget _buildSkillsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compétences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (freelance.skills.isEmpty)
            Text(
              'Aucune compétence renseignée',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: freelance.skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade700),
                        side: BorderSide(color: Colors.blue.shade200),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Section Portfolio
  Widget _buildPortfolioSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: freelance.portfolioItems.length,
              itemBuilder: (context, index) {
                final item = freelance.portfolioItems[index];
                return _buildPortfolioCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget carte de portfolio
  Widget _buildPortfolioCard(PortfolioItem item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 40),
                    ),
                  )
                : Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 40),
                  ),
          ),
          // Titre et description
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section tarifs et disponibilité
  Widget _buildPricingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money,
                    size: 32, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${freelance.hourlyRate.toStringAsFixed(0)} FCFA / heure',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    Text(
                      'Tarif horaire',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (freelance.currentProjects > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.work, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '${freelance.currentProjects} projet(s) en cours',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Section vérification
  Widget _buildVerificationSection(BuildContext context) {
    final isVerified = freelance.verificationDocuments?.isVerified ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isVerified ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVerified ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.info,
              color: isVerified ? Colors.green.shade700 : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Profil vérifié' : 'Profil non vérifié',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVerified
                          ? Colors.green.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVerified
                        ? 'Ce freelance a vérifié son identité'
                        : 'Ce freelance n\'a pas encore vérifié son identité',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
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

  /// Boutons d'action
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Téléphone
          if (freelance.phoneNumber != null &&
              freelance.phoneNumber!.isNotEmpty)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _makePhoneCall(freelance.phoneNumber!),
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (freelance.phoneNumber != null &&
              freelance.phoneNumber!.isNotEmpty)
            const SizedBox(width: 12),

          // Bouton Contacter
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contactFreelancer(context),
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text(
                'Contacter',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Passer un appel téléphonique
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  /// Contacter le freelancer
  void _contactFreelancer(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour envoyer un message'),
        ),
      );
      context.push('/login');
      return;
    }

    final destinataireUserId = freelance.utilisateurId;
    if (destinataireUserId == null || destinataireUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Impossible de démarrer la conversation (utilisateur manquant).'),
        ),
      );
      return;
    }

    final currentUserId = authState.utilisateur.idutilisateur ?? '';
    if (destinataireUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous envoyer un message.'),
        ),
      );
      return;
    }

    final conversationId =
        buildConversationId(currentUserId, destinataireUserId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatPageBlocM(userId: currentUserId),
          child: ChatPageScreenM(
            conversationId: conversationId,
            participantId: destinataireUserId,
            participantName: freelance.name,
            participantImage: freelance.imagePath.isNotEmpty
                ? freelance.imagePath
                : 'assets/images/default_user.png',
            type: ConversationType.freelance,
          ),
        ),
      ),
    );
  }
}
