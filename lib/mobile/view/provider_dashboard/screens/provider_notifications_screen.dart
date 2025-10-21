import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN NOTIFICATIONS PRESTATAIRE MAGNIFIQUE
class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter =
      'all'; // 'all', 'unread', 'prestation', 'payment', 'system'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // Charger les notifications du prestataire
      context
          .read<NotificationsBloc>()
          .add(LoadPrestataireNotifications(_prestataireId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Notifications Prestataire',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          _buildUnreadBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildSearchAndFilters(),
              _buildTabSelector(),
              Expanded(
                child: _buildNotificationsContent(state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // 🔔 BADGE NOTIFICATIONS NON LUES
  Widget _buildUnreadBadge() {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationsLoaded) {
          unreadCount = state.totalUnread;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: unreadCount > 0 ? Colors.red : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 16,
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 🔍 RECHERCHE ET FILTRES
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isNotEmpty && _prestataireId != null) {
                  context
                      .read<NotificationsBloc>()
                      .add(SearchNotifications(_prestataireId!, value));
                }
              },
              decoration: InputDecoration(
                hintText: 'Rechercher dans les notifications...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres
          _buildFilterChips(),
        ],
      ),
    );
  }

  // 🏷️ CHIPS DE FILTRAGE
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Toutes', 'icon': Icons.all_inclusive},
      {'key': 'unread', 'label': 'Non lues', 'icon': Icons.mark_email_unread},
      {'key': 'prestation', 'label': 'Prestations', 'icon': Icons.work},
      {'key': 'payment', 'label': 'Paiements', 'icon': Icons.payment},
      {'key': 'system', 'label': 'Système', 'icon': Icons.settings},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
                _applyFilter();
              },
              label: Text(filter['label'] as String),
              avatar: Icon(
                filter['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              selectedColor: Colors.green.shade600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 📊 SÉLECTEUR D'ONGlets
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          _handleTabChange(index);
        },
        tabs: const [
          Tab(text: 'Toutes', icon: Icon(Icons.notifications)),
          Tab(text: 'Non lues', icon: Icon(Icons.mark_email_unread)),
          Tab(text: 'Prestations', icon: Icon(Icons.work)),
          Tab(text: 'Système', icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  // 📊 CONTENU DES NOTIFICATIONS
  Widget _buildNotificationsContent(NotificationsState state) {
    if (state is NotificationsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is NotificationsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _applyFilter(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllNotificationsTab(state),
        _buildUnreadNotificationsTab(state),
        _buildPrestationNotificationsTab(state),
        _buildSystemNotificationsTab(state),
      ],
    );
  }

  // 🔔 ONGLET TOUTES LES NOTIFICATIONS
  Widget _buildAllNotificationsTab(NotificationsState state) {
    if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.notifications_none,
          title: 'Aucune notification',
          subtitle: 'Vous n\'avez pas encore de notifications',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _buildNotificationCard(notification);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 📨 ONGLET NOTIFICATIONS NON LUES
  Widget _buildUnreadNotificationsTab(NotificationsState state) {
    if (state is NotificationsLoaded) {
      final unreadNotifications =
          state.notifications.where((n) => n['statut'] == 'NON_LUE').toList();

      if (unreadNotifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.mark_email_read,
          title: 'Aucune notification non lue',
          subtitle: 'Vous êtes à jour !',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unreadNotifications.length,
        itemBuilder: (context, index) {
          final notification = unreadNotifications[index];
          return _buildNotificationCard(notification);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 💼 ONGLET NOTIFICATIONS PRESTATIONS
  Widget _buildPrestationNotificationsTab(NotificationsState state) {
    if (state is NotificationsLoaded) {
      final prestationNotifications =
          state.notifications.where((n) => n['type'] == 'PRESTATION').toList();

      if (prestationNotifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.work_outline,
          title: 'Aucune notification de prestation',
          subtitle:
              'Vous n\'avez pas encore de notifications liées aux prestations',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prestationNotifications.length,
        itemBuilder: (context, index) {
          final notification = prestationNotifications[index];
          return _buildNotificationCard(notification);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // ⚙️ ONGLET NOTIFICATIONS SYSTÈME
  Widget _buildSystemNotificationsTab(NotificationsState state) {
    if (state is NotificationsLoaded) {
      final systemNotifications =
          state.notifications.where((n) => n['type'] == 'SYSTEME').toList();

      if (systemNotifications.isEmpty) {
        return _buildEmptyState(
          icon: Icons.settings_outlined,
          title: 'Aucune notification système',
          subtitle: 'Vous n\'avez pas encore de notifications système',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: systemNotifications.length,
        itemBuilder: (context, index) {
          final notification = systemNotifications[index];
          return _buildNotificationCard(notification);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 🔔 CARTE DE NOTIFICATION
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'SYSTEME';
    final statut = notification['statut'] ?? 'NON_LUE';
    final priorite = notification['priorite'] ?? 'NORMALE';
    final titre = notification['titre'] ?? '';
    final message = notification['message'] ?? '';
    final createdAt = notification['createdAt'];
    final isUnread = statut == 'NON_LUE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getNotificationColor(type).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 24,
              ),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                  color: isUnread ? Colors.grey[800] : Colors.grey[700],
                ),
              ),
            ),
            _buildPriorityBadge(priorite),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getNotificationIcon(type),
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _getNotificationTypeLabel(type),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatNotificationTime(createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _handleNotificationTap(notification);
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (isUnread)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 16),
                    SizedBox(width: 8),
                    Text('Marquer comme lu'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive, size: 16),
                  SizedBox(width: 8),
                  Text('Archiver'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🏷️ BADGE DE PRIORITÉ
  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'CRITIQUE':
        color = Colors.red;
        break;
      case 'HAUTE':
        color = Colors.orange;
        break;
      case 'NORMALE':
        color = Colors.blue;
        break;
      case 'BASSE':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 📭 ÉTAT VIDE
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ➕ BOUTON D'ACTION FLOTTANT
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _markAllAsRead();
      },
      backgroundColor: Colors.green.shade600,
      icon: const Icon(Icons.mark_email_read, color: Colors.white),
      label: const Text(
        'Tout marquer comme lu',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔧 MÉTHODES UTILITAIRES

  // 🎨 COULEUR PAR TYPE DE NOTIFICATION
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'PRESTATION':
        return Colors.blue;
      case 'PAIEMENT':
        return Colors.green;
      case 'COMMANDE':
        return Colors.orange;
      case 'VERIFICATION':
        return Colors.purple;
      case 'MESSAGE':
        return Colors.teal;
      case 'SYSTEME':
        return Colors.grey;
      case 'PROMOTION':
        return Colors.pink;
      case 'RAPPEL':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // 🎯 ICÔNE PAR TYPE DE NOTIFICATION
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'PRESTATION':
        return Icons.work;
      case 'PAIEMENT':
        return Icons.payment;
      case 'COMMANDE':
        return Icons.shopping_cart;
      case 'VERIFICATION':
        return Icons.verified;
      case 'MESSAGE':
        return Icons.message;
      case 'SYSTEME':
        return Icons.settings;
      case 'PROMOTION':
        return Icons.local_offer;
      case 'RAPPEL':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  // 🏷️ LABEL PAR TYPE DE NOTIFICATION
  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'PRESTATION':
        return 'Prestation';
      case 'PAIEMENT':
        return 'Paiement';
      case 'COMMANDE':
        return 'Commande';
      case 'VERIFICATION':
        return 'Vérification';
      case 'MESSAGE':
        return 'Message';
      case 'SYSTEME':
        return 'Système';
      case 'PROMOTION':
        return 'Promotion';
      case 'RAPPEL':
        return 'Rappel';
      default:
        return 'Notification';
    }
  }

  // 📅 FORMATER L'HEURE DE LA NOTIFICATION
  String _formatNotificationTime(dynamic createdAt) {
    if (createdAt == null) return '';

    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min';
      } else {
        return 'Maintenant';
      }
    } catch (e) {
      return '';
    }
  }

  // 🔄 APPLIQUER LE FILTRE
  void _applyFilter() {
    if (_prestataireId == null) return;

    switch (_selectedFilter) {
      case 'all':
        context
            .read<NotificationsBloc>()
            .add(LoadPrestataireNotifications(_prestataireId!));
        break;
      case 'unread':
        context
            .read<NotificationsBloc>()
            .add(LoadUnreadNotifications(_prestataireId!));
        break;
      case 'prestation':
        context
            .read<NotificationsBloc>()
            .add(LoadNotificationsByType(_prestataireId!, 'PRESTATION'));
        break;
      case 'payment':
        context
            .read<NotificationsBloc>()
            .add(LoadNotificationsByType(_prestataireId!, 'PAIEMENT'));
        break;
      case 'system':
        context
            .read<NotificationsBloc>()
            .add(LoadNotificationsByType(_prestataireId!, 'SYSTEME'));
        break;
    }
  }

  // 📊 GÉRER LE CHANGEMENT D'ONGlet
  void _handleTabChange(int index) {
    if (_prestataireId == null) return;

    switch (index) {
      case 0: // Toutes
        context
            .read<NotificationsBloc>()
            .add(LoadPrestataireNotifications(_prestataireId!));
        break;
      case 1: // Non lues
        context
            .read<NotificationsBloc>()
            .add(LoadUnreadNotifications(_prestataireId!));
        break;
      case 2: // Prestations
        context
            .read<NotificationsBloc>()
            .add(LoadNotificationsByType(_prestataireId!, 'PRESTATION'));
        break;
      case 3: // Système
        context
            .read<NotificationsBloc>()
            .add(LoadNotificationsByType(_prestataireId!, 'SYSTEME'));
        break;
    }
  }

  // 🔔 GÉRER LE TAP SUR NOTIFICATION
  void _handleNotificationTap(Map<String, dynamic> notification) {
    final notificationId = notification['_id'];
    if (notificationId != null && _prestataireId != null) {
      // Marquer comme lue si ce n'est pas déjà fait
      if (notification['statut'] == 'NON_LUE') {
        context
            .read<NotificationsBloc>()
            .add(MarkNotificationAsRead(notificationId, _prestataireId!));
      }
    }
  }

  // ⚙️ GÉRER L'ACTION SUR NOTIFICATION
  void _handleNotificationAction(
      String action, Map<String, dynamic> notification) {
    final notificationId = notification['_id'];
    if (notificationId == null || _prestataireId == null) return;

    switch (action) {
      case 'mark_read':
        context
            .read<NotificationsBloc>()
            .add(MarkNotificationAsRead(notificationId, _prestataireId!));
        break;
      case 'archive':
        context
            .read<NotificationsBloc>()
            .add(ArchiveNotification(notificationId, _prestataireId!));
        break;
      case 'delete':
        _showDeleteConfirmation(notificationId);
        break;
    }
  }

  // 🗑️ CONFIRMATION DE SUPPRESSION
  void _showDeleteConfirmation(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_prestataireId != null) {
                context
                    .read<NotificationsBloc>()
                    .add(DeleteNotification(notificationId, _prestataireId!));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MARQUER TOUTES COMME LUES
  void _markAllAsRead() {
    if (_prestataireId != null) {
      context
          .read<NotificationsBloc>()
          .add(MarkAllNotificationsAsRead(_prestataireId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été marquées comme lues'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
