import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/chat_screen.dart';
import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/core/interfaces/i_chat_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';

/// Inbox of all buyer conversations.
///
/// Each tile shows a 56px circular avatar (with initials fallback), the
/// buyer's display name, a single-line excerpt of the last message, the
/// timestamp and an unread dot when applicable. Tap → push [ChatScreen].
///
/// Streams the buyers list from [IChatService.getBuyers]. Empty, loading, and
/// error states all use the brand kit's [EmptyState] / progress indicator
/// conventions.
class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final chatService = locator<IChatService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: chatService.getBuyers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ChatsError(
                message: snapshot.error?.toString() ??
                    "We couldn't load your conversations.",
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const _ChatsEmpty();
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>? ??
                    const <String, dynamic>{};
                return _ConversationTile(
                  name: (data['name'] as String?) ?? 'Buyer',
                  avatarUrl: data['profileImageUrl'] as String?,
                  lastMessage: data['lastMessage'] as String?,
                  lastMessageAt: _readTimestamp(data['lastMessageAt']) ??
                      _readTimestamp(data['updatedAt']),
                  unreadCount: _readUnreadCount(data['unreadCount']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverName:
                              (data['name'] as String?) ?? 'Conversation',
                          receiverUserID: doc.id,
                          receiverAvatarUrl:
                              data['profileImageUrl'] as String?,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

DateTime? _readTimestamp(dynamic raw) {
  if (raw is Timestamp) return raw.toDate().toLocal();
  if (raw is DateTime) return raw.toLocal();
  return null;
}

int _readUnreadCount(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return 0;
}

// ────────────────────────────────────────────────────────────────────────────
// Conversation tile
// ────────────────────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final hasUnread = unreadCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1F2A20).withValues(alpha: .06),
            offset: const Offset(0, 8),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BuyerAvatar(name: name, imageUrl: avatarUrl, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: tt.titleSmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatTileTime(lastMessageAt!),
                              style: tt.labelMedium?.copyWith(
                                color: hasUnread
                                    ? cs.primary
                                    : cs.onSurface
                                        .withValues(alpha: 0.55),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (lastMessage != null &&
                                      lastMessage!.trim().isNotEmpty)
                                  ? lastMessage!
                                  : 'Tap to start a conversation',
                              style: tt.bodyMedium?.copyWith(
                                color: hasUnread
                                    ? cs.onSurface
                                    : cs.onSurface
                                        .withValues(alpha: 0.65),
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            _UnreadBadge(count: unreadCount, color: cs.primary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTileTime(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final atDay = DateTime(time.year, time.month, time.day);
  if (atDay == today) return DateFormat('h:mm a').format(time);
  final yesterday = today.subtract(const Duration(days: 1));
  if (atDay == yesterday) return 'Yesterday';
  final diff = today.difference(atDay).inDays;
  if (diff < 7) return DateFormat('EEE').format(time);
  if (time.year == now.year) return DateFormat('MMM d').format(time);
  return DateFormat('MMM d, y').format(time);
}

// ────────────────────────────────────────────────────────────────────────────
// Avatar
// ────────────────────────────────────────────────────────────────────────────

class _BuyerAvatar extends StatelessWidget {
  const _BuyerAvatar({
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

// ────────────────────────────────────────────────────────────────────────────
// Unread badge
// ────────────────────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final cs = theme.colorScheme;
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: cs.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Empty / error states
// ────────────────────────────────────────────────────────────────────────────

class _ChatsEmpty extends StatelessWidget {
  const _ChatsEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        EmptyState(
          icon: Icons.forum_outlined,
          title: 'No conversations yet',
          subtitle:
              "When buyers message you about your listings, you'll see them here.",
        ),
      ],
    );
  }
}

class _ChatsError extends StatelessWidget {
  const _ChatsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: cs.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load messages",
              style: tt.titleMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
