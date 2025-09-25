import 'package:equatable/equatable.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

enum ChatPageStatus {
  initial,
  loading,
  loaded,
  error,
}

class ChatPageStateM extends Equatable {
  final ChatPageStatus status;
  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messagesByConversation;
  final ConversationModel? selectedConversation;
  final String? error;

  // Champs utilisés pour la compatibilité avec le code existant
  final bool? isLoading;
  final List<Categorie>? listItems;

  // 🔌 WebSocket et notifications
  final bool isWebSocketConnected;

  const ChatPageStateM({
    this.status = ChatPageStatus.initial,
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.selectedConversation,
    this.error,
    this.isLoading,
    this.listItems,
    this.isWebSocketConnected = false,
  });

  factory ChatPageStateM.initial() {
    return const ChatPageStateM(
      status: ChatPageStatus.initial,
      isLoading: true,
      listItems: null,
      error: '',
      isWebSocketConnected: false,
    );
  }

  ChatPageStateM copyWith({
    ChatPageStatus? status,
    List<ConversationModel>? conversations,
    Map<String, List<MessageModel>>? messagesByConversation,
    ConversationModel? selectedConversation,
    String? error,
    bool? isLoading,
    List<Categorie>? listItems,
    bool? isWebSocketConnected,
    bool clearSelectedConversation = false,
  }) {
    return ChatPageStateM(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      selectedConversation: clearSelectedConversation
          ? null
          : selectedConversation ?? this.selectedConversation,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      listItems: listItems ?? this.listItems,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
    );
  }

  // Pour garder la compatibilité avec le code existant
  ChatPageStateM copyWith3({
    bool? isLoading2,
    String? error2,
  }) {
    return copyWith(
      isLoading: isLoading2,
      error: error2,
    );
  }

  // Renvoie les messages de la conversation sélectionnée
  List<MessageModel> get selectedConversationMessages {
    if (selectedConversation == null) return [];
    return messagesByConversation[selectedConversation!.id] ?? [];
  }

  // Renvoie true si des messages sont en cours de chargement
  bool get isLoadingMessages {
    return status == ChatPageStatus.loading && selectedConversation != null;
  }

  // Renvoie true si des conversations sont en cours de chargement
  bool get isLoadingConversations {
    return status == ChatPageStatus.loading && selectedConversation == null;
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        messagesByConversation,
        selectedConversation,
        error,
        isLoading,
        listItems,
        isWebSocketConnected,
      ];
}
