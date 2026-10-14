import '../../../../data/services/authCubit.dart';
import '../../../../data/services/protected_action_intent.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../data/utils/network_user_message.dart';
import '../../../../design_system/design_system.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../common/auth_completion.dart';
import '../../searchpagem/screens/searchPageScreenM.dart';
import '../chatpageblocm/chatPageBlocM.dart';
import '../chatpageblocm/chatPageEventM.dart';
import '../chatpageblocm/chatPageStateM.dart';
import '../widgets/conversation_thread_widgets.dart';
import '../widgets/voice_recorder_widget.dart';
import '../../jobpagem/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/session_guest_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
  String? _pendingOutboundDraft;

  late ChatPageBlocM _chatBloc;
  String _currentUserId = '';

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

  String _inboxContextLine(ConversationModel conversation) {
    final category = _getInboxCategoryLabel(conversation.type);
    final topic = cleanDisplayPart(conversation.contextLabel);
    if (topic == null) return category;
    return '$category · $topic';
  }

  String _inboxPreviewSnippet(ConversationModel conversation) {
    final msg = conversation.lastMessage;
    if (msg == null) return 'Aucun message';
    switch (msg.type) {
      case MessageType.audio:
        final sec = msg.dureeFichier ?? 0;
        final m = (sec ~/ 60).toString();
        final s = (sec % 60).toString().padLeft(2, '0');
        return 'Message vocal · $m:$s';
      case MessageType.image:
        return 'Photo';
      case MessageType.text:
        final text = msg.content.trim();
        if (text.isEmpty) return 'Aucun message';
        if (msg.senderId == _currentUserId) {
          return 'Vous : $text';
        }
        return text;
    }
  }

  int _unreadConversationsCount(List<ConversationModel> conversations) {
    return conversations.where((c) => c.unreadCount > 0).length;
  }

  Widget _buildConversationsSectionHeader(List<ConversationModel> filtered) {
    final unreadRows = _unreadConversationsCount(filtered);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            'Conversations',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const Spacer(),
          if (unreadRows > 0)
            Text(
              '$unreadRows non lue${unreadRows > 1 ? 's' : ''}',
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  /// Photo réseau / asset si dispo, sinon avatar initiales.
  Widget _buildConversationAvatar(ConversationModel conversation,
      {double radius = 26}) {
    final img = safeImageUrl(conversation.participantImage) ??
        (conversation.participantImage.startsWith('assets/')
            ? conversation.participantImage
            : '');
    final hasNetwork = safeImageUrl(conversation.participantImage) != null;
    final hasAsset = img.startsWith('assets/') &&
        img.isNotEmpty &&
        img != 'assets/profil.png';
    final name = displayOrFallback(conversation.participantName, 'Utilisateur');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final size = radius * 2;

    Widget initialsAvatar() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: SDColors.neutral200,
        child: Text(
          initial,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w700,
            fontSize: radius >= 24 ? null : 13,
          ),
        ),
      );
    }

    Widget avatar;
    if (hasNetwork) {
      avatar = ClipOval(
        child: Image.network(
          img,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => initialsAvatar(),
        ),
      );
    } else if (hasAsset) {
      avatar = CircleAvatar(
        radius: radius,
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
        if (conversation.isOnline && radius >= 20)
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
    final snippet = _inboxPreviewSnippet(conversation);

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
                              decoration: BoxDecoration(
                                color: SDColors.primary700,
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
                    _inboxContextLine(conversation),
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral800,
                      fontWeight: FontWeight.w400,
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

  List<ConversationModel> _filteredConversations(List<ConversationModel> all) {
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

  /// AppBar conversation mobile (fond mint, avatar, sous-titre service).
  PreferredSizeWidget _buildMobileConversationAppBar(ChatPageStateM state) {
    final conv = state.selectedConversation!;
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Material(
        color: SDColors.primary50,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: SDColors.neutral900,
                  size: 20,
                ),
                onPressed: () {
                  context.read<ChatPageBlocM>().add(const LoadConversations());
                },
              ),
              _buildConversationAvatar(conv, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.participantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _conversationThreadSubtitle(conv),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.phone_outlined, color: SDColors.neutral800),
                onPressed: () {},
                tooltip: 'Appeler',
              ),
              IconButton(
                icon: Icon(Icons.more_vert_rounded, color: SDColors.neutral800),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _conversationThreadSubtitle(ConversationModel conversation) {
    final ctx = cleanDisplayPart(conversation.contextLabel);
    if (ctx != null && ctx.isNotEmpty) return ctx;
    return _getConversationLabel(conversation.type);
  }

  void _onServiceContextBannerTap(ConversationModel conversation) {
    if (conversation.type == ConversationType.prestataire) {
      NavigationHelper.navigateToProviderProfile(
        context,
        providerId: conversation.participantId,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profil bientôt disponible pour ce contact.')),
    );
  }

  Widget _buildDesktopConversationHeader(ChatPageStateM state) {
    final conv = state.selectedConversation!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: SDColors.neutral200)),
      ),
      child: Row(
        children: [
          _buildConversationAvatar(conv, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.participantName,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conv.isOnline
                            ? SDColors.success500
                            : SDColors.neutral400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      conv.isOnline ? 'En ligne' : 'Hors ligne',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationMessagesList(ChatPageStateM state) {
    final conv = state.selectedConversation!;
    final messages = state.messagesByConversation[conv.id] ?? const [];

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Aucun message',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _currentUserId;
        final showDateHeader = index == 0 ||
            !conversationSameDay(
              messages[index - 1].timestamp,
              message.timestamp,
            );
        final showPeerAvatar = !isMe &&
            (index == 0 || messages[index - 1].senderId == _currentUserId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader)
              ConversationDateSeparator(
                label: conversationDateSeparatorLabel(message.timestamp),
              ),
            ConversationMessageTile(
              message: message,
              isMe: isMe,
              showPeerAvatar: showPeerAvatar,
              peerAvatar: _buildConversationAvatar(conv, radius: 14),
              onRetry: isMe && message.status == MessageStatus.failed
                  ? () => _chatBloc.add(RetrySendMessage(
                        conversationId: conv.id,
                        messageId: message.id,
                      ))
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationComposer(ChatPageStateM state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.partnerTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'en train d\'écrire…',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
          decoration: BoxDecoration(
            color: SDColors.white,
            border: Border(top: BorderSide(color: SDColors.neutral200)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon:
                    Icon(Icons.add_circle_outline, color: SDColors.neutral700),
                tooltip: 'Pièce jointe',
                onPressed: _pickImage,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: SDColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SDColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          onChanged: _onMessageChanged,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Votre message…',
                            hintStyle: SDTypography.bodyMedium.copyWith(
                              color: SDColors.neutral400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral900,
                          ),
                        ),
                      ),
                      VoiceRecorderWidget(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: SDColors.primary700,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: SDColors.white),
                  onPressed: _sendMessage,
                  tooltip: 'Envoyer',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpenConversationPanel(ChatPageStateM state, bool isMobile) {
    final conv = state.selectedConversation!;
    return Column(
      children: [
        if (!isMobile) _buildDesktopConversationHeader(state),
        if (isMobile) ...[
          ConversationServiceContextBanner(
            conversation: conv,
            onTap: () => _onServiceContextBannerTap(conv),
          ),
          Divider(height: 1, color: SDColors.neutral200),
        ],
        Expanded(child: _buildConversationMessagesList(state)),
        _buildConversationComposer(state),
      ],
    );
  }

  /// Titre page aligné comme Profil (gauche, gros).
  Widget _buildMessagesTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Messagerie',
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
            icon:
                Icon(Icons.edit_rounded, color: SDColors.primary700, size: 22),
            tooltip: 'Nouveau message',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// Barre de recherche inbox (blanc, bordure neutre — alignée Explorer / recherche).
  Widget _buildExplorerStyleInboxSearch(BuildContext context) {
    final hasQuery = _listSearchController.text.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: SDColors.neutral600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _listSearchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              cursorColor: SDColors.primary600,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation',
                hintStyle: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral500,
                  fontSize: 14,
                ),
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          if (hasQuery)
            IconButton(
              onPressed: () {
                _listSearchController.clear();
                setState(() {});
                FocusScope.of(context).unfocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon:
                  const Icon(Icons.close, size: 18, color: SDColors.neutral500),
              tooltip: 'Effacer',
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip({
      required String label,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? SDColors.primary700 : SDColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? SDColors.primary700 : SDColors.primary100,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral700,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
            value: _MessagesInboxFilter.tous,
          ),
          chip(
            label: 'Travaux',
            value: _MessagesInboxFilter.travaux,
          ),
          chip(
            label: 'Freelance',
            value: _MessagesInboxFilter.freelance,
          ),
          chip(
            label: 'Produits',
            value: _MessagesInboxFilter.produits,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatBloc = BlocProvider.of<ChatPageBlocM>(context);

    // Source de vérité : AuthCubit — synchroniser AVANT LoadConversations.
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final id = authState.utilisateur.idutilisateur.trim();
      if (id.isNotEmpty) {
        _currentUserId = id;
        _chatBloc.setUserId(id);
      }
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🔌 Déconnecter le WebSocket
    _chatBloc.add(DisconnectWebSocket());

    _messageController.dispose();
    _listSearchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final current = _chatBloc.state;
    if (current.status != ChatPageStatus.error) return;
    _chatBloc.add(const LoadConversations());
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
        _pendingOutboundDraft = _messageController.text.trim();
        _chatBloc.add(SendMessage(
          conversationId: convId,
          content: _messageController.text.trim(),
          type: MessageType.image,
          imageFile: _selectedImage,
        ));
        setState(() => _selectedImage = null);
      } else {
        _pendingOutboundDraft = _messageController.text.trim();
        _chatBloc.add(SendMessage(
          conversationId: convId,
          content: _messageController.text.trim(),
          type: MessageType.text,
        ));
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

  Widget _buildConversationPane(
    ChatPageStateM state,
    List<ConversationModel> filtered,
  ) {
    final waiting = state.status == ChatPageStatus.initial ||
        state.status == ChatPageStatus.loading;
    if (waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.conversations.isEmpty && state.status == ChatPageStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SDSectionNeedsConnection(
            detail: 'La messagerie n’a pas de conversation enregistrée ici.',
            onRetry: () =>
                context.read<ChatPageBlocM>().add(const LoadConversations()),
          ),
        ),
      );
    }

    if (state.conversations.isEmpty && state.status == ChatPageStatus.loaded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SDIllustration(
                        asset: SDIllustrations.messagesEmptyConnected,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Aucune conversation pour le moment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Contactez un professionnel pour commencer à échanger.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF757575),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: SDColors.neutral400,
              ),
              SizedBox(height: SDSpacing.sm),
              Text(
                'Aucun résultat',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Essayez un autre filtre ou une autre recherche.',
                textAlign: TextAlign.center,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = ListView.builder(
      padding: EdgeInsets.only(bottom: SDSpacing.sm),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final conversation = filtered[index];
        final isSelected = state.selectedConversation?.id == conversation.id;
        return _buildInboxConversationRow(
          conversation,
          isSelected: isSelected,
        );
      },
    );
    final notice = state.error ?? '';
    if (notice.isEmpty) return list;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SDOfflineSavedBanner(
            offline: homeBannerLooksOffline(notice),
          ),
        ),
        Expanded(child: list),
      ],
    );
  }

  // 🔐 Écran invité — mur d'authentification (≠ empty inbox connecté)
  Widget _buildNotAuthenticatedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: SessionGuestGate(
          guestBuilder: (context) => GuestAuthState(
          pageTitle: 'Messagerie',
          title: 'Connectez-vous pour accéder à vos messages',
          description:
              'Discutez directement avec les prestataires, freelances et vendeurs.',
          illustration: const SDIllustration(
            asset: SDIllustrations.messagesGuest,
          ),
          onPrimary: () {
            pushAuthForPendingAction(
              context: context,
              type: ProtectedActionType.startConversation,
              originRoute: 'chat',
              route: '/login',
            );
          },
          onSecondary: () {
            pushAuthForPendingAction(
              context: context,
              type: ProtectedActionType.startConversation,
              originRoute: 'chat',
              route: '/register',
            );
          },
        ),
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
        if (_pendingOutboundDraft != null &&
            state.selectedConversation != null) {
          final convId = state.selectedConversation!.id;
          final messages = state.messagesByConversation[convId];
          if (messages != null && messages.isNotEmpty) {
            for (var i = messages.length - 1; i >= 0; i--) {
              final m = messages[i];
              if (m.senderId != _currentUserId) continue;
              if (m.content != _pendingOutboundDraft) continue;
              if (m.status == MessageStatus.failed) {
                _messageController.text = _pendingOutboundDraft!;
              } else if (m.status != MessageStatus.sending) {
                _messageController.clear();
              }
              if (m.status != MessageStatus.sending) {
                _pendingOutboundDraft = null;
              }
              break;
            }
          }
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
              ? _buildMobileConversationAppBar(state)
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
                  _buildConversationsSectionHeader(filtered),
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
                              borderRadius: BorderRadius.circular(
                                  SDSpacing.borderRadiusXLarge),
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
                                  child: _buildConversationPane(
                                    state,
                                    filtered,
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
                              borderRadius: BorderRadius.circular(
                                  SDSpacing.borderRadiusLarge),
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
                                    child:
                                        Text('Sélectionnez une conversation'))
                                : AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: state.selectedConversation != null
                                        ? 1.0
                                        : 0.0,
                                    child: _buildOpenConversationPanel(
                                        state, isMobile),
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
