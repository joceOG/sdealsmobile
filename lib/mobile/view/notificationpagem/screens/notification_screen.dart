import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart'; // ✅ Import DS
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
      backgroundColor: SDColors.neutral50,
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
    return SDWhiteAppBar.appBar(
      title: 'Mes Notifications',
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoaded && state.unreadCount > 0) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mark_email_read_outlined),
                    onPressed: _markAllAsRead,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: SDColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.white,
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
              icon: const Icon(Icons.mark_email_read_outlined),
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
      padding: EdgeInsets.all(SDSpacing.sm),
      color: SDColors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les notifications...',
              hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
              prefixIcon: Icon(Icons.search, color: SDColors.primary600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: SDColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: SDColors.primary600),
              ),
              filled: true,
              fillColor: SDColors.neutral50,
            ),
            style: SDTypography.bodyMedium,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: SDSpacing.xs),
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'all'),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Non lues', 'unread'),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Lues', 'read'),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Missions', 'MISSION'),
                SizedBox(width: SDSpacing.xs),
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
      selectedColor: SDColors.primary600.withOpacity(0.2),
      checkmarkColor: SDColors.primary600,
      backgroundColor: SDColors.white,
      side: BorderSide(
        color: isSelected ? SDColors.primary600 : SDColors.neutral200,
      ),
    );
  }

  // 📑 BARRE D'ONGLETS
  Widget _buildTabBar() {
    return Container(
      color: SDColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: SDColors.primary600,
        unselectedLabelColor: SDColors.neutral500,
        indicatorColor: SDColors.primary600,
        indicatorWeight: 3,
        labelStyle: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(SDColors.primary700),
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
                  color: SDColors.neutral400,
                ),
                SizedBox(height: SDSpacing.sm),
                Text(
                  'Erreur de chargement',
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.neutral600,
                  ),
                ),
                SizedBox(height: SDSpacing.xs),
                Text(
                  state.message,
                  style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SDSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    if (_userId != null) {
                      context.read<NotificationBloc>().add(
                            RefreshNotifications(_userId!),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                  ),
                  child: Text('Réessayer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
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

          // Grouper les notifications par type
          final groupedNotifications = _groupNotificationsByType(notifications);

          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                context.read<NotificationBloc>().add(
                      RefreshNotifications(_userId!),
                    );
              }
            },
            color: SDColors.primary700,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(SDSpacing.sm),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final group = groupedNotifications[index];
                final groupType = group['type'] as String;
                final groupNotifications = group['notifications'] as List<Map<String, dynamic>>;
                
                // Si un seul élément dans le groupe, afficher directement
                if (groupNotifications.length == 1) {
                  return Dismissible(
                    key: Key(groupNotifications[0]['_id'] ?? index.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: SDSpacing.md),
                      color: SDColors.error500,
                      child: Icon(Icons.delete, color: SDColors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Supprimer cette notification ?', style: SDTypography.titleMedium),
                          content: Text('Cette action est irréversible.', style: SDTypography.bodyMedium),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Annuler', style: SDTypography.labelMedium),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: SDColors.error500,
                              ),
                              child: Text('Supprimer', style: SDTypography.labelMedium.copyWith(color: SDColors.error500)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(groupNotifications[0]['_id'] ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification supprimée', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                          backgroundColor: SDColors.primary600,
                        ),
                      );
                    },
                    child: _buildNotificationCard(groupNotifications[0]),
                  );
                }
                
                // Si plusieurs éléments, afficher avec en-tête de groupe
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupHeader(groupType, groupNotifications.length),
                    ...groupNotifications.map((notification) => Dismissible(
                      key: Key(notification['_id'] ?? '${groupType}_${groupNotifications.indexOf(notification)}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: SDSpacing.md),
                        color: SDColors.error500,
                        child: Icon(Icons.delete, color: SDColors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Supprimer cette notification ?', style: SDTypography.titleMedium),
                            content: Text('Cette action est irréversible.', style: SDTypography.bodyMedium),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Annuler', style: SDTypography.labelMedium),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: SDColors.error500,
                                ),
                                child: Text('Supprimer', style: SDTypography.labelMedium.copyWith(color: SDColors.error500)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        context.read<NotificationBloc>().add(
                          DeleteNotification(notification['_id'] ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notification supprimée', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                            backgroundColor: SDColors.primary600,
                          ),
                        );
                      },
                      child: _buildNotificationCard(notification),
                    )).toList(),
                    SizedBox(height: SDSpacing.md),
                  ],
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
        iconColor = SDColors.primary600;
        break;
      case 'MISSION_ACCEPTEE':
        iconData = Icons.check_circle;
        iconColor = SDColors.success;
        break;
      case 'MISSION_REFUSEE':
        iconData = Icons.cancel;
        iconColor = SDColors.error;
        break;
      case 'MISSION_DEMARREE':
        iconData = Icons.play_circle;
        iconColor = SDColors.info;
        break;
      case 'MISSION_TERMINEE':
        iconData = Icons.done_all;
        iconColor = SDColors.success;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = SDColors.primary600;
    }

    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.xs),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: isRead
            ? null
            : Border.all(
                color: SDColors.primary600.withOpacity(0.3),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                padding: EdgeInsets.all(SDSpacing.xs),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: SDSpacing.xs),
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
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead ? SDColors.neutral700 : SDColors.neutral900,
                            ),
                          ),
                        ),
                        if (priorite == 'HAUTE')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SDSpacing.xxxs,
                              vertical: SDSpacing.xxxs,
                            ),
                            decoration: BoxDecoration(
                              color: SDColors.error500,
                              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                            ),
                            child: Text(
                              'URGENT',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.xxxs),
                      Text(
                        contenu,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: SDSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: SDColors.neutral500,
                        ),
                        SizedBox(width: SDSpacing.xxxs),
                        Text(
                          _formatDate(dateCreation),
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                        Spacer(),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: SDColors.primary600,
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
            color: SDColors.neutral400,
          ),
          SizedBox(height: SDSpacing.sm),
          Text(
            message,
            style: SDTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: SDColors.neutral600,
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          Text(
            'Vous recevrez des notifications ici\nquand vous aurez des missions',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
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
          SnackBar(
            content: Text('ID de mission manquant', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
            backgroundColor: SDColors.warning500,
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
          SnackBar(
            content: Text('ID de conversation manquant', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
            backgroundColor: SDColors.warning500,
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
  
  // Grouper les notifications par type
  List<Map<String, dynamic>> _groupNotificationsByType(List<Map<String, dynamic>> notifications) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var notification in notifications) {
      final type = notification['type']?.toString() ?? 'AUTRE';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(notification);
    }
    
    // Convertir en liste avec métadonnées
    return grouped.entries.map((entry) => {
      'type': entry.key,
      'notifications': entry.value,
    }).toList();
  }
  
  // En-tête de groupe
  Widget _buildGroupHeader(String type, int count) {
    String title;
    IconData icon;
    Color color;
    
    switch (type) {
      case 'NOUVELLE_MISSION':
        title = 'Nouvelles Missions';
        icon = Icons.assignment;
        color = SDColors.primary600;
        break;
      case 'MISSION_ACCEPTEE':
        title = 'Missions Acceptées';
        icon = Icons.check_circle;
        color = SDColors.success500;
        break;
      case 'MISSION_REFUSEE':
        title = 'Missions Refusées';
        icon = Icons.cancel;
        color = SDColors.error500;
        break;
      case 'MISSION_DEMARREE':
        title = 'Missions en Cours';
        icon = Icons.play_circle;
        color = SDColors.info500;
        break;
      case 'MISSION_TERMINEE':
        title = 'Missions Terminées';
        icon = Icons.done_all;
        color = SDColors.success500;
        break;
      case 'MESSAGE_RECU':
        title = 'Messages';
        icon = Icons.message;
        color = SDColors.primary600;
        break;
      default:
        title = 'Autres';
        icon = Icons.notifications;
        color = SDColors.neutral500;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.xs, top: SDSpacing.sm),
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: SDSpacing.xs),
          Text(
            title,
            style: SDTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
