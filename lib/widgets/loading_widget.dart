import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shimmer loading placeholder
class LoadingWidget extends StatelessWidget {
  final LoadingType type;

  const LoadingWidget({super.key, this.type = LoadingType.fullScreen});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.fullScreen:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case LoadingType.inline:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case LoadingType.chatList:
        return _buildChatListShimmer();
    }
  }

  Widget _buildChatListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Avatar shimmer
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120, height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200, height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum LoadingType { fullScreen, inline, chatList }
