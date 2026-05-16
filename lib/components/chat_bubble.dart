import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single chat message bubble.
///
/// Outgoing messages (`isOwn: true`) right-align with the primary colour;
/// incoming messages left-align on the honey-paper raised surface. Each bubble
/// has a 4px "tail" corner on the speaker's side and 18px corners elsewhere,
/// with an optional [timestamp] label rendered below.
///
/// Used by `chat_screen.dart` to render the conversation transcript. The
/// bubble itself is intentionally side-agnostic — alignment is driven by the
/// parent column so multiple bubbles can flow naturally in a `ListView`.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isOwn,
    this.timestamp,
    this.isRead,
  });

  final String text;
  final bool isOwn;
  final DateTime? timestamp;
  final bool? isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final mediaWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = mediaWidth * 0.75;

    final bubbleColor = isOwn ? cs.primary : cs.surfaceContainerHighest;
    final textColor = isOwn ? cs.onPrimary : cs.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOwn ? 18 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 18),
    );

    return Column(
      crossAxisAlignment:
          isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
            ),
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(color: textColor, height: 1.35),
            ),
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(timestamp!),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (isOwn && isRead != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead! ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead!
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    if (isToday) return DateFormat('h:mm a').format(time);
    final isThisYear = now.year == time.year;
    return DateFormat(isThisYear ? 'MMM d, h:mm a' : 'MMM d, y').format(time);
  }
}
