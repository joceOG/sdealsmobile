import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/commande_model.dart';
import '../orderpageblocm/commande_bloc.dart';
import '../orderpageblocm/commande_event.dart';
import '../orderpageblocm/commande_state.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../widgets/commande_card.dart';
import 'commande_details_screen.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class OrderPageScreenM extends StatefulWidget {
  const OrderPageScreenM({super.key});

  @override
  State<OrderPageScreenM> createState() => _OrderPageScreenMState();
}

class _OrderPageScreenMState extends State<OrderPageScreenM>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Charger les commandes au démarrage
    context.read<CommandeBloc>().add(const ChargerCommandes());
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      CommandeStatus? selectedStatus;

      switch (_tabController.index) {
        case 0: // Toutes
          selectedStatus = null;
          break;
        case 1: // En attente
          selectedStatus = CommandeStatus.enAttente;
          break;
        case 2: // En cours
          selectedStatus = CommandeStatus.enCours;
          break;
        case 3: // Terminées
          selectedStatus = CommandeStatus.terminee;
          break;
        case 4: // Annulées
          selectedStatus = CommandeStatus.annulee;
          break;
      }

      context.read<CommandeBloc>().add(FiltrerParStatus(selectedStatus));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommandeBloc, CommandeState>(
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: SDColors.white,
          appBar: _buildAppBar(state),
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  context
                      .read<CommandeBloc>()
                      .add(const RechercherCommandes(''));
                }
              });
            },
            backgroundColor: SDColors.primary600,
            child: const Icon(
              Icons.search,
              color: SDColors.white,
            ),
          ),
        );
      },
    );
  }

  PreferredSize _buildAppBar(CommandeState state) {
    return PreferredSize(
      preferredSize: Size.fromHeight(_isSearchVisible ? 230 : 170),
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(44),
            bottomRight: Radius.circular(44),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: SDColors.primary600,
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(44),
              bottomRight: Radius.circular(44),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: SDSpacing.xxxs),
                // Titre
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: SDAnimations.medium,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: child,
                  ),
                  child: Center(
                    child: Text(
                      'COMMANDES',
                      style: SDTypography.displaySmall.copyWith(
                        color: SDColors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: SDSpacing.md),

                // Champ de recherche si visible
                if (_isSearchVisible)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                    child: Container(
                      decoration: BoxDecoration(
                        color: SDColors.white,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une commande...',
                          prefixIcon:
                              Icon(Icons.search, color: SDColors.primary600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.md,
                            vertical: SDSpacing.sm,
                          ),
                        ),
                        onChanged: (value) {
                          context
                              .read<CommandeBloc>()
                              .add(RechercherCommandes(value));
                        },
                      ),
                    ),
                  ),

                SizedBox(height: SDSpacing.xs),

                // TabBar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: SDColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                        color: SDColors.white,
                      ),
                      labelColor: SDColors.primary600,
                      unselectedLabelColor: SDColors.white,
                      isScrollable: true,
                      labelPadding: EdgeInsets.symmetric(horizontal: SDSpacing.xxs),
                      tabAlignment: TabAlignment.center,
                      labelStyle: SDTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: SDTypography.labelSmall,
                      tabs: [
                        _buildTab('Toutes', state.commandes.length),
                        _buildTab(
                          'En attente',
                          state.getNombreCommandesParStatus(
                              CommandeStatus.enAttente),
                        ),
                        _buildTab(
                          'En cours',
                          state.getNombreCommandesParStatus(
                              CommandeStatus.enCours),
                        ),
                        _buildTab(
                          'Terminées',
                          state.getNombreCommandesParStatus(
                              CommandeStatus.terminee),
                        ),
                        _buildTab(
                          'Annulées',
                          state.getNombreCommandesParStatus(
                              CommandeStatus.annulee),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (count > 0) ...[
            SizedBox(width: SDSpacing.xxxs),
            Container(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxxs, vertical: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tabController.index == _getTabIndexFromLabel(label)
                    ? SDColors.primary600
                    : SDColors.white,
              ),
              child: Text(
                count.toString(),
                style: SDTypography.labelSmall.copyWith(
                  fontSize: 9,
                  color: _tabController.index == _getTabIndexFromLabel(label)
                      ? SDColors.white
                      : SDColors.primary600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getTabIndexFromLabel(String label) {
    switch (label) {
      case 'Toutes':
        return 0;
      case 'En attente':
        return 1;
      case 'En cours':
        return 2;
      case 'Terminées':
        return 3;
      case 'Annulées':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildBody(CommandeState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SDColors.primary600)),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: SDColors.primary300),
            SizedBox(height: SDSpacing.md),
            Text(
              'Une erreur s\'est produite',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: SDColors.primary600,
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxxl),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
              ),
            ),
            SizedBox(height: SDSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CommandeBloc>().add(const ChargerCommandes());
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return EmptyStateWidget(
        imagePath: 'assets/commandes_vides.png',
        title: 'Aucune commande',
        message: 'Vous n\'avez pas encore passé de commande.\nCommencez vos achats dès maintenant !',
        imageSize: 200,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Toutes les commandes
        _buildCommandesList(state.commandesFiltrees),
        // En attente
        _buildCommandesList(state.commandesFiltrees),
        // En cours
        _buildCommandesList(state.commandesFiltrees),
        // Terminées
        _buildCommandesList(state.commandesFiltrees),
        // Annulées
        _buildCommandesList(state.commandesFiltrees),
      ],
    );
  }

  Widget _buildCommandesList(List<CommandeModel> commandes) {
    return ListView.builder(
      padding: EdgeInsets.only(top: SDSpacing.md, bottom: SDSpacing.xxxl),
      itemCount: commandes.length,
      itemBuilder: (context, index) {
        final commande = commandes[index];
        return CommandeCard(
          commande: commande,
          onViewDetails: () => _navigateToDetails(commande),
          onChat: () => _openChat(commande),
          onRate: commande.peutEtreNotee ? () => _rateCommande(commande) : null,
        );
      },
    );
  }

  String _getEmptyStateMessage(CommandeStatus? status) {
    if (status == null) {
      return 'Vous n\'avez pas encore passé de commande';
    }

    switch (status) {
      case CommandeStatus.enAttente:
        return 'Aucune commande en attente actuellement';
      case CommandeStatus.enCours:
        return 'Aucune commande en cours actuellement';
      case CommandeStatus.terminee:
        return 'Vous n\'avez pas encore de commande terminée';
      case CommandeStatus.annulee:
        return 'Aucune commande annulée';
      default:
        return 'Aucune commande trouvée';
    }
  }

  void _navigateToDetails(CommandeModel commande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeDetailsScreen(commande: commande),
      ),
    );
  }

  void _openChat(CommandeModel commande) {
    // Cette fonction serait implémentée pour ouvrir le chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat avec ${commande.prestataireName} ouvert'),
        backgroundColor: SDColors.success500,
      ),
    );
  }

  void _rateCommande(CommandeModel commande) {
    showDialog(
      context: context,
      builder: (context) => _buildRatingDialog(commande),
    );
  }

  Widget _buildRatingDialog(CommandeModel commande) {
    double rating = 0;
    final commentController = TextEditingController();

    return AlertDialog(
      title: const Text('Noter cette commande'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Comment évaluez-vous votre expérience avec ${commande.prestataireName}?'),
            SizedBox(height: SDSpacing.lg),
            StatefulBuilder(
              builder: (context, setState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: SDColors.warning500,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: SDSpacing.lg),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (rating > 0) {
              context.read<CommandeBloc>().add(NoterCommande(
                    commandeId: commande.id,
                    note: rating,
                    commentaire: commentController.text,
                  ));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merci pour votre évaluation!'),
                  backgroundColor: SDColors.success500,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez attribuer au moins 1 étoile'),
                  backgroundColor: SDColors.error500,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SDColors.primary600,
            foregroundColor: SDColors.white,
          ),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
