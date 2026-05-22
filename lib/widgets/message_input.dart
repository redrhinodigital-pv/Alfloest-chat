import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import './emoji_picker_widget.dart';
import './sticker_picker.dart';
import './gif_picker_widget.dart';

/// Which picker tray is currently open
enum PickerType { none, emoji, sticker, gif }

/// Premium Telegram-style message composer with expandable Emoji / Sticker / GIF tray.
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

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  PickerType _activePicker = PickerType.none;
  late final AnimationController _pickerAnimation;
  late final Animation<double> _pickerHeight;

  @override
  void initState() {
    super.initState();
    _pickerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pickerHeight = CurvedAnimation(
      parent: _pickerAnimation,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pickerAnimation.dispose();
    super.dispose();
  }

  void _togglePicker(PickerType type) {
    if (_activePicker == type) {
      // Close
      _pickerAnimation.reverse();
      setState(() => _activePicker = PickerType.none);
    } else {
      // Open or switch
      setState(() => _activePicker = type);
      _pickerAnimation.forward();
    }
  }

  void _closePicker() {
    if (_activePicker != PickerType.none) {
      _pickerAnimation.reverse();
      setState(() => _activePicker = PickerType.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (!widget.isRecording) ...[
                  // Attachment button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryLight, size: 26),
                    onPressed: () {
                      _closePicker();
                      widget.onAttachmentPressed();
                    },
                  ),
                ] else ...[
                  // Cancel recording
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error),
                    onPressed: widget.onCancelRecording,
                  ),
                ],

                // Text field / Recording indicator
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: widget.isRecording
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Recording Voice... ${widget.recordingDuration}s',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              // Emoji/Sticker toggle
                              GestureDetector(
                                onTap: () => _togglePicker(PickerType.emoji),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _activePicker == PickerType.emoji
                                        ? Icons.keyboard_rounded
                                        : Icons.emoji_emotions_outlined,
                                    color: _activePicker == PickerType.emoji
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    size: 22,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: widget.controller,
                                  onChanged: widget.onTextChanged,
                                  onTap: _closePicker,
                                  maxLines: 4,
                                  minLines: 1,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Message',
                                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right button: Mic or Send
                if (!widget.isRecording && !widget.hasText && !widget.isEditing) ...[
                  GestureDetector(
                    onLongPress: widget.onMicLongPress,
                    onTap: widget.onMicTap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.mic, color: AppColors.primaryLight, size: 22),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: widget.isRecording
                        ? widget.onStopRecording
                        : widget.onSendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isEditing
                            ? Icons.check
                            : widget.isRecording
                                ? Icons.send
                                : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Picker tray row (Sticker / GIF shortcut buttons)
        if (_activePicker != PickerType.none)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _buildPickerTab(
                  icon: Icons.emoji_emotions_rounded,
                  label: 'Emoji',
                  isActive: _activePicker == PickerType.emoji,
                  onTap: () => _togglePicker(PickerType.emoji),
                ),
                const SizedBox(width: 6),
                _buildPickerTab(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Stickers',
                  isActive: _activePicker == PickerType.sticker,
                  onTap: () => _togglePicker(PickerType.sticker),
                ),
                const SizedBox(width: 6),
                _buildPickerTab(
                  icon: Icons.gif_box_outlined,
                  label: 'GIFs',
                  isActive: _activePicker == PickerType.gif,
                  onTap: () => _togglePicker(PickerType.gif),
                ),
              ],
            ),
          ),

        // Animated picker tray
        SizeTransition(
          sizeFactor: _pickerHeight,
          child: _buildPickerContent(),
        ),
      ],
    );
  }

  Widget _buildPickerTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerContent() {
    switch (_activePicker) {
      case PickerType.emoji:
        return EmojiPickerWidget(
          onEmojiSelected: (emoji) {
            final text = widget.controller.text;
            final selection = widget.controller.selection;
            // When emoji picker is open, TextField loses focus and selection
            // becomes invalid (start = -1). Default to appending at end.
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
              // Remove last character (handles multi-byte emoji)
              final characters = text.characters.toList();
              characters.removeLast();
              final newText = characters.join();
              widget.controller.text = newText;
              widget.controller.selection = TextSelection.collapsed(offset: newText.length);
              widget.onTextChanged(newText);
            }
          },
        );

      case PickerType.sticker:
        return StickerPicker(
          onStickerSelected: (url) {
            _closePicker();
            widget.onStickerSend?.call(url);
          },
        );

      case PickerType.gif:
        return GifPickerWidget(
          onGifSelected: (url) {
            _closePicker();
            widget.onGifSend?.call(url);
          },
        );

      case PickerType.none:
        return const SizedBox.shrink();
    }
  }
}
