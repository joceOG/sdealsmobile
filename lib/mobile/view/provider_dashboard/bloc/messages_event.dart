// 🎯 ÉVÉNEMENTS POUR LE BLoC MESSAGES PRESTATAIRE
abstract class MessagesEvent {}

// 📨 CHARGER LES CONVERSATIONS DU PRESTATAIRE
class LoadPrestataireConversations extends MessagesEvent {
  final String prestataireId;
  LoadPrestataireConversations(this.prestataireId);
}

// 📨 CHARGER LES MESSAGES D'UNE CONVERSATION
class LoadConversationMessages extends MessagesEvent {
  final String conversationId;
  final String prestataireId;
  LoadConversationMessages(this.conversationId, this.prestataireId);
}

// 📨 ENVOYER UN MESSAGE
class SendMessage extends MessagesEvent {
  final String conversationId;
  final String prestataireId;
  final String destinataireId;
  final String content;
  final String? typeMessage;
  final String? referenceId;
  final String? referenceType;
  final dynamic pieceJointe;
  final String? typePieceJointe;

  SendMessage({
    required this.conversationId,
    required this.prestataireId,
    required this.destinataireId,
    required this.content,
    this.typeMessage,
    this.referenceId,
    this.referenceType,
    this.pieceJointe,
    this.typePieceJointe,
  });
}

// 📨 MARQUER LES MESSAGES COMME LUS
class MarkMessagesAsRead extends MessagesEvent {
  final String conversationId;
  final String prestataireId;
  MarkMessagesAsRead(this.conversationId, this.prestataireId);
}

// 📨 RECHERCHER DANS LES MESSAGES
class SearchMessages extends MessagesEvent {
  final String prestataireId;
  final String query;
  SearchMessages(this.prestataireId, this.query);
}

// 📨 CHARGER LES MESSAGES NON LUS
class LoadUnreadMessages extends MessagesEvent {
  final String prestataireId;
  LoadUnreadMessages(this.prestataireId);
}

// 📨 SUPPRIMER UN MESSAGE
class DeleteMessage extends MessagesEvent {
  final String messageId;
  final String prestataireId;
  DeleteMessage(this.messageId, this.prestataireId);
}

// 📨 CHARGER LES STATISTIQUES
class LoadMessageStats extends MessagesEvent {
  final String prestataireId;
  LoadMessageStats(this.prestataireId);
}

// 📨 FILTRER LES CONVERSATIONS
class FilterConversations extends MessagesEvent {
  final String prestataireId;
  final String? typeMessage;
  final String? statut;
  FilterConversations(this.prestataireId, {this.typeMessage, this.statut});
}

// 📨 CHARGER PLUS DE MESSAGES (PAGINATION)
class LoadMoreMessages extends MessagesEvent {
  final String conversationId;
  final String prestataireId;
  final int page;
  LoadMoreMessages(this.conversationId, this.prestataireId, this.page);
}

// 🔌 CONNEXION WEBSOCKET
class ConnectWebSocket extends MessagesEvent {}

// 🔌 DÉCONNEXION WEBSOCKET
class DisconnectWebSocket extends MessagesEvent {}

// 📨 NOUVEAU MESSAGE REÇU VIA WEBSOCKET
class NewMessageReceived extends MessagesEvent {
  final Map<String, dynamic> messageData;
  NewMessageReceived(this.messageData);
}

// 📨 MISE À JOUR STATUT MESSAGE
class MessageStatusUpdated extends MessagesEvent {
  final String messageId;
  final String status;
  MessageStatusUpdated(this.messageId, this.status);
}
