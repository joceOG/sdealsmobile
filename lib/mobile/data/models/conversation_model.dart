import 'message_model.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';

enum ConversationType {
  prestataire,
  vendeur,
  freelance,
}

class ConversationModel {
  final String id;
  final String userId; // ID de l'utilisateur actuel
  final String participantId; // ID de l'autre participant
  final String participantName; // Nom de l'autre participant
  final String participantImage; // Image de l'autre participant
  final MessageModel? lastMessage; // Dernier message envoyé
  final DateTime lastUpdated; // Date de la dernière mise à jour
  final bool unread; // S'il y a des messages non lus
  final int unreadCount; // Nombre de messages non lus
  final ConversationType
      type; // Type de conversation (prestataire, vendeur, freelance)
  final bool isOnline; // Si le participant est en ligne
  /// Sujet affiché après l'univers (ex. « Plomberie », « Création de logo »).
  final String? contextLabel;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.participantId,
    required this.participantName,
    required this.participantImage,
    this.lastMessage,
    required this.lastUpdated,
    this.unread = false,
    this.unreadCount = 0,
    required this.type,
    this.isOnline = false,
    this.contextLabel,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      userId: json['userId'],
      participantId: json['participantId'],
      participantName: json['participantName'],
      participantImage: json['participantImage'],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      unread: json['unread'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
      type: ConversationType.values.firstWhere(
        (e) => e.toString() == 'ConversationType.${json['type']}',
        orElse: () => ConversationType.prestataire,
      ),
      isOnline: json['isOnline'] ?? false,
      contextLabel: cleanDisplayPart(json['contextLabel']),
    );
  }

  // 🔄 Convertir depuis le format backend
  // Le backend renvoie : { conversationId, interlocuteur, dernierMessage, nonLus }
  factory ConversationModel.fromBackend(
      Map<String, dynamic> json, String currentUserId) {

    // Interlocuteur : objet renvoyé par formatConversationsForUser
    final Map<String, dynamic>? interlocuteur =
        json['interlocuteur'] is Map<String, dynamic>
            ? json['interlocuteur'] as Map<String, dynamic>
            : null;

    // Déterminer le type de conversation selon les rôles de l'interlocuteur
    ConversationType determineType(Map<String, dynamic>? participant) {
      if (participant == null) return ConversationType.prestataire;
      final roles = participant['roles'];
      if (roles is List) {
        final rolesStr = roles.join(' ').toLowerCase();
        if (rolesStr.contains('vendeur')) return ConversationType.vendeur;
        if (rolesStr.contains('freelance')) return ConversationType.freelance;
      }
      final role = participant['role']?.toString().toLowerCase() ?? '';
      if (role.contains('vendeur')) return ConversationType.vendeur;
      if (role.contains('freelance')) return ConversationType.freelance;
      return ConversationType.prestataire;
    }

    // Extraire le dernier message
    MessageModel? lastMessage;
    if (json['dernierMessage'] != null) {
      try {
        lastMessage = MessageModel.fromBackend(
            json['dernierMessage'] as Map<String, dynamic>);
      } catch (e) {
        // ignore parsing error
      }
    }

    // unreadCount : le backend renvoie nonLus (pas messagesNonLus)
    final unreadCount = (json['nonLus'] as num?)?.toInt() ??
        (json['messagesNonLus'] as num?)?.toInt() ??
        0;

    // Nom affiché : préférer prénom + nom (STAB-12B)
    final participantName = personNameFromMap(
      interlocuteur,
      fallback: 'Utilisateur',
    );

    return ConversationModel(
      id: json['conversationId']?.toString() ?? json['_id']?.toString() ?? '',
      userId: currentUserId,
      participantId: interlocuteur?['_id']?.toString() ??
          interlocuteur?['id']?.toString() ??
          '',
      participantName: participantName,
      participantImage: safeImageUrl(interlocuteur?['photoProfil']) ?? '',
      lastMessage: lastMessage,
      lastUpdated: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : (lastMessage?.timestamp ?? DateTime.now()),
      unread: unreadCount > 0,
      unreadCount: unreadCount,
      type: determineType(interlocuteur),
      isOnline: false,
      contextLabel: cleanDisplayPart(json['contextLabel'] ??
          json['sujet'] ??
          json['serviceLabel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'participantId': participantId,
      'participantName': participantName,
      'participantImage': participantImage,
      'lastMessage': lastMessage?.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'unread': unread,
      'unreadCount': unreadCount,
      'type': type.toString().split('.').last,
      'isOnline': isOnline,
      if (contextLabel != null) 'contextLabel': contextLabel,
    };
  }

  // Retourne une copie de la conversation avec des paramètres mis à jour
  ConversationModel copyWith({
    String? id,
    String? userId,
    String? participantId,
    String? participantName,
    String? participantImage,
    MessageModel? lastMessage,
    DateTime? lastUpdated,
    bool? unread,
    int? unreadCount,
    ConversationType? type,
    bool? isOnline,
    String? contextLabel,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantImage: participantImage ?? this.participantImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      unread: unread ?? this.unread,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      contextLabel: contextLabel ?? this.contextLabel,
    );
  }

  // Retourne le type de contact sous forme de texte
  String get typeText {
    switch (type) {
      case ConversationType.prestataire:
        return 'Prestataire';
      case ConversationType.vendeur:
        return 'Vendeur';
      case ConversationType.freelance:
        return 'Freelance';
    }
  }
}

/// Données illustratives (maquette) — non injectées en prod ; référence tests / UI.
List<ConversationModel> mockConversations = [
  ConversationModel(
    id: 'illustr-travaux-1',
    userId: 'currentUser',
    participantId: 'P001',
    participantName: 'Kouamé Yao',
    participantImage: 'assets/profil.png',
    lastMessage: MessageModel(
      id: 'm1',
      senderId: 'P001',
      receiverId: 'currentUser',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      content: 'Je peux passer demain matin.',
      type: MessageType.text,
      status: MessageStatus.delivered,
    ),
    lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
    unread: true,
    unreadCount: 2,
    type: ConversationType.prestataire,
    contextLabel: 'Plomberie',
  ),
  ConversationModel(
    id: 'illustr-freelance-1',
    userId: 'currentUser',
    participantId: 'F001',
    participantName: 'Aïcha Koné',
    participantImage: 'assets/profil.png',
    lastMessage: MessageModel(
      id: 'm2',
      senderId: 'F001',
      receiverId: 'currentUser',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      content: 'Voici les deux premières propositions.',
      type: MessageType.text,
      status: MessageStatus.delivered,
    ),
    lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    unread: true,
    unreadCount: 1,
    type: ConversationType.freelance,
    contextLabel: 'Création de logo',
  ),
  ConversationModel(
    id: 'illustr-produits-1',
    userId: 'currentUser',
    participantId: 'V001',
    participantName: 'Boutique Élan',
    participantImage: 'assets/profil.png',
    lastMessage: MessageModel(
      id: 'm3',
      senderId: 'currentUser',
      receiverId: 'V001',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      content: 'La pointure 42 est disponible ?',
      type: MessageType.text,
      status: MessageStatus.seen,
    ),
    lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
    unread: false,
    unreadCount: 0,
    type: ConversationType.vendeur,
    contextLabel: 'Chaussures',
  ),
];
