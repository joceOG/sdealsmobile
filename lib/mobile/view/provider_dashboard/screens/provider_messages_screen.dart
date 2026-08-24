import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/conversation_id.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../../../data/models/conversation_model.dart';
import '../../chatpagem/chatpageblocm/chatPageBlocM.dart';
import '../../chatpagem/screens/chatPageScreenM.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Écran Messagerie prestataire — layout type Figma (chips + liste).
class ProviderMessagesScreen extends StatefulWidget {
  const ProviderMessagesScreen({super.key});

  @override
  ProviderMessagesScreenState createState() => ProviderMessagesScreenState();
}

class ProviderMessagesScreenState extends State<ProviderMessagesScreen> {
  String? _userId;
  String _searchQuery = '';
  bool _showSearch = false;
  /// all | unread | favorites
  String _chipFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};
  MessagesBloc? _messagesBloc;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.utilisateur.idutilisateur;
      final bloc = context.read<MessagesBloc>();
      bloc.setToken(authState.token);
      if (_userId != null) {
        bloc.setUserId(_userId!);
        bloc.add(ConnectWebSocket());
        bloc.add(LoadPrestataireConversations(_userId!));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messagesBloc ??= context.read<MessagesBloc>();
  }

  @override
  void dispose() {
    _messagesBloc?.add(DisconnectWebSocket());
    _searchController.dispose();
    super.dispose();
  }

  /// AppBar parent.
  void toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        if (_userId != null) {
          context
              .read<MessagesBloc>()
              .add(LoadPrestataireConversations(_userId!));
        }
      }
    });
  }

  /// AppBar parent.
  void openFilters() => _showFilterSheet();

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SDColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrer les conversations',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  ('all', 'Toutes les conversations', Icons.chat_bubble_outline_rounded),
                  ('unread', 'Non lues uniquement', Icons.mark_email_unread_outlined),
                  ('favorites', 'Favoris', Icons.star_border_rounded),
                  ('prestation', 'Liées à une prestation', Icons.work_outline_rounded),
                  ('support', 'Support', Icons.support_agent_outlined),
                ].map((e) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.$3, color: SDColors.neutral900),
                    title: Text(
                      e.$2,
                      style: SDTypography.bodyMedium
                          .copyWith(color: SDColors.neutral900),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applySheetFilter(e.$1);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applySheetFilter(String key) {
    if (_userId == null) return;
    setState(() {
      if (key == 'all' || key == 'unread' || key == 'favorites') {
        _chipFilter = key;
      }
    });
    switch (key) {
      case 'prestation':
        context.read<MessagesBloc>().add(
            FilterConversations(_userId!, typeMessage: 'PRESTATION'));
        break;
      case 'support':
        context
            .read<MessagesBloc>()
            .add(FilterConversations(_userId!, typeMessage: 'SUPPORT'));
        break;
      case 'unread':
        context.read<MessagesBloc>().add(LoadUnreadMessages(_userId!));
        break;
      default:
        context
            .read<MessagesBloc>()
            .add(LoadPrestataireConversations(_userId!));
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (_userId == null) return;
    if (value.trim().isEmpty) {
      context
          .read<MessagesBloc>()
          .add(LoadPrestataireConversations(_userId!));
    } else {
      context.read<MessagesBloc>().add(SearchMessages(_userId!, value.trim()));
    }
  }

  List<Map<String, dynamic>> _normalizeConversations(MessagesState state) {
    if (state is ConversationsLoaded) {
      return state.conversations
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
    }
    if (state is UnreadMessagesLoaded) {
      // Convertir messages non lus en lignes conversation-like
      return state.unreadMessages.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return {
          'conversationId': map['conversationId'],
          'interlocuteur': map['expediteur'],
          'dernierMessage': map,
          'nonLus': 1,
          'nombreNonLus': 1,
        };
      }).toList();
    }
    if (state is MessagesSearched) {
      return state.results.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return {
          'conversationId': map['conversationId'],
          'interlocuteur': map['expediteur'],
          'dernierMessage': map,
          'nonLus': 0,
        };
      }).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _filteredList(List<Map<String, dynamic>> all) {
    var list = all;
    if (_chipFilter == 'unread') {
      list = list.where((c) => _unreadCount(c) > 0).toList();
    } else if (_chipFilter == 'favorites') {
      list = list.where((c) => _favoriteIds.contains(_conversationKey(c))).toList();
    }
    if (_searchQuery.trim().isNotEmpty &&
        list.isNotEmpty &&
        // MessagesSearched déjà filtré côté API ; filtrer localement sur ConversationsLoaded
        true) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final other = _otherParticipant(c);
        final name = personNameFromMap(other, fallback: '').toLowerCase();
        final mission = _missionTitle(c).toLowerCase();
        final content =
            '${_lastMessage(c)?['contenu'] ?? ''}'.toLowerCase();
        return name.contains(q) || mission.contains(q) || content.contains(q);
      }).toList();
    }
    return list;
  }

  String _conversationKey(Map<String, dynamic> c) {
    return (c['conversationId'] ?? c['_id'] ?? '').toString();
  }

  int _unreadCount(Map<String, dynamic> c) {
    final v = c['nonLus'] ?? c['nombreNonLus'] ?? 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  Map<String, dynamic>? _lastMessage(Map<String, dynamic> c) {
    final dm = c['dernierMessage'];
    if (dm is Map) return Map<String, dynamic>.from(dm);
    return null;
  }

  Map<String, dynamic>? _otherParticipant(Map<String, dynamic> c) {
    final inter = c['interlocuteur'];
    if (inter is Map) return Map<String, dynamic>.from(inter);

    final exp = (c['expediteurInfo'] is List &&
            (c['expediteurInfo'] as List).isNotEmpty)
        ? c['expediteurInfo'][0]
        : null;
    final dest = (c['destinataireInfo'] is List &&
            (c['destinataireInfo'] as List).isNotEmpty)
        ? c['destinataireInfo'][0]
        : null;

    if (exp is Map && exp['_id']?.toString() == _userId) {
      return dest is Map ? Map<String, dynamic>.from(dest) : null;
    }
    if (dest is Map && dest['_id']?.toString() == _userId) {
      return exp is Map ? Map<String, dynamic>.from(exp) : null;
    }
    if (exp is Map) return Map<String, dynamic>.from(exp);
    if (dest is Map) return Map<String, dynamic>.from(dest);
    return null;
  }

  String _displayName(Map<String, dynamic>? p) {
    if (p == null) return 'Client';
    final prenom = cleanDisplayPart(p['prenom']);
    final nom = cleanDisplayPart(p['nom']);
    if (prenom != null && nom != null && nom.isNotEmpty) {
      return '$prenom ${nom[0].toUpperCase()}.';
    }
    return joinPersonName(prenom: prenom, nom: nom, fallback: 'Client');
  }

  String _missionTitle(Map<String, dynamic> c) {
    final dm = _lastMessage(c);
    final candidates = [
      c['titreMission'],
      c['titre'],
      c['prestationTitre'],
      dm?['titre'],
      dm?['referenceType'],
      dm?['typeMessage'],
    ];
    for (final v in candidates) {
      final s = '$v'.trim();
      if (s.isEmpty || s == 'null') continue;
      if (s == 'PRESTATION') return 'Mission / prestation';
      if (s == 'SUPPORT') return 'Support';
      if (s == 'COMMANDE') return 'Commande';
      return s;
    }
    return 'Conversation';
  }

  bool _isOnline(Map<String, dynamic>? p) {
    if (p == null) return false;
    final v = p['isOnline'] ?? p['enLigne'] ?? false;
    return v == true || v == 'true';
  }

  String _formatListTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString()).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(date.year, date.month, date.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return DateFormat('HH:mm').format(date);
      if (diff == 1) return 'Hier';
      if (diff < 7) {
        final label = DateFormat('EEEE', 'fr_FR').format(date);
        return label.isEmpty
            ? label
            : '${label[0].toUpperCase()}${label.substring(1)}';
      }
      return DateFormat('dd/MM').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SDColors.white,
      child: BlocBuilder<MessagesBloc, MessagesState>(
        builder: (context, state) {
          final raw = _normalizeConversations(state);
          final list = _filteredList(raw);
          final totalCount = state is ConversationsLoaded
              ? state.conversations.length
              : raw.length;
          final unreadTotal = state is ConversationsLoaded
              ? state.totalUnread
              : raw.fold<int>(0, (s, c) => s + _unreadCount(c));

          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                context
                    .read<MessagesBloc>()
                    .add(LoadPrestataireConversations(_userId!));
              }
            },
            color: SDColors.primary600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Échangez avec vos clients en toute simplicité.',
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral500),
                        ),
                        if (_showSearch) ...[
                          const SizedBox(height: 12),
                          _buildSearchField(),
                        ],
                        const SizedBox(height: 16),
                        _buildChips(totalCount, unreadTotal),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (state is MessagesLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (state is MessagesError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildError(state.message),
                  )
                else if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmpty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conversation = list[index];
                          return _ConversationRow(
                            conversation: conversation,
                            name: _displayName(_otherParticipant(conversation)),
                            mission: _missionTitle(conversation),
                            snippet:
                                '${_lastMessage(conversation)?['contenu'] ?? 'Aucun message'}',
                            time: _formatListTime(
                              _lastMessage(conversation)?['createdAt'] ??
                                  conversation['updatedAt'],
                            ),
                            unread: _unreadCount(conversation),
                            photo: _otherParticipant(conversation)?['photoProfil']
                                ?.toString(),
                            isOnline: _isOnline(_otherParticipant(conversation)),
                            isFavorite: _favoriteIds
                                .contains(_conversationKey(conversation)),
                            onTap: () => _openConversation(conversation),
                            onToggleFavorite: () {
                              final key = _conversationKey(conversation);
                              if (key.isEmpty) return;
                              setState(() {
                                if (_favoriteIds.contains(key)) {
                                  _favoriteIds.remove(key);
                                } else {
                                  _favoriteIds.add(key);
                                }
                              });
                            },
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
      decoration: InputDecoration(
        hintText: 'Rechercher un client, une mission…',
        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
        prefixIcon:
            const Icon(Icons.search_rounded, color: SDColors.neutral900),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded, color: SDColors.neutral900),
          onPressed: toggleSearch,
        ),
        filled: true,
        fillColor: SDColors.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SDColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SDColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SDColors.neutral900, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildChips(int total, int unread) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ChipPill(
            label: 'Toutes',
            selected: _chipFilter == 'all',
            badge: total > 0 ? '$total' : null,
            onTap: () {
              setState(() => _chipFilter = 'all');
              if (_userId != null) {
                context
                    .read<MessagesBloc>()
                    .add(LoadPrestataireConversations(_userId!));
              }
            },
          ),
          const SizedBox(width: 8),
          _ChipPill(
            label: 'Non lues',
            selected: _chipFilter == 'unread',
            badge: unread > 0 ? '$unread' : null,
            onTap: () => setState(() => _chipFilter = 'unread'),
          ),
          const SizedBox(width: 8),
          _ChipPill(
            label: 'Favoris',
            selected: _chipFilter == 'favorites',
            icon: Icons.star_border_rounded,
            onTap: () => setState(() => _chipFilter = 'favorites'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: SDColors.neutral900),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (_userId != null) {
                  context
                      .read<MessagesBloc>()
                      .add(LoadPrestataireConversations(_userId!));
                }
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    String title = 'Aucune conversation';
    String subtitle = 'Vos échanges avec les clients apparaîtront ici.';
    if (_chipFilter == 'unread') {
      title = 'Aucune non lue';
      subtitle = 'Vous êtes à jour.';
    } else if (_chipFilter == 'favorites') {
      title = 'Aucun favori';
      subtitle = 'Appuyez longuement sur une conversation pour l’ajouter.';
    } else if (_searchQuery.isNotEmpty) {
      title = 'Aucun résultat';
      subtitle = 'Essayez un autre mot-clé.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48,
                color: SDColors.neutral900.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              title,
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ouvrir le chat')),
      );
      return;
    }

    final currentUserId = authState.utilisateur.idutilisateur;
    String? conversationId = conversation['conversationId']?.toString() ??
        conversation['_id']?.toString();

    final other = _otherParticipant(conversation);
    final participantId = other?['_id']?.toString() ??
        getOtherParticipantId(conversationId ?? '', currentUserId) ??
        '';

    if ((conversationId == null || conversationId.isEmpty) &&
        participantId.isNotEmpty) {
      conversationId = buildConversationId(currentUserId, participantId);
    }

    if (conversationId == null || conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation introuvable')),
      );
      return;
    }

    final participantName = personNameFromMap(other, fallback: 'Client');
    final participantImage =
        safeImageUrl(other?['photoProfil']) ?? 'assets/images/default_user.png';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatPageBlocM(userId: currentUserId),
          child: ChatPageScreenM(
            conversationId: conversationId,
            participantId: participantId.isNotEmpty ? participantId : null,
            participantName:
                participantName.isNotEmpty ? participantName : 'Conversation',
            participantImage: participantImage,
            type: ConversationType.prestataire,
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final String? badge;
  final IconData? icon;
  final VoidCallback onTap;

  const _ChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.primary600 : SDColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? SDColors.white : SDColors.neutral900,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? SDColors.white.withValues(alpha: 0.22)
                        : SDColors.neutral200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: SDTypography.labelSmall.copyWith(
                      color: selected ? SDColors.white : SDColors.neutral800,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String name;
  final String mission;
  final String snippet;
  final String time;
  final int unread;
  final String? photo;
  final bool isOnline;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _ConversationRow({
    required this.conversation,
    required this.name,
    required this.mission,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.photo,
    required this.isOnline,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = unread > 0;
    return Material(
      color: highlight
          ? SDColors.primary50.withValues(alpha: 0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onToggleFavorite,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: SDColors.neutral100,
                    backgroundImage:
                        (photo != null && photo!.startsWith('http'))
                            ? NetworkImage(photo!)
                            : null,
                    child: (photo == null || !photo!.startsWith('http'))
                        ? const Icon(Icons.person_outline_rounded,
                            color: SDColors.neutral900)
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                          border: Border.all(color: SDColors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: SDTypography.titleSmall.copyWith(
                              color: SDColors.neutral900,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral800,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snippet,
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (unread > 0)
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              color: SDColors.primary600,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$unread',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          )
                        else if (isFavorite)
                          const Icon(Icons.star_rounded,
                              size: 18, color: SDColors.neutral900),
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
}
