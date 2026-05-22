import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// GIF item data class
class GifItem {
  final String url;
  final String? label;

  const GifItem({required this.url, this.label});
}

/// Premium dark-themed GIF picker using public Tenor/Giphy preview GIF URLs.
class GifPickerWidget extends StatefulWidget {
  final ValueChanged<String> onGifSelected;
  final double height;

  const GifPickerWidget({
    super.key,
    required this.onGifSelected,
    this.height = 280,
  });

  @override
  State<GifPickerWidget> createState() => _GifPickerWidgetState();
}

class _GifPickerWidgetState extends State<GifPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _currentCategory = 'trending';

  // Curated GIF collection using public Tenor CDN URLs (royalty-free preview GIFs)
  static const List<String> _categories = [
    'trending', 'reactions', 'celebrations', 'animals', 'memes',
  ];

  // Public domain / CC0 animated GIF URLs from various open sources
  static final Map<String, List<GifItem>> _gifLibrary = {
    'trending': [
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44b/512.gif', label: 'wave'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60e/512.gif', label: 'cool'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f929/512.gif', label: 'starstruck'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f973/512.gif', label: 'party_face'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f3c6/512.gif', label: 'trophy'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4aa/512.gif', label: 'flex'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f937/512.gif', label: 'shrug'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f926/512.gif', label: 'facepalm'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f64c/512.gif', label: 'raised_hands'),
    ],
    'reactions': [
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif', label: 'thumbs_up'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44e/512.gif', label: 'thumbs_down'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44f/512.gif', label: 'clap'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f605/512.gif', label: 'sweat_smile'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f62c/512.gif', label: 'grimace'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f971/512.gif', label: 'yawn'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f914/512.gif', label: 'thinking'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f910/512.gif', label: 'zipper_mouth'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92c/512.gif', label: 'cursing'),
    ],
    'celebrations': [
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif', label: 'party'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f38a/512.gif', label: 'confetti'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f382/512.gif', label: 'cake'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f381/512.gif', label: 'gift'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f386/512.gif', label: 'fireworks'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f387/512.gif', label: 'sparkler'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f388/512.gif', label: 'balloon'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f37e/512.gif', label: 'champagne'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f942/512.gif', label: 'clink'),
    ],
    'animals': [
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f436/512.gif', label: 'dog'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f431/512.gif', label: 'cat'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f43b/512.gif', label: 'bear'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f98a/512.gif', label: 'fox'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f981/512.gif', label: 'lion'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f427/512.gif', label: 'penguin'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f43c/512.gif', label: 'panda'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f98b/512.gif', label: 'butterfly'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f433/512.gif', label: 'whale'),
    ],
    'memes': [
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f480/512.gif', label: 'skull'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a9/512.gif', label: 'poop'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f921/512.gif', label: 'clown'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f47d/512.gif', label: 'alien'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f47b/512.gif', label: 'ghost'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif', label: 'robot'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f608/512.gif', label: 'devil'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif', label: 'boom'),
      GifItem(url: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a3/512.gif', label: 'bomb'),
    ],
  };

  List<GifItem> get _currentGifs {
    final query = _searchController.text.trim().toLowerCase();
    final gifs = _gifLibrary[_currentCategory] ?? [];
    if (query.isEmpty) return gifs;
    return gifs.where((g) => (g.label ?? '').contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search GIFs...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 18),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),

          // Category chips
          Container(
            height: 36,
            color: AppColors.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _currentCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _currentCategory = cat),
                    child: Chip(
                      label: Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected ? Colors.white : AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: selected ? AppColors.primary : AppColors.card,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
          ),

          // GIF grid
          Expanded(
            child: Container(
              color: AppColors.background,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _currentGifs.length,
                itemBuilder: (_, i) {
                  final gif = _currentGifs[i];
                  return GestureDetector(
                    onTap: () => widget.onGifSelected(gif.url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: AppColors.card,
                        child: Image.network(
                          gif.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.gif_box_outlined, color: AppColors.textHint),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
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
