import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/data/models/conversation_model.dart';
import 'package:sdealsmobile/mobile/data/models/message_model.dart';

/// Bandeau « SERVICE CONCERNÉ » (maquette conversation).
class ConversationServiceContextBanner extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;

  const ConversationServiceContextBanner({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final serviceTitle =
        cleanDisplayPart(conversation.contextLabel) ?? 'Service';
    return Material(
      color: SDColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 48,
                  height: 48,
                  color: SDColors.primary50,
                  child: Icon(
                    Icons.home_repair_service_outlined,
                    color: SDColors.primary700,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVICE CONCERNÉ',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Voir le profil',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: SDColors.neutral400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationDateSeparator extends StatelessWidget {
  final String label;

  const ConversationDateSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: SDColors.neutral100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

bool conversationSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String conversationDateSeparatorLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Aujourd\'hui';
  if (day == today.subtract(const Duration(days: 1))) return 'Hier';
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String conversationMessageTimeLabel(DateTime timestamp) {
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String? outgoingStatusLabel(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return 'Envoi en cours…';
    case MessageStatus.sent:
    case MessageStatus.delivered:
    case MessageStatus.seen:
      return 'Envoyé';
    case MessageStatus.failed:
      return null;
  }
}

/// Bulle + métadonnées (maquette : texte lisible, photo, statuts, retry).
class ConversationMessageTile extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showPeerAvatar;
  final Widget? peerAvatar;
  final VoidCallback? onRetry;

  const ConversationMessageTile({
    super.key,
    required this.message,
    required this.isMe,
    this.showPeerAvatar = false,
    this.peerAvatar,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showPeerAvatar && peerAvatar != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: peerAvatar!,
              )
            else
              const SizedBox(width: 36),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? SDColors.primary50 : SDColors.white,
                    borderRadius: bubbleRadius,
                    border: Border.all(
                      color: isMe ? SDColors.primary100 : SDColors.neutral200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.neutral900.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _buildBubbleContent(),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversationMessageTimeLabel(message.timestamp),
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe && message.status != MessageStatus.failed) ...[
                      const SizedBox(width: 6),
                      if (message.status == MessageStatus.sending)
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: SDColors.neutral500,
                        ),
                      if (outgoingStatusLabel(message.status) != null) ...[
                        if (message.status == MessageStatus.sending)
                          const SizedBox(width: 4),
                        Text(
                          outgoingStatusLabel(message.status)!,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral600,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (isMe && message.status == MessageStatus.failed) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        'Échec de l\'envoi',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.error500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (onRetry != null)
                        TextButton(
                          onPressed: onRetry,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: SDColors.primary700,
                          ),
                          child: Text(
                            'Réessayer',
                            style: SDTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent() {
    if (message.type == MessageType.image) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(),
          if (message.content.trim().isNotEmpty &&
              message.content.trim().toLowerCase() != 'image') ...[
            const SizedBox(height: 8),
            Text(
              message.content,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
                height: 1.35,
              ),
            ),
          ],
        ],
      );
    }
    if (message.type == MessageType.audio) {
      return Text(
        message.content.isNotEmpty ? message.content : 'Message vocal',
        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
      );
    }
    return Text(
      message.content,
      style: SDTypography.bodyMedium.copyWith(
        color: SDColors.neutral900,
        height: 1.35,
      ),
    );
  }

  Widget _buildImage() {
    final url = message.attachmentUrl ?? message.content;
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          height: 180,
          width: double.infinity,
          placeholder: (_, __) => Container(
            height: 180,
            color: SDColors.neutral100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 120,
            color: SDColors.neutral100,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        url,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: SDColors.neutral100,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, color: SDColors.neutral400),
        ),
      ),
    );
  }
}
