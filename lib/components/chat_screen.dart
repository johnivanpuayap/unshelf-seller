import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:unshelf_seller/components/chat_bubble.dart';
import 'package:unshelf_seller/core/interfaces/i_chat_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';

/// Single conversation surface between the seller and one buyer.
///
/// Although it lives under `lib/components/` for historical reasons, this is a
/// full-screen view: it owns its own [Scaffold], an inline [AppBar] (peer
/// avatar + name + presence subtitle) and the message input bar at the bottom.
///
/// Streams messages from [IChatService] in chronological order (newest at
/// bottom) and renders them as [ChatBubble]s grouped by sender. The input bar
/// uses the themed [InputDecorationTheme] fill so the field melts into the
/// surface, with a primary-tinted send icon button on the right.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.receiverName,
    required this.receiverUserID,
    this.receiverAvatarUrl,
  });

  final String receiverName;
  final String receiverUserID;
  final String? receiverAvatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IChatService _chatService = locator<IChatService>();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _sending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _chatService.sendMessage(widget.receiverUserID, text);
      _messageController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't send message.")),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _PeerAvatar(
              name: widget.receiverName,
              imageUrl: widget.receiverAvatarUrl,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.receiverName.isEmpty
                        ? 'Conversation'
                        : widget.receiverName,
                    style: tt.titleMedium?.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Buyer',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _MessageInputBar(
              controller: _messageController,
              onSend: _sendMessage,
              isSending: _sending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final currentUid = _firebaseAuth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverUserID, currentUid),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final tt = theme.textTheme;

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Couldn't load messages.",
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Say hello',
                    style:
                        tt.titleMedium?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Send the first message to start the conversation.",
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final document = docs[index];
            final data = document.data() as Map<String, dynamic>;
            final senderId = data['senderId'] as String? ?? '';
            final isOwn = senderId == currentUid;
            final messageText = (data['message'] as String?) ?? '';
            final ts = data['timestamp'];
            DateTime? timestamp;
            if (ts is Timestamp) {
              timestamp = ts.toDate().toLocal();
            }

            // Show timestamp only for the last bubble in a sender group.
            final isLastInGroup = index == docs.length - 1 ||
                ((docs[index + 1].data() as Map<String, dynamic>)['senderId'] !=
                    senderId);

            return Padding(
              padding: EdgeInsets.only(bottom: isLastInGroup ? 12 : 4),
              child: Align(
                alignment:
                    isOwn ? Alignment.centerRight : Alignment.centerLeft,
                child: ChatBubble(
                  text: messageText,
                  isOwn: isOwn,
                  timestamp: isLastInGroup ? timestamp : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ────────────────────────────────────────────────────────────────────────────

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.name,
    required this.size,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _initialsFallback(cs, tt, size, name),
            )
          : _initialsFallback(cs, tt, size, name),
    );
  }

  static Widget _initialsFallback(
    ColorScheme cs,
    TextTheme tt,
    double size,
    String name,
  ) {
    final initials = _initialsFromName(name);
    return Center(
      child: Text(
        initials,
        style: (size >= 48 ? tt.titleMedium : tt.labelLarge)?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initialsFromName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    hintText: 'Type a message',
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isSending ? null : onSend,
                    child: Center(
                      child: isSending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: cs.onPrimary,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
