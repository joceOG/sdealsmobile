// 🎯 ÉTATS POUR LE BLoC MESSAGES PRESTATAIRE
abstract class MessagesState {}

// 📨 ÉTAT INITIAL
class MessagesInitial extends MessagesState {}

// 📨 CHARGEMENT EN COURS
class MessagesLoading extends MessagesState {}

// 📨 CONVERSATIONS CHARGÉES
class ConversationsLoaded extends MessagesState {
  final List<dynamic> conversations;
  final int totalUnread;
  final Map<String, dynamic>? stats;

  ConversationsLoaded({
    required this.conversations,
    required this.totalUnread,
    this.stats,
  });

  ConversationsLoaded copyWith({
    List<dynamic>? conversations,
    int? totalUnread,
    Map<String, dynamic>? stats,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      totalUnread: totalUnread ?? this.totalUnread,
      stats: stats ?? this.stats,
    );
  }
}

// 📨 MESSAGES CHARGÉS
class MessagesLoaded extends MessagesState {
  final List<dynamic> messages;
  final String conversationId;
  final bool hasMore;
  final int currentPage;

  MessagesLoaded({
    required this.messages,
    required this.conversationId,
    required this.hasMore,
    required this.currentPage,
  });

  MessagesLoaded copyWith({
    List<dynamic>? messages,
    String? conversationId,
    bool? hasMore,
    int? currentPage,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// 📨 MESSAGE ENVOYÉ
class MessageSent extends MessagesState {
  final Map<String, dynamic> message;
  MessageSent(this.message);
}

// 📨 MESSAGES MARQUÉS COMME LUS
class MessagesMarkedAsRead extends MessagesState {
  final String conversationId;
  final int modifiedCount;
  MessagesMarkedAsRead(this.conversationId, this.modifiedCount);
}

// 📨 RECHERCHE EFFECTUÉE
class MessagesSearched extends MessagesState {
  final List<dynamic> results;
  final String query;
  MessagesSearched(this.results, this.query);
}

// 📨 MESSAGES NON LUS CHARGÉS
class UnreadMessagesLoaded extends MessagesState {
  final List<dynamic> unreadMessages;
  final int total;
  UnreadMessagesLoaded(this.unreadMessages, this.total);
}

// 📨 MESSAGE SUPPRIMÉ
class MessageDeleted extends MessagesState {
  final String messageId;
  MessageDeleted(this.messageId);
}

// 📨 STATISTIQUES CHARGÉES
class MessageStatsLoaded extends MessagesState {
  final Map<String, dynamic> stats;
  MessageStatsLoaded(this.stats);
}

// 📨 ERREUR
class MessagesError extends MessagesState {
  final String message;
  MessagesError(this.message);
}
