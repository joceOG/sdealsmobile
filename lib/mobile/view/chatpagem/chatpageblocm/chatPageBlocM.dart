import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageEventM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageStateM.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';
import 'package:sdealsmobile/data/services/notification_service.dart';
import 'package:sdealsmobile/data/utils/conversation_id.dart';
import 'dart:io';

class ChatPageBlocM extends Bloc<ChatPageEventM, ChatPageStateM> {
  final ApiClient _apiClient;
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();

  /// ID utilisateur — source de vérité côté UI : [AuthCubit] via [setUserId].
  String _currentUserId;
  final _uuid = const Uuid();

  /// Load demandé avant que l'id soit connu → relancer dès [setUserId].
  bool _pendingLoadConversations = false;

  /// Test-only : remplace [ApiClient.getConversations] sans réseau.
  final Future<List<Map<String, dynamic>>> Function(String userId)?
      _conversationsLoader;

  ChatPageBlocM({
    String? userId,
    ApiClient? apiClient,
    Future<List<Map<String, dynamic>>> Function(String userId)?
        conversationsLoader,
  })  : _apiClient = apiClient ?? ApiClient(),
        _conversationsLoader = conversationsLoader,
        _currentUserId = userId?.trim() ?? '',
        super(ChatPageStateM.initial()) {
    on<LoadConversations>(_onLoadConversations);
    on<SelectConversation>(_onSelectConversation);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<SendAudioMessage>(_onSendAudioMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<CreateConversation>(_onCreateConversation);
    on<SearchConversations>(_onSearchConversations);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
    on<SendChatNotification>(_onSendChatNotification);
    on<ChatNotificationReceived>(_onChatNotificationReceived);
    on<SearchMessages>(_onSearchMessages);
    on<DeleteMessage>(_onDeleteMessage);
    on<PartnerTypingChanged>(_onPartnerTypingChanged);
    on<EmitTyping>(_onEmitTyping);

    // Gardons la compatibilité avec le code existant
    on<LoadCategorieDataM>(_onLoadCategorieDataM);

    // Configuration des callbacks WebSocket
    _setupWebSocketCallbacks();
  }

  /// Met à jour l'ID utilisateur (AuthCubit). Relance un load en attente.
  void setUserId(String id) {
    final normalized = id.trim();
    _currentUserId = normalized;

    if (normalized.isNotEmpty && _pendingLoadConversations) {
      _pendingLoadConversations = false;
      add(const LoadConversations());
    }
  }

  /// Exposé pour tests / diagnostics.
  @visibleForTesting
  String get debugCurrentUserId => _currentUserId;

  @visibleForTesting
  bool get debugPendingLoadConversations => _pendingLoadConversations;

  // Ajouté pour la compatibilité avec le code existant
  Future<void> _onLoadCategorieDataM(
      LoadCategorieDataM event, Emitter<ChatPageStateM> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      var nomgroupe = "Métiers";
      List<Categorie> list_categorie =
          await _apiClient.fetchCategorie(nomgroupe);
      emit(state.copyWith(listItems: list_categorie, isLoading: false));
    } catch (error) {
      emit(state.copyWith(error: error.toString(), isLoading: false));
    }
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ChatPageStateM> emit) async {
    // Auth pas encore synchronisée : attendre setUserId — ne jamais faux « non connecté ».
    if (_currentUserId.isEmpty) {
      _pendingLoadConversations = true;
      emit(state.copyWith(
        status: ChatPageStatus.loading,
        error: '',
      ));
      return;
    }

    _pendingLoadConversations = false;
    emit(state.copyWith(status: ChatPageStatus.loading, error: ''));

    try {
      if (kDebugMode) {
        print('🔄 Chargement conversations depuis API...');
      }
      final conversationsData = _conversationsLoader != null
          ? await _conversationsLoader!(_currentUserId)
          : await _apiClient.getConversations(_currentUserId);

      final conversations = conversationsData
          .map((data) => ConversationModel.fromBackend(data, _currentUserId))
          .toList();

      if (kDebugMode) {
        print('✅ ${conversations.length} conversations chargées depuis API');
      }

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        conversations: conversations,
        clearSelectedConversation: true,
        error: '',
      ));
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error loading conversations: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
        conversations: const [],
      ));
    }
  }

  Future<void> _onSelectConversation(
      SelectConversation event, Emitter<ChatPageStateM> emit) async {
    emit(state.copyWith(
      selectedConversation: event.conversation,
    ));

    // Automatiquement charger les messages lorsqu'une conversation est sélectionnée
    add(LoadMessages(event.conversation.id));

    // Marquer la conversation comme lue
    if (event.conversation.unread) {
      add(MarkConversationAsRead(event.conversation.id));
    }
  }

  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<ChatPageStateM> emit) async {
    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      print(
          '🔄 Chargement messages API pour conversation: ${event.conversationId}');
      final messagesData = await _apiClient.getConversationMessages(
        event.conversationId,
        userId: _currentUserId,
      );

      final messages =
          messagesData.map((data) => MessageModel.fromBackend(data)).toList();

      print('✅ ${messages.length} messages chargés depuis API');

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = messages;

      // Sélectionner la conversation si absente (deep-link /chat/:id)
      ConversationModel? selected = state.selectedConversation;
      if (selected == null || selected.id != event.conversationId) {
        selected = state.conversations.cast<ConversationModel?>().firstWhere(
              (c) => c?.id == event.conversationId,
              orElse: () => null,
            );
        if (selected == null) {
          final otherId =
              getOtherParticipantId(event.conversationId, _currentUserId) ??
                  '';
          selected = ConversationModel(
            id: event.conversationId,
            userId: _currentUserId,
            participantId: otherId,
            participantName: 'Conversation',
            participantImage: 'assets/images/default_user.png',
            lastUpdated: DateTime.now(),
            type: ConversationType.prestataire,
          );
        }
      }

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        messagesByConversation: updatedMessagesMap,
        selectedConversation: selected,
        partnerTyping: false,
      ));

      if (_webSocketService.isConnected) {
        _webSocketService.joinConversation(event.conversationId);
      }
      add(MarkConversationAsRead(event.conversationId));
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error loading messages: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatPageStateM> emit) async {
    if (state.selectedConversation == null) return;

    try {
      // Créer un nouveau message avec un ID temporaire
      final imageFile = event.imageFile is File ? event.imageFile as File : null;
      final newMessage = MessageModel(
        id: _uuid.v4(),
        senderId: _currentUserId,
        receiverId: state.selectedConversation!.participantId,
        timestamp: DateTime.now(),
        content: event.content,
        type: event.type,
        status: MessageStatus.sending,
      );

      // Ajouter immédiatement le message à l'UI pour un feedback instantané
      final currentMessages = state.selectedConversationMessages;
      final updatedMessages = List<MessageModel>.from(currentMessages)
        ..add(newMessage);

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = updatedMessages;

      // Mettre à jour également la dernière conversation
      final updatedConversation = state.selectedConversation!.copyWith(
        lastMessage: newMessage,
        lastUpdated: DateTime.now(),
        unread: false,
      );

      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == updatedConversation.id) {
          return updatedConversation;
        }
        return conv;
      }).toList();

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
        conversations: updatedConversations,
        selectedConversation: updatedConversation,
      ));

      // 🔄 Envoi API (texte ou image) — pas de simulation
      MessageModel sentMessage;
      try {
        print('🔄 Envoi message via API...');
        final responseData = await _apiClient.sendMessage(
          expediteur: _currentUserId,
          destinataire: state.selectedConversation!.participantId,
          contenu: imageFile != null
              ? (event.content.trim().isEmpty ? 'Image' : event.content)
              : event.content,
          pieceJointe: imageFile,
          typePieceJointe: imageFile != null ? 'IMAGE' : null,
        );

        sentMessage = MessageModel.fromBackend(responseData);
        print('✅ Message envoyé via API avec ID: ${sentMessage.id}');

        // Typing stop après envoi
        _webSocketService.stopTyping(
          event.conversationId,
          userId: _currentUserId,
        );
      } catch (apiError) {
        print('❌ Échec envoi message: $apiError');
        final failedMessages = updatedMessages.map((msg) {
          if (msg.id == newMessage.id) {
            return msg.copyWith(newStatus: MessageStatus.failed);
          }
          return msg;
        }).toList();
        updatedMessagesMap[event.conversationId] = failedMessages;
        emit(state.copyWith(
          messagesByConversation: updatedMessagesMap,
          error: apiError.toString(),
        ));
        return;
      }

      // Mettre à jour les messages avec le message envoyé
      final finalMessages = updatedMessages.map((msg) {
        if (msg.id == newMessage.id) {
          return sentMessage;
        }
        return msg;
      }).toList();

      updatedMessagesMap[event.conversationId] = finalMessages;

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));
    } catch (error) {
      if (kDebugMode) {
        print('Error sending message: $error');
      }

      // Mettre à jour le message avec le statut d'échec
      final updatedMessages = state.selectedConversationMessages.map((msg) {
        if (msg.status == MessageStatus.sending) {
          return msg.copyWith(newStatus: MessageStatus.failed);
        }
        return msg;
      }).toList();

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = updatedMessages;

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
        error: error.toString(),
      ));
    }
  }

  Future<void> _onSendAudioMessage(
      SendAudioMessage event, Emitter<ChatPageStateM> emit) async {
    if (state.selectedConversation == null) return;
    final audioFile = event.audioFile is File ? event.audioFile as File : null;
    if (audioFile == null) return;

    final tempMessage = MessageModel(
      id: _uuid.v4(),
      senderId: _currentUserId,
      receiverId: state.selectedConversation!.participantId,
      timestamp: DateTime.now(),
      content: '🎤 Message vocal',
      type: MessageType.audio,
      status: MessageStatus.sending,
      dureeFichier: event.dureeFichier,
    );

    final currentMessages = state.selectedConversationMessages;
    final updatedMessages = List<MessageModel>.from(currentMessages)
      ..add(tempMessage);
    final updatedMessagesMap =
        Map<String, List<MessageModel>>.from(state.messagesByConversation);
    updatedMessagesMap[event.conversationId] = updatedMessages;

    emit(state.copyWith(messagesByConversation: updatedMessagesMap));

    try {
      final responseData = await _apiClient.sendMessage(
        expediteur: _currentUserId,
        destinataire: state.selectedConversation!.participantId,
        pieceJointe: audioFile,
        typePieceJointe: 'AUDIO',
        dureeFichier: event.dureeFichier,
      );
      final sentMessage = MessageModel.fromBackend(responseData);
      final finalMessages = updatedMessages.map((msg) {
        return msg.id == tempMessage.id ? sentMessage : msg;
      }).toList();
      updatedMessagesMap[event.conversationId] = finalMessages;
      emit(state.copyWith(messagesByConversation: updatedMessagesMap));
    } catch (e) {
      final failedMessages = updatedMessages.map((msg) {
        return msg.id == tempMessage.id
            ? msg.copyWith(newStatus: MessageStatus.failed)
            : msg;
      }).toList();
      updatedMessagesMap[event.conversationId] = failedMessages;
      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onMarkMessageAsRead(
      MarkMessageAsRead event, Emitter<ChatPageStateM> emit) async {
    try {
      await _apiClient.markMessagesAsRead(
          event.conversationId, _currentUserId);

      if (!state.messagesByConversation.containsKey(event.conversationId)) {
        return;
      }

      final updatedMessages =
          state.messagesByConversation[event.conversationId]!.map((msg) {
        if (msg.id == event.messageId ||
            (msg.receiverId == _currentUserId &&
                msg.status != MessageStatus.seen)) {
          return msg.copyWith(newStatus: MessageStatus.seen);
        }
        return msg;
      }).toList();

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = updatedMessages;

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));
    } catch (error) {
      if (kDebugMode) {
        print('Error marking message as read: $error');
      }
    }
  }

  Future<void> _onMarkConversationAsRead(
      MarkConversationAsRead event, Emitter<ChatPageStateM> emit) async {
    try {
      // 🔄 Tenter d'appeler l'API backend
      try {
        print(
            '🔄 Marquage conversation comme lue via API: ${event.conversationId}');
        await _apiClient.markMessagesAsRead(
            event.conversationId, _currentUserId);
        print('✅ Conversation marquée comme lue via API');
      } catch (apiError) {
        print('⚠️ API mark-as-read échouée: $apiError');
        // Pas de faux succès silencieux : on propage l'erreur
        emit(state.copyWith(error: 'Marquage lu impossible: $apiError'));
        return;
      }

      // Mettre à jour la conversation localement
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return conv.copyWith(unread: false, unreadCount: 0);
        }
        return conv;
      }).toList();

      // Mettre à jour les messages de la conversation
      if (state.messagesByConversation.containsKey(event.conversationId)) {
        final messages = state.messagesByConversation[event.conversationId]!;
        final updatedMessages = messages.map((msg) {
          if (msg.receiverId == _currentUserId &&
              msg.status != MessageStatus.seen) {
            return msg.copyWith(newStatus: MessageStatus.seen);
          }
          return msg;
        }).toList();

        final updatedMessagesMap =
            Map<String, List<MessageModel>>.from(state.messagesByConversation);
        updatedMessagesMap[event.conversationId] = updatedMessages;

        emit(state.copyWith(
          conversations: updatedConversations,
          messagesByConversation: updatedMessagesMap,
          selectedConversation:
              state.selectedConversation?.id == event.conversationId
                  ? state.selectedConversation!
                      .copyWith(unread: false, unreadCount: 0)
                  : null,
        ));
      } else {
        emit(state.copyWith(
          conversations: updatedConversations,
          selectedConversation:
              state.selectedConversation?.id == event.conversationId
                  ? state.selectedConversation!
                      .copyWith(unread: false, unreadCount: 0)
                  : null,
        ));
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error marking conversation as read: $error');
      }
    }
  }

  Future<void> _onCreateConversation(
      CreateConversation event, Emitter<ChatPageStateM> emit) async {
    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      // Vérifier si une conversation existe déjà avec ce participant
      final existingConversation = state.conversations.firstWhere(
        (conv) => conv.participantId == event.participantId,
        orElse: () => ConversationModel(
          id: '',
          userId: '',
          participantId: '',
          participantName: '',
          participantImage: '',
          lastUpdated: DateTime.now(),
          type: ConversationType.prestataire,
        ),
      );

      if (existingConversation.id.isNotEmpty) {
        // Conversation existante trouvée, la sélectionner
        emit(state.copyWith(
          status: ChatPageStatus.loaded,
          selectedConversation: existingConversation,
        ));
        add(LoadMessages(existingConversation.id));
        return;
      }

      // Créer une conversation avec ID déterministe (aligné web/backend)
      final conversationId =
          buildConversationId(_currentUserId, event.participantId);

      final newConversation = ConversationModel(
        id: conversationId,
        userId: _currentUserId,
        participantId: event.participantId,
        participantName: event.participantName,
        participantImage: event.participantImage,
        lastUpdated: DateTime.now(),
        type: event.type,
        unread: false,
        unreadCount: 0,
        isOnline: false,
      );

      final alreadyListed =
          state.conversations.any((c) => c.id == conversationId);
      final updatedConversations = alreadyListed
          ? state.conversations
          : [newConversation, ...state.conversations];

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        conversations: updatedConversations,
        selectedConversation: newConversation,
      ));

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap.putIfAbsent(newConversation.id, () => []);

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));

      if (_webSocketService.isConnected) {
        _webSocketService.joinConversation(conversationId);
      }

      // Charger l'historique s'il existe déjà côté serveur
      add(LoadMessages(conversationId));
    } catch (error) {
      if (kDebugMode) {
        print('Error creating conversation: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
      ));
    }
  }

  Future<void> _onSearchConversations(
      SearchConversations event, Emitter<ChatPageStateM> emit) async {
    if (event.query.isEmpty) {
      add(const LoadConversations());
      return;
    }

    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      final lowercaseQuery = event.query.toLowerCase();
      final filteredConversations = state.conversations.where((conv) {
        return conv.participantName.toLowerCase().contains(lowercaseQuery) ||
            (conv.lastMessage?.content.toLowerCase().contains(lowercaseQuery) ??
                false);
      }).toList();

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        conversations: filteredConversations,
      ));
    } catch (error) {
      if (kDebugMode) {
        print('Error searching conversations: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
      ));
    }
  }

  // 🔌 CONFIGURATION DES CALLBACKS WEBSOCKET
  void _setupWebSocketCallbacks() {
    _webSocketService.onNewMessage((data) {
      add(NewMessageReceived(Map<String, dynamic>.from(
          data is Map ? data as Map : {'raw': data})));
    });

    _webSocketService.onMessageNotification((data) {
      print('🔔 Notification message reçue: $data');
    });

    _webSocketService.onUserTyping((data) {
      try {
        final map = Map<String, dynamic>.from(
            data is Map ? data as Map : <String, dynamic>{});
        final conversationId = map['conversationId']?.toString() ?? '';
        final typingUserId = map['userId']?.toString() ?? '';
        final isTyping = map['isTyping'] == true;
        if (conversationId.isEmpty) return;
        if (typingUserId == _currentUserId) return;
        add(PartnerTypingChanged(
          conversationId: conversationId,
          isTyping: isTyping,
        ));
      } catch (_) {}
    });

    _webSocketService.onMessageError((error) {
      print('❌ Erreur message WebSocket: $error');
    });
  }

  // 🔌 CONNEXION WEBSOCKET
  Future<void> _onConnectWebSocket(
      ConnectWebSocket event, Emitter<ChatPageStateM> emit) async {
    try {
      await _webSocketService.authenticate(userId: _currentUserId);
      emit(state.copyWith(isWebSocketConnected: true));
      if (state.selectedConversation != null) {
        _webSocketService.joinConversation(state.selectedConversation!.id);
      }
    } catch (error) {
      emit(state.copyWith(
        isWebSocketConnected: false,
        error: 'Erreur connexion WebSocket: $error',
      ));
    }
  }

  Future<void> _onPartnerTypingChanged(
      PartnerTypingChanged event, Emitter<ChatPageStateM> emit) async {
    if (state.selectedConversation?.id != event.conversationId) return;
    emit(state.copyWith(partnerTyping: event.isTyping));
  }

  Future<void> _onEmitTyping(
      EmitTyping event, Emitter<ChatPageStateM> emit) async {
    if (!_webSocketService.isConnected) return;
    if (event.isTyping) {
      _webSocketService.startTyping(event.conversationId,
          userId: _currentUserId);
    } else {
      _webSocketService.stopTyping(event.conversationId,
          userId: _currentUserId);
    }
  }

  // 🔌 DÉCONNEXION WEBSOCKET — quitte la room, ne coupe pas le singleton
  Future<void> _onDisconnectWebSocket(
      DisconnectWebSocket event, Emitter<ChatPageStateM> emit) async {
    if (state.selectedConversation != null) {
      _webSocketService.leaveConversation(state.selectedConversation!.id);
    }
    emit(state.copyWith(isWebSocketConnected: false));
  }

  // 📨 NOUVEAU MESSAGE REÇU VIA WEBSOCKET
  Future<void> _onNewMessageReceived(
      NewMessageReceived event, Emitter<ChatPageStateM> emit) async {
    try {
      final messageData = event.messageData;

      // Créer le message à partir des données WebSocket
      final newMessage = MessageModel(
        id: messageData['_id'] ?? _uuid.v4(),
        senderId: messageData['expediteur']?.toString() ?? '',
        receiverId: messageData['destinataire']?.toString() ?? '',
        timestamp: DateTime.parse(
            messageData['createdAt'] ?? DateTime.now().toIso8601String()),
        content: messageData['contenu'] ?? '',
        type: MessageType.text, // À adapter selon le type
        status: MessageStatus.delivered,
      );

      final conversationId = messageData['conversationId'] ?? '';

      // Ajouter le message à la conversation
      final currentMessages =
          state.messagesByConversation[conversationId] ?? [];
      final updatedMessages = [...currentMessages, newMessage];

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[conversationId] = updatedMessages;

      // Mettre à jour la conversation avec le dernier message
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return conv.copyWith(
            lastMessage: newMessage,
            lastUpdated: newMessage.timestamp,
            unread: newMessage.receiverId == _currentUserId,
            unreadCount: newMessage.receiverId == _currentUserId
                ? (conv.unreadCount + 1)
                : conv.unreadCount,
          );
        }
        return conv;
      }).toList();

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
        conversations: updatedConversations,
      ));
    } catch (error) {
      print('❌ Erreur traitement nouveau message: $error');
    }
  }

  // 📊 MISE À JOUR STATUT MESSAGE
  Future<void> _onMessageStatusUpdated(
      MessageStatusUpdated event, Emitter<ChatPageStateM> emit) async {
    try {
      final conversationId = event.conversationId;
      final messageId = event.messageId;
      final newStatus = event.status;

      if (!state.messagesByConversation.containsKey(conversationId)) return;

      final updatedMessages =
          state.messagesByConversation[conversationId]!.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(newStatus: newStatus);
        }
        return msg;
      }).toList();

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[conversationId] = updatedMessages;

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));
    } catch (error) {
      print('❌ Erreur mise à jour statut message: $error');
    }
  }

  // 🔔 ENVOYER NOTIFICATION CHAT
  Future<void> _onSendChatNotification(
    SendChatNotification event,
    Emitter<ChatPageStateM> emit,
  ) async {
    try {
      final success = await _notificationService.notifyNewMessage(
        userId: event.userId,
        senderName: 'Vous',
        message: event.message,
        conversationId: 'current_conversation',
      );

      if (success) {
        print('✅ Notification chat envoyée avec succès');
      } else {
        print('❌ Échec envoi notification chat');
      }
    } catch (error) {
      print('❌ Erreur envoi notification chat: $error');
    }
  }

  // 🔔 NOTIFICATION CHAT REÇUE
  Future<void> _onChatNotificationReceived(
    ChatNotificationReceived event,
    Emitter<ChatPageStateM> emit,
  ) async {
    try {
      final notificationData = event.notificationData;
      final type = notificationData['type']?.toString() ?? '';

      print('🔔 Notification chat reçue: $type');

      // Traiter selon le type de notification
      switch (type) {
        case 'new_message':
          _handleNewMessageNotification(notificationData, emit);
          break;
        case 'message_status':
          _handleMessageStatusNotification(notificationData, emit);
          break;
        default:
          print('📱 Notification chat générique: $notificationData');
      }
    } catch (error) {
      print('❌ Erreur traitement notification chat: $error');
    }
  }

  // 📨 TRAITER NOTIFICATION NOUVEAU MESSAGE
  void _handleNewMessageNotification(
    Map<String, dynamic> data,
    Emitter<ChatPageStateM> emit,
  ) {
    final conversationId = data['conversationId']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? '';
    final message = data['message']?.toString() ?? '';

    print('📨 Nouveau message de $senderName: $message');

    // Mettre à jour les conversations avec le nouveau message
    final updatedConversations = state.conversations.map((conv) {
      if (conv.id == conversationId) {
        return conv.copyWith(
          unread: true,
          unreadCount: conv.unreadCount + 1,
          lastUpdated: DateTime.now(),
        );
      }
      return conv;
    }).toList();

    emit(state.copyWith(
      conversations: updatedConversations,
    ));
  }

  // 📊 TRAITER NOTIFICATION STATUT MESSAGE
  void _handleMessageStatusNotification(
    Map<String, dynamic> data,
    Emitter<ChatPageStateM> emit,
  ) {
    final messageId = data['messageId']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    final conversationId = data['conversationId']?.toString() ?? '';

    print('📊 Statut message $messageId mis à jour: $status');

    // Mettre à jour le statut du message
    if (state.messagesByConversation.containsKey(conversationId)) {
      final messages = state.messagesByConversation[conversationId]!;
      final updatedMessages = messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(newStatus: _parseMessageStatus(status));
        }
        return msg;
      }).toList();

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[conversationId] = updatedMessages;

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));
    }
  }

  // 🔄 PARSER LE STATUT DU MESSAGE
  MessageStatus _parseMessageStatus(String status) {
    switch (status.toLowerCase()) {
      case 'envoyé':
        return MessageStatus.sent;
      case 'livré':
        return MessageStatus.delivered;
      case 'lu':
        return MessageStatus.seen;
      case 'échec':
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  // 🧹 NETTOYAGE
  // 🔍 RECHERCHER DANS LES MESSAGES
  Future<void> _onSearchMessages(
      SearchMessages event, Emitter<ChatPageStateM> emit) async {
    if (event.query.isEmpty) {
      // Si la recherche est vide, recharger toutes les conversations
      add(const LoadConversations());
      return;
    }

    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      // 🔄 Tenter d'abord l'API backend
      try {
        print('🔍 Recherche messages via API: "${event.query}"');
        final messagesData =
            await _apiClient.searchMessages(_currentUserId, event.query);

        // Grouper les messages par conversation
        final Map<String, List<MessageModel>> messagesByConv = {};
        for (var data in messagesData) {
          final message = MessageModel.fromBackend(data);
          final convId = data['conversationId']?.toString() ?? '';

          if (!messagesByConv.containsKey(convId)) {
            messagesByConv[convId] = [];
          }
          messagesByConv[convId]!.add(message);
        }

        print(
            '✅ ${messagesData.length} messages trouvés dans ${messagesByConv.length} conversations');

        emit(state.copyWith(
          status: ChatPageStatus.loaded,
          messagesByConversation: messagesByConv,
        ));
      } catch (apiError) {
        // ⚠️ Fallback sur recherche locale si l'API échoue
        print('⚠️ API indisponible, recherche locale: $apiError');

        final query = event.query.toLowerCase();
        final filteredConversations = state.conversations.where((conv) {
          return conv.participantName.toLowerCase().contains(query) ||
              (conv.lastMessage?.content.toLowerCase().contains(query) ??
                  false);
        }).toList();

        print(
            '📦 ${filteredConversations.length} conversations trouvées localement');

        emit(state.copyWith(
          status: ChatPageStatus.loaded,
          conversations: filteredConversations,
        ));
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error searching messages: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
      ));
    }
  }

  // 🗑️ SUPPRIMER UN MESSAGE
  Future<void> _onDeleteMessage(
      DeleteMessage event, Emitter<ChatPageStateM> emit) async {
    try {
      // 🔄 Tenter d'abord l'API backend
      try {
        print('🗑️ Suppression message via API: ${event.messageId}');
        await _apiClient.deleteMessageForUser(event.messageId, _currentUserId);
        print('✅ Message supprimé via API');
      } catch (apiError) {
        // ⚠️ Fallback sur suppression locale si l'API échoue
        print('⚠️ API indisponible, suppression locale: $apiError');
      }

      // Supprimer le message localement
      if (!state.messagesByConversation.containsKey(event.conversationId)) {
        return;
      }

      final updatedMessages = state
          .messagesByConversation[event.conversationId]!
          .where((msg) => msg.id != event.messageId)
          .toList();

      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = updatedMessages;

      // Mettre à jour le dernier message de la conversation
      final lastMessage =
          updatedMessages.isNotEmpty ? updatedMessages.last : null;
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return conv.copyWith(
            lastMessage: lastMessage,
            lastUpdated: lastMessage?.timestamp ?? DateTime.now(),
          );
        }
        return conv;
      }).toList();

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
        conversations: updatedConversations,
      ));

      print('✅ Message supprimé localement');
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error deleting message: $error');
      }
      emit(state.copyWith(
        error: error.toString(),
      ));
    }
  }

  Future<void> close() {
    // Ne pas disposer le WebSocket singleton (partagé app-wide)
    _notificationService.dispose();
    return super.close();
  }
}
