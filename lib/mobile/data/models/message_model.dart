import 'package:intl/intl.dart';

enum MessageType {
  text,
  image,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final String content;
  final MessageType type;
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      timestamp: DateTime.parse(json['timestamp']),
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  // 🔄 Convertir depuis le format backend
  factory MessageModel.fromBackend(Map<String, dynamic> json) {
    // Mapper les statuts backend vers les statuts locaux
    MessageStatus mapStatus(String? backendStatus) {
      switch (backendStatus?.toUpperCase()) {
        case 'ENVOYE':
          return MessageStatus.sent;
        case 'DELIVRE':
          return MessageStatus.delivered;
        case 'LU':
          return MessageStatus.seen;
        default:
          return MessageStatus.sent;
      }
    }

    // Mapper les types backend vers les types locaux
    MessageType mapType(String? typePieceJointe) {
      if (typePieceJointe == null || typePieceJointe.isEmpty) {
        return MessageType.text;
      }
      switch (typePieceJointe.toUpperCase()) {
        case 'IMAGE':
          return MessageType.image;
        default:
          return MessageType.text;
      }
    }

    return MessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['expediteur']?.toString() ?? '',
      receiverId: json['destinataire']?.toString() ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      content:
          json['contenu']?.toString() ?? json['pieceJointe']?.toString() ?? '',
      type: mapType(json['typePieceJointe']),
      status: mapStatus(json['statut']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
    };
  }

  // Format l'heure du message
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Aujourd'hui: afficher seulement l'heure
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == yesterday) {
      // Hier: afficher "Hier" + l'heure
      return 'Hier, ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      // Autre jour: afficher la date complète
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }

  // Crée une copie du message avec un statut mis à jour
  MessageModel copyWith({MessageStatus? newStatus}) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      timestamp: timestamp,
      content: content,
      type: type,
      status: newStatus ?? status,
    );
  }
}

// Liste de messages pour le développement et les tests
List<MessageModel> mockMessages = [
  MessageModel(
    id: '1',
    senderId: 'currentUser',
    receiverId: 'P001',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    content:
        'Bonjour, je souhaite réserver vos services pour demain à 14h. Est-ce possible ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '2',
    senderId: 'P001',
    receiverId: 'currentUser',
    timestamp:
        DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 50)),
    content:
        'Bonjour ! Oui, c\'est tout à fait possible. Pourriez-vous me préciser l\'adresse et le service souhaité ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '3',
    senderId: 'currentUser',
    receiverId: 'P001',
    timestamp:
        DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 40)),
    content:
        'Super ! C\'est au 123 Rue des Fleurs. Je souhaite une tonte complète du jardin.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '4',
    senderId: 'P001',
    receiverId: 'currentUser',
    timestamp:
        DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 35)),
    content:
        'Parfait, c\'est noté. J\'apporterai tout le matériel nécessaire. Y a-t-il autre chose à savoir ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '5',
    senderId: 'currentUser',
    receiverId: 'P001',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    content: 'Non c\'est tout. Merci beaucoup et à demain !',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '6',
    senderId: 'P001',
    receiverId: 'currentUser',
    timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
    content: 'À demain ! Bonne journée.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '7',
    senderId: 'currentUser',
    receiverId: 'P001',
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    content:
        'Excusez-moi, pourriez-vous aussi tailler la haie ? Je paierai le supplément bien sûr.',
    type: MessageType.text,
    status: MessageStatus.delivered,
  ),
  MessageModel(
    id: '8',
    senderId: 'P001',
    receiverId: 'currentUser',
    timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    content:
        'Aucun problème ! Je m\'occuperai également de la haie. Le tarif supplémentaire sera de 5000 FCFA.',
    type: MessageType.text,
    status: MessageStatus.delivered,
  ),
  MessageModel(
    id: '9',
    senderId: 'currentUser',
    receiverId: 'P001',
    timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    content: 'C\'est parfait, merci beaucoup !',
    type: MessageType.text,
    status: MessageStatus.sent,
  ),
];

// Message pour le vendeur
List<MessageModel> mockVendeurMessages = [
  MessageModel(
    id: '10',
    senderId: 'currentUser',
    receiverId: 'V001',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    content: 'Bonjour, est-ce que ce produit est toujours disponible ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '11',
    senderId: 'V001',
    receiverId: 'currentUser',
    timestamp:
        DateTime.now().subtract(const Duration(days: 3, hours: 4, minutes: 30)),
    content: 'Bonjour ! Oui, il est encore disponible en stock.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '12',
    senderId: 'currentUser',
    receiverId: 'V001',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
    content: 'Parfait ! Est-ce possible de le livrer demain ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '13',
    senderId: 'V001',
    receiverId: 'currentUser',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 3)),
    content:
        'Oui, nous pouvons livrer demain dans l\'après-midi. Voici une photo du produit.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '14',
    senderId: 'V001',
    receiverId: 'currentUser',
    timestamp:
        DateTime.now().subtract(const Duration(days: 3, hours: 2, minutes: 59)),
    content: 'assets/products/1.png',
    type: MessageType.image,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '15',
    senderId: 'currentUser',
    receiverId: 'V001',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    content: 'Merci pour la photo, je confirme ma commande !',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
];

// Message pour un freelance
List<MessageModel> mockFreelanceMessages = [
  MessageModel(
    id: '16',
    senderId: 'currentUser',
    receiverId: 'F001',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    content:
        'Bonjour, j\'ai besoin d\'aide pour créer un site web pour ma boutique.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '17',
    senderId: 'F001',
    receiverId: 'currentUser',
    timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 23)),
    content:
        'Bonjour ! Je serais ravi de vous aider. Pouvez-vous me donner plus de détails sur votre projet ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '18',
    senderId: 'currentUser',
    receiverId: 'F001',
    timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 22)),
    content:
        'Je vends des produits artisanaux et j\'aimerais un site e-commerce simple mais élégant.',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
  MessageModel(
    id: '19',
    senderId: 'F001',
    receiverId: 'currentUser',
    timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 21)),
    content:
        'Parfait ! Je peux vous proposer une solution avec WordPress et WooCommerce. Seriez-vous disponible pour un appel demain ?',
    type: MessageType.text,
    status: MessageStatus.seen,
  ),
];
