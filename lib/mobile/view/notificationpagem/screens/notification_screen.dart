import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN NOTIFICATIONS CLIENT MAGNIFIQUE
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  String? _userId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    // Listener pour pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Charger plus quand on arrive à 200px de la fin
        if (_userId != null) {
          context.read<NotificationBloc>().add(
            LoadMoreNotifications(_userId!),
          );
        }
      }
    });

    // Récupérer l'ID de l'utilisateur depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.utilisateur.idutilisateur;
      // Définir le token dans le BLoC
      context.read<NotificationBloc>().setToken(authState.token);
      // Charger les notifications de l'utilisateur
      context
          .read<NotificationBloc>()
          .add(LoadUserNotifications(userId: _userId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab('all'),
                _buildNotificationsTab('unread'),
                _buildNotificationsTab('read'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 APP BAR MAGNIFIQUE
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      title: const Text(
        'Mes Notifications',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoaded && state.unreadCount > 0) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    onPressed: _markAllAsRead,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
            );
          },
        ),
      ],
    );
  }

  // 🔍 BARRE DE RECHERCHE ET FILTRES
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les notifications...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Non lues', 'unread'),
                const SizedBox(width: 8),
                _buildFilterChip('Lues', 'read'),
                const SizedBox(width: 8),
                _buildFilterChip('Missions', 'MISSION'),
                const SizedBox(width: 8),
                _buildFilterChip('Système', 'SYSTEM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ CHIPS DE FILTRE
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        context.read<NotificationBloc>().add(
              FilterNotifications(statut: value == 'all' ? null : value),
            );
      },
      selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
      ),
    );
  }

  // 📑 BARRE D'ONGLETS
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF2E7D32),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Toutes'),
          Tab(text: 'Non lues'),
          Tab(text: 'Lues'),
        ],
        onTap: (index) {
          String filter = 'all';
          switch (index) {
            case 0:
              filter = 'all';
              break;
            case 1:
              filter = 'unread';
              break;
            case 2:
              filter = 'read';
              break;
          }
          context.read<NotificationBloc>().add(
                FilterNotifications(statut: filter == 'all' ? null : filter),
              );
        },
      ),
    );
  }

  // 📱 ONGLET DE NOTIFICATIONS
  Widget _buildNotificationsTab(String filter) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        if (state is NotificationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_userId != null) {
                      context.read<NotificationBloc>().add(
                            RefreshNotifications(_userId!),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state is NotificationLoaded) {
          List<Map<String, dynamic>> notifications = state.notifications;

          // Filtrer par recherche
          if (_searchQuery.isNotEmpty) {
            notifications = notifications.where((notification) {
              final titre =
                  notification['titre']?.toString().toLowerCase() ?? '';
              final contenu =
                  notification['contenu']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return titre.contains(query) || contenu.contains(query);
            }).toList();
          }

          // Filtrer par statut
          if (filter != 'all') {
            notifications = notifications.where((notification) {
              final statut = notification['statut']?.toString() ?? '';
              return statut == filter;
            }).toList();
          }

          if (notifications.isEmpty) {
            return _buildEmptyState(filter);
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                context.read<NotificationBloc>().add(
                      RefreshNotifications(_userId!),
                    );
              }
            },
            color: const Color(0xFF2E7D32),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(notifications[index]['_id'] ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer cette notification ?'),
                        content: const Text('Cette action est irréversible.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<NotificationBloc>().add(
                      DeleteNotification(notifications[index]['_id'] ?? ''),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification supprimée'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  child: _buildNotificationCard(notifications[index]),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // 📄 CARTE DE NOTIFICATION
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['statut'] == 'LU';
    final type = notification['type']?.toString() ?? '';
    final titre = notification['titre']?.toString() ?? 'Notification';
    final contenu = notification['contenu']?.toString() ?? '';
    final dateCreation = notification['dateCreation']?.toString() ?? '';
    final priorite = notification['priorite']?.toString() ?? 'NORMALE';

    // Icône selon le type
    IconData iconData;
    Color iconColor;
    switch (type) {
      case 'NOUVELLE_MISSION':
        iconData = Icons.assignment;
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'MISSION_ACCEPTEE':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'MISSION_REFUSEE':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'MISSION_DEMARREE':
        iconData = Icons.play_circle;
        iconColor = Colors.blue;
        break;
      case 'MISSION_TERMINEE':
        iconData = Icons.done_all;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = const Color(0xFF2E7D32);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isRead
            ? null
            : Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        if (priorite == 'HAUTE')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contenu,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(dateCreation),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📭 ÉTAT VIDE
  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'unread':
        message = 'Aucune notification non lue';
        icon = Icons.mark_email_read;
        break;
      case 'read':
        message = 'Aucune notification lue';
        icon = Icons.drafts;
        break;
      default:
        message = 'Aucune notification';
        icon = Icons.notifications_none;
    }

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
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous recevrez des notifications ici\nquand vous aurez des missions',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🎯 ACTIONS
  void _onNotificationTap(Map<String, dynamic> notification) {
    // Marquer comme lue si ce n'est pas déjà fait
    if (notification['statut'] != 'LU') {
      context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notification['_id']?.toString() ?? ''),
          );
    }

    // ✅ Navigation selon le type de notification
    final type = notification['type']?.toString() ?? '';
    
    if (type.contains('MISSION')) {
      final missionId = notification['donnees']?['missionId']?.toString();
      if (missionId != null) {
        // ✅ Navigation vers MissionDetailsScreen
        context.push('/mission-details/$missionId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID de mission manquant'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (type.contains('MESSAGE')) {
      final conversationId = notification['donnees']?['conversationId']?.toString();
      if (conversationId != null) {
        // ✅ Navigation vers Chat
        context.push('/chat/$conversationId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID de conversation manquant'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    // Autres types: juste marquer comme lu (déjà fait)
  }

  void _markAllAsRead() {
    if (_userId != null) {
      context.read<NotificationBloc>().add(
            MarkAllNotificationsAsRead(_userId!),
          );
    }
  }

  // 📅 FORMATAGE DE DATE
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Date inconnue';
    }
  }
}
