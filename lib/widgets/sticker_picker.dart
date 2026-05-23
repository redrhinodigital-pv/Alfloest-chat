import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Sticker category data
class StickerCategory {
  final String name;
  final IconData icon;
  final List<StickerItem> stickers;

  const StickerCategory({
    required this.name,
    required this.icon,
    required this.stickers,
  });
}

/// Individual sticker
class StickerItem {
  final String url;
  final String? label;

  const StickerItem({required this.url, this.label});
}

/// Premium sticker picker with horizontal category tabs and grid display.
class StickerPicker extends StatefulWidget {
  final ValueChanged<String> onStickerSelected;
  final double height;
  final ScrollController? scrollController; // Added to support draggable sheet integration

  const StickerPicker({
    super.key,
    required this.onStickerSelected,
    this.height = 280,
    this.scrollController,
  });

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  int _selectedCategory = 0;

  // Built-in sticker packs using public emoji-style URLs
  static final List<StickerCategory> _categories = [
    StickerCategory(
      name: 'Reactions',
      icon: Icons.emoji_emotions_outlined,
      stickers: [
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif', label: 'thumbs_up'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/2764_fe0f/512.gif', label: 'heart'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f602/512.gif', label: 'joy'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f622/512.gif', label: 'cry'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif', label: 'fire'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60d/512.gif', label: 'heart_eyes'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92f/512.gif', label: 'mind_blown'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44f/512.gif', label: 'clap'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif', label: 'party'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4af/512.gif', label: 'hundred'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f62e/512.gif', label: 'surprised'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92d/512.gif', label: 'shush'),
      ],
    ),
    StickerCategory(
      name: 'Love',
      icon: Icons.favorite_outline,
      stickers: [
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f970/512.gif', label: 'smiling_hearts'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f618/512.gif', label: 'kiss'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f496/512.gif', label: 'sparkling_heart'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f49d/512.gif', label: 'heart_ribbon'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f48b/512.gif', label: 'kiss_mark'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f495/512.gif', label: 'two_hearts'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f493/512.gif', label: 'heartbeat'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f49e/512.gif', label: 'revolving_hearts'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f339/512.gif', label: 'rose'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f338/512.gif', label: 'cherry_blossom'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1fac0/512.gif', label: 'anatomical_heart'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f917/512.gif', label: 'hug'),
      ],
    ),
    StickerCategory(
      name: 'Funny',
      icon: Icons.sentiment_very_satisfied,
      stickers: [
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f923/512.gif', label: 'rofl'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f921/512.gif', label: 'clown'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92a/512.gif', label: 'zany'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f480/512.gif', label: 'skull'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f47b/512.gif', label: 'ghost'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a9/512.gif', label: 'poop'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f608/512.gif', label: 'devil'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f648/512.gif', label: 'see_no_evil'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f649/512.gif', label: 'hear_no_evil'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f64a/512.gif', label: 'speak_no_evil'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f913/512.gif', label: 'nerd'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f643/512.gif', label: 'upside_down'),
      ],
    ),
    StickerCategory(
      name: 'Anime',
      icon: Icons.star_outline,
      stickers: [
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.gif', label: 'sparkles'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f31f/512.gif', label: 'glowing_star'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f308/512.gif', label: 'rainbow'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f984/512.gif', label: 'unicorn'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f409/512.gif', label: 'dragon'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f47e/512.gif', label: 'alien'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif', label: 'robot'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1fa84/512.gif', label: 'magic_wand'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif', label: 'rocket'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f30d/512.gif', label: 'globe'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f3ae/512.gif', label: 'game'),
        StickerItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f3a8/512.gif', label: 'art'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedCategory];
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Category tabs
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: Row(
              children: List.generate(_categories.length, (i) {
                final cat = _categories[i];
                final selected = i == _selectedCategory;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            size: 20,
                            color: selected ? AppColors.primary : AppColors.textHint,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.name,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: selected ? AppColors.primary : AppColors.textHint,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Sticker grid
          Expanded(
            child: Container(
              color: AppColors.background,
              child: GridView.builder(
                controller: widget.scrollController, // Hooked draggable scroll controller
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: category.stickers.length,
                itemBuilder: (_, i) {
                  final sticker = category.stickers[i];
                  return GestureDetector(
                    onTap: () => widget.onStickerSelected(sticker.url),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.card.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CachedNetworkImage( // Replaced with CachedNetworkImage
                        imageUrl: sticker.url,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                          size: 24,
                        ),
                        placeholder: (_, __) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
