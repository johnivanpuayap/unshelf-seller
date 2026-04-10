import 'package:flutter/material.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String type;

  const ChatBubble({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final Color bubbleColor =
        (type == 'sender') ? AppColors.primaryColor : AppColors.surface;
    final Color textColor =
        (type == 'sender') ? Colors.white : AppColors.textPrimary;
    return Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          color: bubbleColor,
        ),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: textColor),
        ));
  }
}
