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

class ChatPageBlocM extends Bloc<ChatPageEventM, ChatPageStateM> {
  final ApiClient _apiClient = ApiClient();
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  final String _currentUserId =
      'currentUser'; // À remplacer par l'ID réel de l'utilisateur connecté
  final _uuid = const Uuid();

  ChatPageBlocM() : super(ChatPageStateM.initial()) {
    on<LoadConversations>(_onLoadConversations);
    on<SelectConversation>(_onSelectConversation);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
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

    // Gardons la compatibilité avec le code existant
    on<LoadCategorieDataM>(_onLoadCategorieDataM);

    // Configuration des callbacks WebSocket
    _setupWebSocketCallbacks();
  }

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
    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      // Simulons une API call avec les données mockées
      await Future.delayed(const Duration(milliseconds: 500));

      // Dans un environnement réel, nous appellerions l'API ici
      // final List<ConversationModel> conversations = await _apiClient.getConversations(_currentUserId);
      final List<ConversationModel> conversations = mockConversations;

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        conversations: conversations,
        clearSelectedConversation: true,
      ));
    } catch (error) {
      if (kDebugMode) {
        print('Error loading conversations: $error');
      }
      emit(state.copyWith(
        status: ChatPageStatus.error,
        error: error.toString(),
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
    if (state.selectedConversation == null) return;

    emit(state.copyWith(status: ChatPageStatus.loading));

    try {
      // Simulons une API call avec les données mockées
      await Future.delayed(const Duration(milliseconds: 500));

      // Dans un environnement réel, nous appellerions l'API ici
      // final List<MessageModel> messages = await _apiClient.getMessages(
      //   event.conversationId,
      //   limit: event.limit,
      //   offset: event.offset,
      // );

      // Utilisons des données mockées pour le développement
      List<MessageModel> messages;
      switch (event.conversationId) {
        case 'conv1':
          messages = mockMessages;
          break;
        case 'conv2':
          messages = mockVendeurMessages;
          break;
        case 'conv3':
          messages = mockFreelanceMessages;
          break;
        default:
          messages = [];
          break;
      }

      // Mettre à jour les messages pour la conversation actuelle
      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[event.conversationId] = messages;

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        messagesByConversation: updatedMessagesMap,
      ));
    } catch (error) {
      if (kDebugMode) {
        print('Error loading messages: $error');
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
      final newMessage = MessageModel(
        id: _uuid.v4(),
        senderId: _currentUserId,
        receiverId: state.selectedConversation!.participantId,
        timestamp: DateTime.now(),
        content: event.content,
        type: event.type,
        status: MessageStatus.sending, // Message en cours d'envoi
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

      // Simuler l'envoi du message à l'API
      await Future.delayed(const Duration(milliseconds: 500));

      // Dans un environnement réel, nous appellerions l'API ici
      // final sentMessage = await _apiClient.sendMessage(event.conversationId, newMessage);

      // Mettre à jour le statut du message à "envoyé"
      final sentMessage = newMessage.copyWith(newStatus: MessageStatus.sent);

      // Mettre à jour les messages avec le statut mis à jour
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

      // Simuler la réception du message par le destinataire après un court délai
      await Future.delayed(const Duration(seconds: 1));

      final deliveredMessage =
          sentMessage.copyWith(newStatus: MessageStatus.delivered);
      final deliveredMessages = finalMessages.map((msg) {
        if (msg.id == sentMessage.id) {
          return deliveredMessage;
        }
        return msg;
      }).toList();

      updatedMessagesMap[event.conversationId] = deliveredMessages;

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

  Future<void> _onMarkMessageAsRead(
      MarkMessageAsRead event, Emitter<ChatPageStateM> emit) async {
    try {
      // Dans un environnement réel, nous appellerions l'API ici
      // await _apiClient.markMessageAsRead(event.conversationId, event.messageId);

      // Simuler le succès de l'API
      await Future.delayed(const Duration(milliseconds: 200));

      // Mettre à jour le message localement
      if (!state.messagesByConversation.containsKey(event.conversationId))
        return;

      final updatedMessages =
          state.messagesByConversation[event.conversationId]!.map((msg) {
        if (msg.id == event.messageId) {
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
      // Simuler l'appel API
      await Future.delayed(const Duration(milliseconds: 200));

      // Dans un environnement réel, nous appellerions l'API ici
      // await _apiClient.markConversationAsRead(event.conversationId);

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

      // Créer une nouvelle conversation
      // Dans un environnement réel, nous appellerions l'API ici
      // final newConversation = await _apiClient.createConversation(
      //   _currentUserId,
      //   event.participantId,
      //   event.participantName,
      // );

      // Simuler la création d'une nouvelle conversation
      await Future.delayed(const Duration(milliseconds: 500));

      final newConversation = ConversationModel(
        id: _uuid.v4(),
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

      final updatedConversations = [newConversation, ...state.conversations];

      emit(state.copyWith(
        status: ChatPageStatus.loaded,
        conversations: updatedConversations,
        selectedConversation: newConversation,
      ));

      // Initialiser la liste des messages pour cette conversation
      final updatedMessagesMap =
          Map<String, List<MessageModel>>.from(state.messagesByConversation);
      updatedMessagesMap[newConversation.id] = [];

      emit(state.copyWith(
        messagesByConversation: updatedMessagesMap,
      ));
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
      // Dans un environnement réel, nous appellerions l'API ici
      // final List<ConversationModel> filteredConversations =
      //    await _apiClient.searchConversations(_currentUserId, event.query);

      // Simuler une recherche locale
      final lowercaseQuery = event.query.toLowerCase();
      final filteredConversations = mockConversations.where((conv) {
        return conv.participantName.toLowerCase().contains(lowercaseQuery) ||
            (conv.lastMessage?.content.toLowerCase().contains(lowercaseQuery) ??
                false);
      }).toList();

      await Future.delayed(const Duration(milliseconds: 300));

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
      add(NewMessageReceived(data));
    });

    _webSocketService.onMessageNotification((data) {
      // Gérer les notifications de nouveaux messages
      print('🔔 Notification message reçue: $data');
    });

    _webSocketService.onMessageError((error) {
      print('❌ Erreur message WebSocket: $error');
    });
  }

  // 🔌 CONNEXION WEBSOCKET
  Future<void> _onConnectWebSocket(
      ConnectWebSocket event, Emitter<ChatPageStateM> emit) async {
    try {
      await _webSocketService.connect();
      _webSocketService.authenticate(_currentUserId);
      emit(state.copyWith(isWebSocketConnected: true));
    } catch (error) {
      emit(state.copyWith(
        isWebSocketConnected: false,
        error: 'Erreur connexion WebSocket: $error',
      ));
    }
  }

  // 🔌 DÉCONNEXION WEBSOCKET
  Future<void> _onDisconnectWebSocket(
      DisconnectWebSocket event, Emitter<ChatPageStateM> emit) async {
    _webSocketService.disconnect();
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
  @override
  Future<void> close() {
    _webSocketService.dispose();
    _notificationService.dispose();
    return super.close();
  }
}
