import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';
import 'messages_event.dart';
import 'messages_state.dart';

// 🎯 BLoC POUR GÉRER LES MESSAGES PRESTATAIRE
class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final ApiClient _apiClient = ApiClient();
  final WebSocketService _webSocketService = WebSocketService();
  String? _currentToken;
  String? _userId;

  void setToken(String token) {
    _currentToken = token;
  }

  void setUserId(String userId) {
    _userId = userId;
  }

  MessagesBloc() : super(MessagesInitial()) {
    // 📨 CHARGER LES CONVERSATIONS DU PRESTATAIRE
    on<LoadPrestataireConversations>((event, emit) async {
      emit(MessagesLoading());
      _userId = event.prestataireId;
      try {
        final response = await _apiClient
            .get('/messages/conversations/${event.prestataireId}', token: _currentToken);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> conversations = data['conversations'] ?? [];
          final int totalUnread = conversations.fold(
              0, (sum, conv) => sum + (conv['nombreNonLus'] as int? ?? 0));

          emit(ConversationsLoaded(
            conversations: conversations,
            totalUnread: totalUnread,
            stats: data['stats'],
          ));
        } else {
          emit(MessagesError('Erreur lors du chargement des conversations'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 CHARGER LES MESSAGES D'UNE CONVERSATION
    on<LoadConversationMessages>((event, emit) async {
      emit(MessagesLoading());
      try {
        final response = await _apiClient.get(
            '/messages/conversation/${event.conversationId}?userId=${event.prestataireId}', token: _currentToken);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> messages = data['messages'] ?? [];
          final bool hasMore = data['currentPage'] < data['totalPages'];
          final int currentPage = data['currentPage'] ?? 1;

          emit(MessagesLoaded(
            messages: messages,
            conversationId: event.conversationId,
            hasMore: hasMore,
            currentPage: currentPage,
          ));
        } else {
          emit(MessagesError('Erreur lors du chargement des messages'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 ENVOYER UN MESSAGE
    on<SendMessage>((event, emit) async {
      emit(MessagesLoading());
      try {
        final response = await _apiClient.sendMessage(
          expediteur: event.prestataireId,
          destinataire: event.destinataireId,
          contenu: event.content,
          typeMessage: event.typeMessage ?? 'NORMAL',
          referenceId: event.referenceId,
          referenceType: event.referenceType,
          pieceJointe: event.pieceJointe,
          typePieceJointe: event.typePieceJointe,
        );

        emit(MessageSent(response));
        // Recharger les conversations
        add(LoadPrestataireConversations(event.prestataireId));
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 MARQUER LES MESSAGES COMME LUS
    on<MarkMessagesAsRead>((event, emit) async {
      try {
        final response = await _apiClient.patch(
          '/messages/mark-read',
          body: {
            'conversationId': event.conversationId,
            'userId': event.prestataireId,
          },
          token: _currentToken,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          emit(MessagesMarkedAsRead(
            event.conversationId,
            data['modifiedCount'] ?? 0,
          ));
          // Recharger les conversations pour mettre à jour les compteurs
          add(LoadPrestataireConversations(event.prestataireId));
        } else {
          emit(MessagesError('Erreur lors du marquage des messages'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 RECHERCHER DANS LES MESSAGES
    on<SearchMessages>((event, emit) async {
      emit(MessagesLoading());
      try {
        final response = await _apiClient.get(
            '/messages/search?userId=${event.prestataireId}&query=${event.query}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['messages'] ?? [];
          emit(MessagesSearched(results, event.query));
        } else {
          emit(MessagesError('Erreur lors de la recherche'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 CHARGER LES MESSAGES NON LUS
    on<LoadUnreadMessages>((event, emit) async {
      emit(MessagesLoading());
      try {
        final response =
            await _apiClient.get('/messages/unread/${event.prestataireId}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> unreadMessages = data['messages'] ?? [];
          final int total = data['total'] ?? 0;
          emit(UnreadMessagesLoaded(unreadMessages, total));
        } else {
          emit(MessagesError('Erreur lors du chargement des messages non lus'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 SUPPRIMER UN MESSAGE
    on<DeleteMessage>((event, emit) async {
      try {
        final response = await _apiClient.delete(
          '/message/${event.messageId}/user',
          body: {'userId': event.prestataireId},
          token: _currentToken,
        );

        if (response.statusCode == 200) {
          emit(MessageDeleted(event.messageId));
          // Recharger les conversations
          add(LoadPrestataireConversations(event.prestataireId));
        } else {
          emit(MessagesError('Erreur lors de la suppression'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 CHARGER LES STATISTIQUES
    on<LoadMessageStats>((event, emit) async {
      try {
        final response = await _apiClient
            .get('/messages/stats?userId=${event.prestataireId}');
        if (response.statusCode == 200) {
          final stats = jsonDecode(response.body);
          emit(MessageStatsLoaded(stats));
        } else {
          emit(MessagesError('Erreur lors du chargement des statistiques'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 FILTRER LES CONVERSATIONS
    on<FilterConversations>((event, emit) async {
      emit(MessagesLoading());
      try {
        String url = '/messages/conversations/${event.prestataireId}';
        List<String> params = [];

        if (event.typeMessage != null) {
          params.add('typeMessage=${event.typeMessage}');
        }
        if (event.statut != null) {
          params.add('statut=${event.statut}');
        }

        if (params.isNotEmpty) {
          url += '?${params.join('&')}';
        }

        final response = await _apiClient.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> conversations = data['conversations'] ?? [];
          final int totalUnread = conversations.fold(
              0, (sum, conv) => sum + (conv['nombreNonLus'] as int? ?? 0));

          emit(ConversationsLoaded(
            conversations: conversations,
            totalUnread: totalUnread,
            stats: data['stats'],
          ));
        } else {
          emit(MessagesError('Erreur lors du filtrage'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 📨 CHARGER PLUS DE MESSAGES (PAGINATION)
    on<LoadMoreMessages>((event, emit) async {
      try {
        final response = await _apiClient.get(
            '/messages/conversation/${event.conversationId}?userId=${event.prestataireId}&page=${event.page}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> newMessages = data['messages'] ?? [];
          final bool hasMore = data['currentPage'] < data['totalPages'];

          // Si on a déjà des messages chargés, les combiner
          if (state is MessagesLoaded) {
            final currentState = state as MessagesLoaded;
            final combinedMessages = [...currentState.messages, ...newMessages];

            emit(MessagesLoaded(
              messages: combinedMessages,
              conversationId: event.conversationId,
              hasMore: hasMore,
              currentPage: event.page,
            ));
          } else {
            emit(MessagesLoaded(
              messages: newMessages,
              conversationId: event.conversationId,
              hasMore: hasMore,
              currentPage: event.page,
            ));
          }
        } else {
          emit(MessagesError('Erreur lors du chargement des messages'));
        }
      } catch (e) {
        emit(MessagesError('Erreur de connexion: $e'));
      }
    });

    // 🔌 GESTIONNAIRES WEBSOCKET
    on<ConnectWebSocket>((event, emit) async {
      try {
        if (_userId != null && _userId!.isNotEmpty) {
          await _webSocketService.authenticate(userId: _userId!);
        } else {
          await _webSocketService.connect();
        }
        print('🔌 WebSocket connecté pour MessagesBloc');
      } catch (e) {
        print('❌ Erreur connexion WebSocket: $e');
      }
    });

    on<DisconnectWebSocket>((event, emit) async {
      try {
        _webSocketService.disconnect();
        print('🔌 WebSocket déconnecté pour MessagesBloc');
      } catch (e) {
        print('❌ Erreur déconnexion WebSocket: $e');
      }
    });

    on<NewMessageReceived>((event, emit) async {
      // Mettre à jour l'état avec le nouveau message
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updatedMessages = [...currentState.messages, event.messageData];
        emit(MessagesLoaded(
          messages: updatedMessages,
          conversationId: currentState.conversationId,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      }
    });

    on<MessageStatusUpdated>((event, emit) async {
      // Mettre à jour le statut d'un message
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updatedMessages = currentState.messages.map((message) {
          if (message['_id'] == event.messageId) {
            return {...message, 'statut': event.status};
          }
          return message;
        }).toList();

        emit(MessagesLoaded(
          messages: updatedMessages,
          conversationId: currentState.conversationId,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      }
    });
  }
}
