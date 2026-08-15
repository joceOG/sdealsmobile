import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../chatpageblocm/chatPageBlocM.dart';
import '../chatpageblocm/chatPageEventM.dart';
import '../chatpageblocm/chatPageStateM.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../../searchpagem/screens/searchPageScreenM.dart';
import '../../../../data/services/authCubit.dart';
import 'package:go_router/go_router.dart';
import '../widgets/voice_recorder_widget.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

/// Filtres type Figma : Tous, Travaux (prestataires), Freelance, Produits (vendeurs).
enum _MessagesInboxFilter { tous, travaux, freelance, produits }

class ChatPageScreenM extends StatefulWidget {
  final String? conversationId;
  final String? participantId;
  final String? participantName;
  final String? participantImage;
  final ConversationType? type;

  const ChatPageScreenM({
    super.key,
    this.conversationId,
    this.participantId,
    this.participantName,
    this.participantImage,
    this.type,
  });

  @override
  State<ChatPageScreenM> createState() => _ChatPageScreenMState();
}

class _ChatPageScreenMState extends State<ChatPageScreenM>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _listSearchController = TextEditingController();
  _MessagesInboxFilter _inboxFilter = _MessagesInboxFilter.tous;
  bool _arrowPressed = false;
  File? _selectedImage;
  int _prestatairePressed = -1;
  final ImagePicker _imagePicker = ImagePicker();
  DateTime? _lastTypingEmit;

  late ChatPageBlocM _chatBloc;
  String _currentUserId = '';

  // Méthode pour obtenir la couleur selon le type de conversation
  Color _getConversationColor(ConversationType type) {
    switch (type) {
      case ConversationType.prestataire:
        return SDColors.primary600;
      case ConversationType.vendeur:
        return SDColors.primary700;
      case ConversationType.freelance:
        return SDColors.primary500;
    }
  }

  // Méthode pour obtenir le label selon le type de conversation
  String _getConversationLabel(ConversationType type) {
    switch (type) {
      case ConversationType.prestataire:
        return 'Prestataire';
      case ConversationType.vendeur:
        return 'Vendeur';
      case ConversationType.freelance:
        return 'Freelance';
    }
  }

  /// Libellé court pour la ligne d’aperçu (style Figma : « Métier : extrait »).
  String _getInboxCategoryLabel(ConversationType type) {
    switch (type) {
      case ConversationType.prestataire:
        return 'Travaux';
      case ConversationType.freelance:
        return 'Freelance';
      case ConversationType.vendeur:
        return 'Produits';
    }
  }

  String _formatListRowTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    }
    if (now.difference(day).inDays < 7) {
      const wd = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
      return wd[t.weekday - 1];
    }
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.'
    ];
    return '${t.day} ${months[t.month - 1]}';
  }

  /// Photo réseau / asset si dispo, sinon avatar initiales.
  Widget _buildConversationAvatar(ConversationModel conversation) {
    final img = conversation.participantImage.trim();
    final hasNetwork = img.startsWith('http');
    final hasAsset = img.startsWith('assets/') &&
        img.isNotEmpty &&
        img != 'assets/profil.png';
    final initial = conversation.participantName.trim().isNotEmpty
        ? conversation.participantName.trim()[0].toUpperCase()
        : '?';

    Widget initialsAvatar() {
      return CircleAvatar(
        radius: 26,
        backgroundColor: SDColors.neutral200,
        child: Text(
          initial,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    Widget avatar;
    if (hasNetwork) {
      avatar = ClipOval(
        child: Image.network(
          img,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => initialsAvatar(),
        ),
      );
    } else if (hasAsset) {
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: SDColors.neutral200,
        backgroundImage: AssetImage(img),
      );
    } else {
      avatar = initialsAvatar();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: SDColors.success500,
                shape: BoxShape.circle,
                border: Border.all(color: SDColors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInboxConversationRow(
    ConversationModel conversation, {
    required bool isSelected,
  }) {
    final snippet = conversation.lastMessage?.content.trim().isNotEmpty == true
        ? conversation.lastMessage!.content
        : 'Aucun message';

    return InkWell(
      onTap: () => _chatBloc.add(SelectConversation(conversation)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? SDColors.neutral100 : null,
          border: const Border(
            bottom: BorderSide(color: SDColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConversationAvatar(conversation),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName,
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SDColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatListRowTime(conversation.lastUpdated),
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: SDColors.neutral900,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${conversation.unreadCount}',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.typeText,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral800,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesInboxFilter(ConversationType type, _MessagesInboxFilter f) {
    switch (f) {
      case _MessagesInboxFilter.tous:
        return true;
      case _MessagesInboxFilter.travaux:
        return type == ConversationType.prestataire;
      case _MessagesInboxFilter.freelance:
        return type == ConversationType.freelance;
      case _MessagesInboxFilter.produits:
        return type == ConversationType.vendeur;
    }
  }

  List<ConversationModel> _filteredConversations(
      List<ConversationModel> all) {
    final q = _listSearchController.text.trim().toLowerCase();
    return all.where((c) {
      if (!_matchesInboxFilter(c.type, _inboxFilter)) return false;
      if (q.isEmpty) return true;
      final name = c.participantName.toLowerCase();
      final last = c.lastMessage?.content.toLowerCase() ?? '';
      return name.contains(q) || last.contains(q);
    }).toList();
  }

  void _onComposeTap() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_rounded, color: SDColors.primary700),
                  SizedBox(width: SDSpacing.sm),
                  Text(
                    'Nouvelle conversation',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.sm),
              Text(
                'Recherchez un prestataire, un freelance ou une boutique depuis Explorer, puis contactez-les.',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
              SizedBox(height: SDSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SDColors.primary700,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchPageScreenM(),
                    ),
                  );
                },
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('Ouvrir la recherche'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar uniquement en conversation sur **mobile** (retour + titre + menu).
  PreferredSizeWidget _buildMobileConversationAppBar(ChatPageStateM state) {
    return SDAppBarIconThemed(
      style: SDAppBarIconStyles.onLightSurface,
      bar: AppBar(
      backgroundColor: SDColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: SDColors.neutral900, size: 20),
        onPressed: () {
          context.read<ChatPageBlocM>().add(const LoadConversations());
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              state.selectedConversation!.participantName,
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SDSpacing.xxs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SDSpacing.xxs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _getConversationColor(state.selectedConversation!.type)
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(SDSpacing.borderRadiusSmall),
            ),
            child: Text(
              _getConversationLabel(state.selectedConversation!.type),
              style: SDTypography.labelSmall.copyWith(
                color:
                    _getConversationColor(state.selectedConversation!.type),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: SDColors.neutral800),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: SDColors.neutral200),
      ),
    ),
    );
  }

  /// Titre page aligné comme Profil (gauche, gros).
  Widget _buildMessagesTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Messages',
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: SDColors.neutral200),
          ),
          child: IconButton(
            onPressed: _onComposeTap,
            icon: Icon(Icons.edit_rounded, color: SDColors.primary700, size: 22),
            tooltip: 'Nouveau message',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// Même design que `ExplorerPageScreen._buildSearchRow` (pill claire, contour noir).
  Widget _buildExplorerStyleInboxSearch(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 10),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SDColors.neutral900, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: SDColors.neutral700, size: 22),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: TextField(
              controller: _listSearchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              cursorColor: SDColors.neutral900,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation…',
                hintStyle: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral500,
                  fontSize: 14,
                ),
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              style: SDTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: SDColors.neutral900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.arrow_forward,
              color: SDColors.neutral900,
              size: 22,
            ),
            tooltip: 'Rechercher',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip({
      required String label,
      required IconData icon,
      required _MessagesInboxFilter value,
    }) {
      final selected = _inboxFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _inboxFilter = value),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? SDColors.neutral200 : SDColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? SDColors.neutral300
                      : SDColors.neutral300.withOpacity(0.85),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? SDColors.neutral900
                        : SDColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: SDTypography.labelMedium.copyWith(
                      color: selected
                          ? SDColors.neutral900
                          : SDColors.neutral700,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          chip(
            label: 'Tous',
            icon: Icons.forum_outlined,
            value: _MessagesInboxFilter.tous,
          ),
          chip(
            label: 'Travaux',
            icon: Icons.work_outline_rounded,
            value: _MessagesInboxFilter.travaux,
          ),
          chip(
            label: 'Freelance',
            icon: Icons.person_outline_rounded,
            value: _MessagesInboxFilter.freelance,
          ),
          chip(
            label: 'Produits',
            icon: Icons.shopping_bag_outlined,
            value: _MessagesInboxFilter.produits,
          ),
        ],
      ),
    );
  }

  // Méthode pour formater l'horodatage des messages
  String _formatMessageTime(DateTime timestamp) {
    // Format HH:MM
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');

    // Vérifier si le message est d'aujourd'hui
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Si c'est aujourd'hui, afficher seulement l'heure
      return '$hour:$minute';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Si c'est hier
      return 'Hier, $hour:$minute';
    } else if (now.difference(timestamp).inDays < 7) {
      // Si c'est dans la semaine, afficher le nom du jour
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final weekday = weekdays[timestamp.weekday - 1];
      return '$weekday, $hour:$minute';
    } else {
      // Sinon afficher la date complète
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      return '$day/$month, $hour:$minute';
    }
  }

  @override
  void initState() {
    super.initState();
    _chatBloc = BlocProvider.of<ChatPageBlocM>(context);

    // Injecter le vrai userId depuis AuthCubit dans le BLoC
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.utilisateur.idutilisateur ?? '';
      _chatBloc.setUserId(_currentUserId);
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    // 🔌 Déconnecter le WebSocket
    _chatBloc.add(DisconnectWebSocket());

    _messageController.dispose();
    _listSearchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // 🔌 Connecter au WebSocket pour les messages en temps réel
    _chatBloc.add(ConnectWebSocket());

    // Charger la liste des conversations
    _chatBloc.add(LoadConversations());

    // Si nous avons un ID de conversation, on charge ses messages
    if (widget.conversationId != null) {
      _chatBloc.add(LoadMessages(widget.conversationId!));
    }
    // Si nous avons des informations sur un participant mais pas d'ID de conversation,
    // on crée une nouvelle conversation
    else if (widget.participantId != null) {
      _chatBloc.add(CreateConversation(
        participantId: widget.participantId!,
        participantName: widget.participantName ?? 'Utilisateur',
        participantImage:
            widget.participantImage ?? 'assets/images/default_user.png',
        type: widget.type ?? ConversationType.prestataire,
      ));
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    final state = _chatBloc.state;
    if (state.status == ChatPageStatus.loaded &&
        state.selectedConversation != null) {
      final convId = state.selectedConversation!.id;
      _chatBloc.add(EmitTyping(conversationId: convId, isTyping: false));

      if (_selectedImage != null) {
        _chatBloc.add(SendMessage(
          conversationId: convId,
          content: _messageController.text.trim(),
          type: MessageType.image,
          imageFile: _selectedImage,
        ));
        setState(() => _selectedImage = null);
        _messageController.clear();
      } else {
        _chatBloc.add(SendMessage(
          conversationId: convId,
          content: _messageController.text.trim(),
          type: MessageType.text,
        ));
        _messageController.clear();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de sélectionner l\'image: $e')),
      );
    }
  }

  void _onMessageChanged(String value) {
    final conv = _chatBloc.state.selectedConversation;
    if (conv == null) return;
    final now = DateTime.now();
    if (_lastTypingEmit == null ||
        now.difference(_lastTypingEmit!) > const Duration(seconds: 1)) {
      _lastTypingEmit = now;
      _chatBloc.add(EmitTyping(
        conversationId: conv.id,
        isTyping: value.trim().isNotEmpty,
      ));
    }
  }

  // 🔐 Écran affiché quand l'utilisateur n'est pas connecté
  Widget _buildNotAuthenticatedScreen(BuildContext context) {
    const hPad = 20.0;
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: Text(
                'Messages',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(hPad, 24, hPad, 32),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: SDColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      size: 56,
                      color: SDColors.primary600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pas encore de messages',
                    style: SDTypography.titleMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour discuter avec des prestataires, vendeurs et freelances.',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Se connecter',
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: const BorderSide(
                          color: SDColors.primary600,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Créer un compte',
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    // 🔐 Guard : afficher un écran "non connecté" si l'utilisateur n'est pas authentifié
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return _buildNotAuthenticatedScreen(context);
    }

    return BlocConsumer<ChatPageBlocM, ChatPageStateM>(
        listener: (context, state) {
          // Gérer les erreurs
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }

          // Faire défiler vers le bas après l'envoi ou la réception d'un message
          if (state.status == ChatPageStatus.loaded &&
              state.selectedConversation != null &&
              state.messagesByConversation
                  .containsKey(state.selectedConversation!.id)) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        },
        builder: (context, state) {
          // Déterminer si on est sur mobile ou sur un écran plus grand
          final bool isMobile = MediaQuery.of(context).size.width < 600;
          final bool showConversationList =
              !isMobile || state.selectedConversation == null;
          final bool showConversation =
              !isMobile || state.selectedConversation != null;
          final bool showMobileChatAppBar =
              isMobile && state.selectedConversation != null;

          final filtered = _filteredConversations(state.conversations);

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: SDColors.white,
            appBar: showMobileChatAppBar
                ? PreferredSize(
                    preferredSize: Size.fromHeight(kToolbarHeight + 1),
                    child: _buildMobileConversationAppBar(state),
                  )
                : null,
            body: SafeArea(
              top: !showMobileChatAppBar,
              bottom: false,
              child: Column(
            children: [
              if (showConversationList) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMessagesTopHeader(),
                      SizedBox(height: SDSpacing.md),
                      _buildExplorerStyleInboxSearch(context),
                    ],
                  ),
                ),
                _buildFilterChips(),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Liste des conversations (affichée uniquement si nécessaire selon la responsivité)
                    if (showConversationList)
                      Flexible(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
                            boxShadow: [
                              BoxShadow(
                                color: SDColors.neutral900.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: state.status == ChatPageStatus.loading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : state.conversations.isEmpty
                                        ? EmptyStateWidget(
                                            imagePath: 'assets/messages_vides.png',
                                            title: 'Aucune conversation',
                                            message: 'Démarrez une nouvelle conversation en contactant un prestataire ou un vendeur',
                                            imageSize: 180,
                                          )
                                        : filtered.isEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(SDSpacing.md),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.search_off_rounded,
                                                          size: 48,
                                                          color: SDColors.neutral400),
                                                      SizedBox(height: SDSpacing.sm),
                                                      Text(
                                                        'Aucun résultat',
                                                        style: SDTypography.titleSmall
                                                            .copyWith(
                                                                fontWeight:
                                                                    FontWeight.w700),
                                                      ),
                                                      Text(
                                                        'Essayez un autre filtre ou une autre recherche.',
                                                        textAlign: TextAlign.center,
                                                        style: SDTypography.bodySmall
                                                            .copyWith(
                                                                color: SDColors
                                                                    .neutral500),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                padding: EdgeInsets.only(
                                                    bottom: SDSpacing.sm),
                                                itemCount: filtered.length,
                                                itemBuilder: (context, index) {
                                                  final conversation =
                                                      filtered[index];
                                                  final isSelected = state
                                                          .selectedConversation
                                                          ?.id ==
                                                      conversation.id;
                                                  return _buildInboxConversationRow(
                                                    conversation,
                                                    isSelected: isSelected,
                                                  );
                                                },
                                              ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Zone de messages (affichée uniquement si une conversation est sélectionnée sur mobile)
                    if (showConversation)
                      Flexible(
                        flex: 7,
                        child: AnimatedContainer(
                          duration: SDAnimations.medium,
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: SDColors.neutral900.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: state.selectedConversation == null
                              ? Center(
                                  child: Text('Sélectionnez une conversation'))
                              : AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: state.selectedConversation != null
                                      ? 1.0
                                      : 0.0,
                                  child: Column(
                                    children: [
                                      // En-tête de la conversation
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 16.0),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey.shade300,
                                                image: state
                                                        .selectedConversation!
                                                        .participantImage
                                                        .isNotEmpty
                                                    ? DecorationImage(
                                                        image: AssetImage(state
                                                            .selectedConversation!
                                                            .participantImage),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: state.selectedConversation!
                                                      .participantImage.isEmpty
                                                  ? Center(
                                                      child: Text(
                                                        state
                                                            .selectedConversation!
                                                            .participantName[0]
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            // Nom et statut
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  state.selectedConversation!
                                                      .participantName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: state
                                                                .selectedConversation!
                                                                .isOnline
                                                            ? Colors.green
                                                            : Colors
                                                                .grey.shade400,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      state.selectedConversation!
                                                              .isOnline
                                                          ? 'En ligne'
                                                          : 'Hors ligne',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Liste des messages
                                      Expanded(
                                        child: state.messagesByConversation
                                                    .containsKey(state
                                                        .selectedConversation!
                                                        .id) &&
                                                state
                                                    .messagesByConversation[state
                                                        .selectedConversation!
                                                        .id]!
                                                    .isNotEmpty
                                            ? ListView.builder(
                                                controller: _scrollController,
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                itemCount: state
                                                    .messagesByConversation[state
                                                        .selectedConversation!
                                                        .id]!
                                                    .length,
                                                itemBuilder: (context, index) {
                                                  final message = state
                                                          .messagesByConversation[
                                                      state
                                                          .selectedConversation!
                                                          .id]![index];
                                                  final bool isMe = message
                                                          .senderId ==
                                                      _currentUserId;

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 12.0),
                                                    child: Row(
                                                      mainAxisAlignment: isMe
                                                          ? MainAxisAlignment
                                                              .end
                                                          : MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        // Avatar du participant (uniquement pour les messages reçus)
                                                        if (!isMe &&
                                                                index == 0 ||
                                                            !isMe &&
                                                                index > 0 &&
                                                                state
                                                                        .messagesByConversation[
                                                                            state.selectedConversation!.id]![
                                                                            index -
                                                                                1]
                                                                        .senderId ==
                                                                    _currentUserId)
                                                          Container(
                                                            width: 28,
                                                            height: 28,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors.grey
                                                                  .shade300,
                                                              image: state
                                                                      .selectedConversation!
                                                                      .participantImage
                                                                      .isNotEmpty
                                                                  ? DecorationImage(
                                                                      image: AssetImage(state
                                                                          .selectedConversation!
                                                                          .participantImage),
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    )
                                                                  : null,
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 1.5),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black12,
                                                                  blurRadius: 3,
                                                                  offset:
                                                                      Offset(
                                                                          0, 1),
                                                                ),
                                                              ],
                                                            ),
                                                            child: state
                                                                    .selectedConversation!
                                                                    .participantImage
                                                                    .isEmpty
                                                                ? Center(
                                                                    child: Text(
                                                                      state
                                                                          .selectedConversation!
                                                                          .participantName[
                                                                              0]
                                                                          .toUpperCase(),
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : null,
                                                          )
                                                        else if (!isMe)
                                                          SizedBox(
                                                              width:
                                                                  36), // Espacement pour aligner les messages

                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14.0,
                                                                  vertical:
                                                                      10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isMe
                                                                ? Color(
                                                                    0xFFE6F8E6)
                                                                : Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(
                                                                      18.0),
                                                              topRight: Radius
                                                                  .circular(
                                                                      18.0),
                                                              bottomLeft: isMe
                                                                  ? Radius
                                                                      .circular(
                                                                          18.0)
                                                                  : Radius
                                                                      .circular(
                                                                          4.0),
                                                              bottomRight: isMe
                                                                  ? Radius
                                                                      .circular(
                                                                          4.0)
                                                                  : Radius
                                                                      .circular(
                                                                          18.0),
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.05),
                                                                blurRadius: 3,
                                                                offset: Offset(
                                                                    0, 1),
                                                              ),
                                                            ],
                                                            border: Border.all(
                                                                color: isMe
                                                                    ? Colors
                                                                        .green
                                                                        .shade100
                                                                    : Colors
                                                                        .grey
                                                                        .shade200,
                                                                width: 1),
                                                          ),
                                                          constraints:
                                                              BoxConstraints(
                                                            maxWidth: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.65,
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: isMe
                                                                ? CrossAxisAlignment
                                                                    .end
                                                                : CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                message.content,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 15,
                                                                  color: isMe
                                                                      ? Colors
                                                                          .black87
                                                                      : Colors
                                                                          .black87,
                                                                  height: 1.3,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    _formatMessageTime(
                                                                        message
                                                                            .timestamp),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (isMe) ...[
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Icon(
                                                                      message.status ==
                                                                              MessageStatus.seen
                                                                          ? Icons.done_all
                                                                          : message.status == MessageStatus.delivered
                                                                              ? Icons.done_all
                                                                              : message.status == MessageStatus.sent
                                                                                  ? Icons.done
                                                                                  : Icons.access_time,
                                                                      size: 14,
                                                                      color: message.status ==
                                                                              MessageStatus
                                                                                  .seen
                                                                          ? Colors
                                                                              .blue
                                                                          : Colors
                                                                              .grey,
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Text('Aucun message')),
                                      ),
                                      // Zone de saisie
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (state.partnerTyping)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 4),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: Text(
                                                  'en train d\'écrire…',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (_selectedImage != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 8, 12, 0),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.file(
                                                      _selectedImage!,
                                                      height: 96,
                                                      width: 96,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close,
                                                          size: 18),
                                                      style: IconButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black54,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize:
                                                            const Size(
                                                                28, 28),
                                                      ),
                                                      onPressed: () =>
                                                          setState(() =>
                                                              _selectedImage =
                                                                  null),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            top: BorderSide(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Bouton photo du problème
                                            IconButton(
                                              icon: const Icon(Icons.image_outlined),
                                              tooltip: 'Photo du problème',
                                              onPressed: _pickImage,
                                            ),
                                            // Bouton vocal
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              child: VoiceRecorderWidget(
                                                onSend: (audioFile, duration) {
                                                  final conv = _chatBloc.state.selectedConversation;
                                                  if (conv == null) return;
                                                  _chatBloc.add(SendAudioMessage(
                                                    conversationId: conv.id,
                                                    audioFile: audioFile,
                                                    dureeFichier: duration,
                                                  ));
                                                },
                                              ),
                                            ),
                                            // Champ de texte
                                            Expanded(
                                              child: TextField(
                                                controller: _messageController,
                                                focusNode: _focusNode,
                                                onChanged: _onMessageChanged,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Message (optionnel)',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      Colors.grey.shade100,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16.0,
                                                          vertical: 8.0),
                                                ),
                                              ),
                                            ),
                                            // Bouton d'envoi texte
                                            IconButton(
                                              icon: Icon(Icons.send,
                                                  color: Colors.green),
                                              onPressed: _sendMessage,
                                            ),
                                          ],
                                        ),
                                      ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ), // Column
            ), // SafeArea
          ); // Scaffold
        },
    ); // BlocConsumer
  }

  Widget _buildStyledCategoryItem(
      String title, String subtitle, String imagePath,
      {bool isPopular = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.green.withOpacity(0.07)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(imagePath),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTapDown: (_) => setState(() => _arrowPressed = true),
                        onTapUp: (_) => setState(() => _arrowPressed = false),
                        onTapCancel: () =>
                            setState(() => _arrowPressed = false),
                        child: AnimatedScale(
                          scale: _arrowPressed ? 1.15 : 1.0,
                          duration: Duration(milliseconds: 120),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF43EA5E), Color(0xFF1CBF3F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isPopular)
                Positioned(
                  top: 10,
                  right: 10,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Populaire',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledProviderItem(String name, String price, String imagePath,
      {bool isPopular = false, required int index}) {
    final bool pressed = _prestatairePressed == index;
    return AnimatedScale(
      scale: pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _prestatairePressed = index),
        onTapUp: (_) => setState(() => _prestatairePressed = -1),
        onTapCancel: () => setState(() => _prestatairePressed = -1),
        child: Container(
          width: 120,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.10),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              if (isPopular)
                BoxShadow(
                  color: Colors.orange.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              splashColor: Colors.green.withOpacity(0.08),
              onTap: () {},
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: isPopular
                              ? BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.25),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(imagePath),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          price,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (isPopular)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Populaire',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledNavButton(String label, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {},
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF43EA5E), Color(0xFF1CBF3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.18),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.transparent,
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSearchBar extends StatefulWidget {
  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  bool _focused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _focused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focused ? 1.035 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: _focused ? Colors.green : Colors.green.shade200,
              width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(_focused ? 0.13 : 0.07),
              blurRadius: _focused ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Material(
              color: Colors.green,
              shape: const CircleBorder(),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child:
                    Icon(Icons.search_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 16),
                cursorColor: Colors.green,
                decoration: InputDecoration(
                  hintText: 'Rechercher sur soutralideals',
                  hintStyle: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
