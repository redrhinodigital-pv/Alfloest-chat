import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/extensions/theme_extensions.dart';
import './emoji_picker_widget.dart';
import './sticker_picker.dart';
import './gif_picker_widget.dart';

/// Premium Telegram-style message composer with a unified, draggable bottom sheet for Emoji, Stickers, and GIFs.
class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSendMessage;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onMicTap;
  final VoidCallback onMicLongPress;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onStopRecording;
  final ValueChanged<String>? onStickerSend;
  final ValueChanged<String>? onGifSend;
  final bool isRecording;
  final int recordingDuration;
  final bool hasText;
  final bool isEditing;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onTextChanged,
    required this.onSendMessage,
    required this.onAttachmentPressed,
    required this.onMicTap,
    required this.onMicLongPress,
    this.onCancelRecording,
    this.onStopRecording,
    this.onStickerSend,
    this.onGifSend,
    this.isRecording = false,
    this.recordingDuration = 0,
    this.hasText = false,
    this.isEditing = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Opens the gorgeous, draggable snapping bottom sheet for Emojis, Stickers, and GIFs.
  void _showDraggablePickerSheet(BuildContext context) {
    // Unfocus textfield first to hide keyboard smoothly
    _focusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows rounded card layout and soft shadows
      barrierColor: Colors.black26,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.40, // Perfect compact height (40% of screen)
          minChildSize: 0.35,    // Minimum height
          maxChildSize: 0.75,    // Expandable height (75% of screen)
          snap: true,            // Enable snap points
          snapSizes: const [0.40, 0.75],
          builder: (context, scrollController) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? AppColors.surface : Colors.white;

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Snapping Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Content Area with TabBar
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppColors.primary,
                            unselectedLabelColor: isDark ? AppColors.textHint : Colors.grey,
                            indicatorColor: AppColors.primary,
                            tabs: const [
                              Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 20), text: 'Emoji'),
                              Tab(icon: Icon(Icons.sticky_note_2_outlined, size: 20), text: 'Sticker'),
                              Tab(icon: Icon(Icons.gif_box_outlined, size: 20), text: 'GIF'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // 1. Emoji Tab
                                EmojiPickerWidget(
                                  onEmojiSelected: (emoji) {
                                    final text = widget.controller.text;
                                    final selection = widget.controller.selection;
                                    final start = (selection.isValid && selection.start >= 0)
                                        ? selection.start
                                        : text.length;
                                    final end = (selection.isValid && selection.end >= 0)
                                        ? selection.end
                                        : text.length;
                                    final newText = text.replaceRange(start, end, emoji);
                                    widget.controller.value = TextEditingValue(
                                      text: newText,
                                      selection: TextSelection.collapsed(
                                        offset: start + emoji.length,
                                      ),
                                    );
                                    widget.onTextChanged(newText);
                                  },
                                  onBackspace: () {
                                    final text = widget.controller.text;
                                    if (text.isNotEmpty) {
                                      final characters = text.characters.toList();
                                      characters.removeLast();
                                      final newText = characters.join();
                                      widget.controller.text = newText;
                                      widget.controller.selection = TextSelection.collapsed(offset: newText.length);
                                      widget.onTextChanged(newText);
                                    }
                                  },
                                  height: double.infinity,
                                ),
                                // 2. Sticker Tab
                                StickerPicker(
                                  scrollController: scrollController,
                                  onStickerSelected: (url) {
                                    Navigator.pop(context);
                                    widget.onStickerSend?.call(url);
                                  },
                                  height: double.infinity,
                                ),
                                // 3. GIF Tab
                                GifPickerWidget(
                                  scrollController: scrollController,
                                  onGifSelected: (url) {
                                    Navigator.pop(context);
                                    widget.onGifSend?.call(url);
                                  },
                                  height: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTextOrEditing = widget.hasText || widget.isEditing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Blends perfectly with active chat screen
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Auto grow textfield expands upwards
          children: [
            // Glassmorphic Input Composer
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: context.chatInputBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isFocused 
                        ? AppColors.primary.withValues(alpha: 0.5) 
                        : context.divider.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isFocused ? 0.08 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji / Media Sheet toggle icon on the left
                    if (!widget.isRecording)
                      GestureDetector(
                        onTap: () => _showDraggablePickerSheet(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Icon(
                            Icons.emoji_emotions_outlined,
                            color: AppColors.primaryLight,
                            size: 24,
                          ),
                        ),
                      ),

                    // Expandable typing box / voice recording indicator
                    Expanded(
                      child: widget.isRecording
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recording Voice... ${widget.recordingDuration}s',
                                    style: TextStyle(
                                      color: context.textPrimary, 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              onChanged: widget.onTextChanged,
                              maxLines: 4, // Max size constraint
                              minLines: 1, // Dynamic auto-grow
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: AppTextStyles.bodyMedium.copyWith(color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: context.textHint),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                    ),

                    // Attachment files button on the right inside text box
                    if (!widget.isRecording)
                      IconButton(
                        icon: const Icon(Icons.attach_file_rounded, color: AppColors.primaryLight, size: 22),
                        onPressed: widget.onAttachmentPressed,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                        onPressed: widget.onCancelRecording,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),

            // Redesigned Floating Circular Action Button (Mic / Send)
            GestureDetector(
              onLongPress: (!widget.isRecording && !hasTextOrEditing) ? widget.onMicLongPress : null,
              onTap: () {
                if (widget.isRecording) {
                  widget.onStopRecording?.call();
                } else if (hasTextOrEditing) {
                  widget.onSendMessage();
                } else {
                  widget.onMicTap();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: hasTextOrEditing ? AppColors.primaryGradient : null,
                  color: hasTextOrEditing ? null : context.chatInputBackground,
                  shape: BoxShape.circle,
                  border: hasTextOrEditing ? null : Border.all(color: context.divider.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: hasTextOrEditing 
                          ? AppColors.primary.withValues(alpha: 0.3) 
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.isEditing
                        ? Icons.check_rounded
                        : widget.isRecording
                            ? Icons.send_rounded
                            : hasTextOrEditing
                                ? Icons.send_rounded
                                : Icons.mic_none_rounded,
                    color: hasTextOrEditing ? Colors.white : AppColors.primaryLight,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
