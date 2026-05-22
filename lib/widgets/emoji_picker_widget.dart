import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../theme/app_colors.dart';

/// Premium dark-themed emoji picker wrapping emoji_picker_flutter.
class EmojiPickerWidget extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onBackspace;
  final double height;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        onBackspacePressed: onBackspace,
        config: Config(
          height: height,
          emojiViewConfig: EmojiViewConfig(
            columns: 8,
            emojiSizeMax: 28.0,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            backgroundColor: AppColors.background,
            noRecents: const Text(
              'No recent emojis',
              style: TextStyle(fontSize: 16, color: AppColors.textHint),
            ),
          ),
          categoryViewConfig: CategoryViewConfig(
            indicatorColor: AppColors.primary,
            iconColorSelected: AppColors.primary,
            iconColor: AppColors.textHint,
            backgroundColor: AppColors.background,
            tabBarHeight: 46,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            enabled: false,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: AppColors.background,
            buttonIconColor: AppColors.textHint,
            hintText: 'Search emoji...',
          ),
        ),
      ),
    );
  }
}
