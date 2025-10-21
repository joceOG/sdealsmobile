import 'message_model.dart';

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
    );
  }

  // 🔄 Convertir depuis le format backend
  factory ConversationModel.fromBackend(
      Map<String, dynamic> json, String currentUserId) {
    // Extraire les participants
    final List<dynamic> participants = json['participants'] ?? [];

    // Trouver l'autre participant (pas l'utilisateur actuel)
    Map<String, dynamic>? otherParticipant;
    for (var p in participants) {
      if (p is Map<String, dynamic>) {
        final participantId = p['_id']?.toString() ?? p['id']?.toString() ?? '';
        if (participantId != currentUserId) {
          otherParticipant = p;
          break;
        }
      }
    }

    // Déterminer le type de conversation
    ConversationType determineType(Map<String, dynamic>? participant) {
      if (participant == null) return ConversationType.prestataire;

      final role = participant['role']?.toString().toLowerCase() ?? '';
      if (role.contains('vendeur') || role == 'vendeur') {
        return ConversationType.vendeur;
      } else if (role.contains('freelance') || role == 'freelance') {
        return ConversationType.freelance;
      } else if (role.contains('prestataire') || role == 'prestataire') {
        return ConversationType.prestataire;
      }

      return ConversationType.prestataire;
    }

    // Extraire le dernier message
    MessageModel? lastMessage;
    if (json['dernierMessage'] != null) {
      try {
        lastMessage = MessageModel.fromBackend(json['dernierMessage']);
      } catch (e) {
        print('⚠️ Erreur parsing dernierMessage: $e');
      }
    }

    return ConversationModel(
      id: json['_id']?.toString() ?? json['conversationId']?.toString() ?? '',
      userId: currentUserId,
      participantId: otherParticipant?['_id']?.toString() ??
          otherParticipant?['id']?.toString() ??
          '',
      participantName: otherParticipant?['nom']?.toString() ??
          otherParticipant?['prenom']?.toString() ??
          'Utilisateur',
      participantImage:
          otherParticipant?['photoProfil']?.toString() ?? 'assets/profil.png',
      lastMessage: lastMessage,
      lastUpdated: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      unread: json['messagesNonLus'] != null && json['messagesNonLus'] > 0,
      unreadCount: json['messagesNonLus'] ?? 0,
      type: determineType(otherParticipant),
      isOnline: false, // À implémenter avec WebSocket
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

// Données de test pour le développement
List<ConversationModel> mockConversations = [
  ConversationModel(
    id: 'conv1',
    userId: 'currentUser',
    participantId: 'P001',
    participantName: 'EcoJardin Pro',
    participantImage: 'assets/profil.png',
    lastMessage: mockMessages.isNotEmpty ? mockMessages.last : null,
    lastUpdated: DateTime.now().subtract(const Duration(minutes: 20)),
    unread: false,
    unreadCount: 0,
    type: ConversationType.prestataire,
    isOnline: true,
  ),
  ConversationModel(
    id: 'conv2',
    userId: 'currentUser',
    participantId: 'V001',
    participantName: 'Tech Store',
    participantImage: 'assets/profil.png',
    lastMessage:
        mockVendeurMessages.isNotEmpty ? mockVendeurMessages.last : null,
    lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    unread: true,
    unreadCount: 3,
    type: ConversationType.vendeur,
    isOnline: false,
  ),
  ConversationModel(
    id: 'conv3',
    userId: 'currentUser',
    participantId: 'F001',
    participantName: 'Web Developer Pro',
    participantImage: 'assets/profil.png',
    lastMessage:
        mockFreelanceMessages.isNotEmpty ? mockFreelanceMessages.last : null,
    lastUpdated: DateTime.now().subtract(const Duration(days: 4, hours: 21)),
    unread: false,
    unreadCount: 0,
    type: ConversationType.freelance,
    isOnline: false,
  ),
  ConversationModel(
    id: 'conv4',
    userId: 'currentUser',
    participantId: 'P002',
    participantName: 'Electro Services',
    participantImage: 'assets/profil.png',
    lastMessage: MessageModel(
      id: '20',
      senderId: 'P002',
      receiverId: 'currentUser',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      content: 'Je confirme notre rendez-vous demain à 10h.',
      type: MessageType.text,
      status: MessageStatus.seen,
    ),
    lastUpdated: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    unread: true,
    unreadCount: 1,
    type: ConversationType.prestataire,
    isOnline: false,
  ),
  ConversationModel(
    id: 'conv5',
    userId: 'currentUser',
    participantId: 'P003',
    participantName: 'CleanHome',
    participantImage: 'assets/profil.png',
    lastMessage: MessageModel(
      id: '21',
      senderId: 'currentUser',
      receiverId: 'P003',
      timestamp: DateTime.now().subtract(const Duration(days: 6)),
      content: 'Merci pour votre excellent service !',
      type: MessageType.text,
      status: MessageStatus.seen,
    ),
    lastUpdated: DateTime.now().subtract(const Duration(days: 6)),
    unread: false,
    unreadCount: 0,
    type: ConversationType.prestataire,
    isOnline: true,
  ),
];
