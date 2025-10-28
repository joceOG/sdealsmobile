import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN MESSAGES PRESTATAIRE MAGNIFIQUE
class ProviderMessagesScreen extends StatefulWidget {
  const ProviderMessagesScreen({super.key});

  @override
  State<ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends State<ProviderMessagesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'unread', 'prestation', 'support'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // 🔌 Connecter au WebSocket pour les messages en temps réel
      context.read<MessagesBloc>().add(ConnectWebSocket());
      // Charger les conversations du prestataire
      context
          .read<MessagesBloc>()
          .add(LoadPrestataireConversations(_prestataireId!));
    }
  }

  @override
  void dispose() {
    // 🔌 Déconnecter le WebSocket
    context.read<MessagesBloc>().add(DisconnectWebSocket());

    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<MessagesBloc, MessagesState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildMessagesHeader(),
              _buildSearchAndFilters(),
              _buildTabSelector(),
              Expanded(
                child: _buildMessagesContent(state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // 🎨 HEADER DES MESSAGES
  Widget _buildMessagesHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messages Prestataire',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Communiquez avec vos clients',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUnreadBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔔 BADGE MESSAGES NON LUS
  Widget _buildUnreadBadge() {
    return BlocBuilder<MessagesBloc, MessagesState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is ConversationsLoaded) {
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
                Icons.notifications,
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
                      .read<MessagesBloc>()
                      .add(SearchMessages(_prestataireId!, value));
                }
              },
              decoration: InputDecoration(
                hintText: 'Rechercher dans les messages...',
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
      {'key': 'all', 'label': 'Tous', 'icon': Icons.all_inclusive},
      {'key': 'unread', 'label': 'Non lus', 'icon': Icons.mark_email_unread},
      {'key': 'prestation', 'label': 'Prestations', 'icon': Icons.work},
      {'key': 'support', 'label': 'Support', 'icon': Icons.support_agent},
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

  // 🔄 APPLIQUER LE FILTRE
  void _applyFilter() {
    if (_prestataireId == null) return;

    switch (_selectedFilter) {
      case 'all':
        context
            .read<MessagesBloc>()
            .add(LoadPrestataireConversations(_prestataireId!));
        break;
      case 'unread':
        context.read<MessagesBloc>().add(LoadUnreadMessages(_prestataireId!));
        break;
      case 'prestation':
        context.read<MessagesBloc>().add(
            FilterConversations(_prestataireId!, typeMessage: 'PRESTATION'));
        break;
      case 'support':
        context
            .read<MessagesBloc>()
            .add(FilterConversations(_prestataireId!, typeMessage: 'SUPPORT'));
        break;
    }
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
          // Gérer le changement d'onglet si nécessaire
        },
        tabs: const [
          Tab(text: 'Conversations', icon: Icon(Icons.chat_bubble_outline)),
          Tab(text: 'Non lus', icon: Icon(Icons.mark_email_unread)),
          Tab(text: 'Recherche', icon: Icon(Icons.search)),
        ],
      ),
    );
  }

  // 📊 CONTENU DES MESSAGES
  Widget _buildMessagesContent(MessagesState state) {
    if (state is MessagesLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is MessagesError) {
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
        _buildConversationsTab(state),
        _buildUnreadTab(state),
        _buildSearchTab(state),
      ],
    );
  }

  // 💬 ONGLET CONVERSATIONS
  Widget _buildConversationsTab(MessagesState state) {
    if (state is ConversationsLoaded) {
      if (state.conversations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Aucune conversation',
          subtitle: 'Vous n\'avez pas encore de messages',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          final conversation = state.conversations[index];
          return _buildConversationCard(conversation);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 📨 ONGLET MESSAGES NON LUS
  Widget _buildUnreadTab(MessagesState state) {
    if (state is UnreadMessagesLoaded) {
      if (state.unreadMessages.isEmpty) {
        return _buildEmptyState(
          icon: Icons.mark_email_read,
          title: 'Aucun message non lu',
          subtitle: 'Vous êtes à jour !',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.unreadMessages.length,
        itemBuilder: (context, index) {
          final message = state.unreadMessages[index];
          return _buildUnreadMessageCard(message);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 🔍 ONGLET RECHERCHE
  Widget _buildSearchTab(MessagesState state) {
    if (state is MessagesSearched) {
      if (state.results.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off,
          title: 'Aucun résultat',
          subtitle: 'Aucun message trouvé pour "${state.query}"',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final message = state.results[index];
          return _buildSearchResultCard(message);
        },
      );
    }

    return _buildEmptyState(
      icon: Icons.search,
      title: 'Rechercher des messages',
      subtitle: 'Tapez votre recherche dans la barre ci-dessus',
    );
  }

  // 💬 CARTE DE CONVERSATION
  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final dernierMessage = conversation['dernierMessage'];
    final expediteurInfo = conversation['expediteurInfo']?.isNotEmpty == true
        ? conversation['expediteurInfo'][0]
        : null;
    final destinataireInfo =
        conversation['destinataireInfo']?.isNotEmpty == true
            ? conversation['destinataireInfo'][0]
            : null;
    final nombreNonLus = conversation['nombreNonLus'] ?? 0;

    // Déterminer l'autre participant
    final otherParticipant = expediteurInfo ?? destinataireInfo;
    final isFromMe = expediteurInfo?['_id'] == _prestataireId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green.shade100,
              backgroundImage: otherParticipant?['photoProfil'] != null
                  ? NetworkImage(otherParticipant!['photoProfil'])
                  : null,
              child: otherParticipant?['photoProfil'] == null
                  ? Icon(Icons.person, color: Colors.green.shade600)
                  : null,
            ),
            if (nombreNonLus > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$nombreNonLus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          '${otherParticipant?['prenom'] ?? ''} ${otherParticipant?['nom'] ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dernierMessage?['contenu'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getMessageTypeIcon(dernierMessage?['typeMessage']),
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatMessageTime(dernierMessage?['createdAt']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.green.shade600,
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          _openConversation(conversation);
        },
      ),
    );
  }

  // 📨 CARTE MESSAGE NON LU
  Widget _buildUnreadMessageCard(Map<String, dynamic> message) {
    final expediteur = message['expediteur'];
    final contenu = message['contenu'] ?? '';
    final createdAt = message['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.shade100,
          backgroundImage: expediteur?['photoProfil'] != null
              ? NetworkImage(expediteur!['photoProfil'])
              : null,
          child: expediteur?['photoProfil'] == null
              ? Icon(Icons.person, color: Colors.red.shade600, size: 16)
              : null,
        ),
        title: Text(
          '${expediteur?['prenom'] ?? ''} ${expediteur?['nom'] ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contenu,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.mark_email_unread,
            color: Colors.white,
            size: 12,
          ),
        ),
        onTap: () {
          _openMessage(message);
        },
      ),
    );
  }

  // 🔍 CARTE RÉSULTAT DE RECHERCHE
  Widget _buildSearchResultCard(Map<String, dynamic> message) {
    final expediteur = message['expediteur'];
    final contenu = message['contenu'] ?? '';
    final createdAt = message['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: expediteur?['photoProfil'] != null
              ? NetworkImage(expediteur!['photoProfil'])
              : null,
          child: expediteur?['photoProfil'] == null
              ? Icon(Icons.person, color: Colors.blue.shade600, size: 16)
              : null,
        ),
        title: Text(
          '${expediteur?['prenom'] ?? ''} ${expediteur?['nom'] ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contenu,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () {
          _openMessage(message);
        },
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
        // TODO: Nouvelle conversation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonctionnalité en développement'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      backgroundColor: Colors.green.shade600,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Nouveau Message',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔧 MÉTHODES UTILITAIRES

  // 📅 FORMATER L'HEURE DU MESSAGE
  String _formatMessageTime(dynamic createdAt) {
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

  // 🎯 ICÔNE PAR TYPE DE MESSAGE
  IconData _getMessageTypeIcon(String? typeMessage) {
    switch (typeMessage) {
      case 'PRESTATION':
        return Icons.work;
      case 'SUPPORT':
        return Icons.support_agent;
      case 'COMMANDE':
        return Icons.shopping_cart;
      case 'AUTOMATIQUE':
        return Icons.smart_toy;
      default:
        return Icons.message;
    }
  }

  // 💬 OUVRIR UNE CONVERSATION
  void _openConversation(Map<String, dynamic> conversation) {
    // TODO: Ouvrir l'interface de chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interface de chat en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 📨 OUVRIR UN MESSAGE
  void _openMessage(Map<String, dynamic> message) {
    // TODO: Ouvrir le message dans son contexte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du message en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
