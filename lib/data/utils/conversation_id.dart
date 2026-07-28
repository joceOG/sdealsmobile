/// Réplique la logique backend `genererConversationId`.
String buildConversationId(String userId1, String userId2) {
  final ids = [userId1, userId2]..sort();
  return 'conv_${ids[0]}_${ids[1]}';
}

String? getOtherParticipantId(String conversationId, String currentUserId) {
  if (!conversationId.startsWith('conv_')) return null;
  final parts =
      conversationId.replaceFirst('conv_', '').split('_').where((p) => p.isNotEmpty).toList();
  if (parts.length != 2) return null;
  if (parts[0] == currentUserId) return parts[1];
  if (parts[1] == currentUserId) return parts[0];
  return null;
}
