import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';

/// Search screen — search users and start new chats
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (val) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              setState(() {
                _searchQuery = val;
              });
            });
          },
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          _searchQuery.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('Search for users', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  ],
                ))
              : _buildResults(uid),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(String uid) {
    final searchAsync = ref.watch(userSearchProvider(_searchQuery));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (users) {
        // Filter out current user
        final filtered = users.where((u) => u.uid != uid).toList();
        if (filtered.isEmpty) {
          return Center(child: Text('No users found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final user = filtered[i];
            return ListTile(
              leading: AvatarWidget(name: user.displayName, imageUrl: user.photoUrl, size: 48, showOnline: true, isOnline: user.isCurrentlyOnline),
              title: Text(user.displayName, style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(user.username.isNotEmpty ? '@${user.username}' : user.bio,
                style: TextStyle(color: AppColors.textSecondary)),
              onTap: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final chat = await ref.read(chatRepositoryProvider).getOrCreateChat(uid, user.uid);
                        ref.invalidate(chatsProvider(uid));
                        if (mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chat.id, otherUserId: user.uid),
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to open chat: $e', style: const TextStyle(color: Colors.white)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
            );
          },
        );
      },
    );
  }
}
