import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Quick emoji reaction picker
class EmojiReactionWidget extends StatelessWidget {
  final Function(String emoji) onReact;
  final VoidCallback? onMoreEmoji;

  const EmojiReactionWidget({super.key, required this.onReact, this.onMoreEmoji});

  static const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...quickReactions.map((e) => GestureDetector(
            onTap: () => onReact(e),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(e, style: const TextStyle(fontSize: 26)),
            ),
          )),
          if (onMoreEmoji != null)
            IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary, size: 24),
              onPressed: onMoreEmoji, padding: EdgeInsets.all(4), constraints: BoxConstraints()),
        ],
      ),
    );
  }
}
