import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders an animated sticker (from network URL) in a chat bubble.
/// Supports PNG, WEBP, and GIF images from network URLs.
class AnimatedStickerWidget extends StatelessWidget {
  final String url;
  final double size;
  final VoidCallback? onTap;

  const AnimatedStickerWidget({
    super.key,
    required this.url,
    this.size = 150,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
                size: 36,
              ),
            ),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
