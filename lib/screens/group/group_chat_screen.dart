import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import '../../core/enums/enums.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/emoji_reaction.dart';
import '../../services/storage_service.dart';
import '../../services/audio_service.dart';
import '../../services/supabase_service.dart';
import '../../services/compression_service.dart';
import '../../widgets/message_input.dart';
import './group_details_screen.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Media & Recording states
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  final AudioService _audioService = AudioService();

  // Reply & Edit states
  MessageModel? _replyTo;
  MessageModel? _editingMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _editingMessage == null) return;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;
    final senderName = user?.displayName ?? 'Unknown';

    if (_editingMessage != null) {
      // Editing mode
      await ref.read(groupRepositoryProvider).editGroupMessage(_editingMessage!.id, text);
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
      return;
    }

    // Sending regular text message
    ref.read(groupRepositoryProvider).sendGroupMessage(
      groupId: widget.groupId,
      senderId: uid,
      senderName: senderName,
      text: text,
      replyTo: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
    );

    _messageController.clear();
    setState(() => _replyTo = null);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _lookupMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'zip':
        return 'application/zip';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickAndSendMedia(MessageType type) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;
    final senderName = user?.displayName ?? 'Unknown';

    String? filePath;
    String? name;
    int? size;
    String mimeType = 'application/octet-stream';
    Uint8List? uploadBytes;

    try {
      if (type == MessageType.image) {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
        if (file != null) {
          filePath = file.path;
          name = file.name;
          mimeType = 'image/jpeg';
          final originalBytes = await file.readAsBytes();
          uploadBytes = await ref.read(compressionServiceProvider).compressImage(
            filePath: file.path,
            originalBytes: originalBytes,
          );
          size = uploadBytes.length;
        }
      } else if (type == MessageType.file) {
        final result = await FilePicker.pickFiles();
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;
          filePath = file.path;
          name = file.name;
          size = file.size;
          final pickedBytes = file.bytes;
          if (pickedBytes == null && file.path != null) {
            uploadBytes = await XFile(file.path!).readAsBytes();
          } else {
            uploadBytes = pickedBytes;
          }
          mimeType = _lookupMimeType(name);
        }
      }

      if (name == null) return;
      if (uploadBytes == null && filePath != null) {
        uploadBytes = await XFile(filePath).readAsBytes();
      }
      if (uploadBytes == null) return;
      size ??= uploadBytes.length;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final downloadUrl = await ref.read(storageServiceProvider).uploadMedia(
            filePath: filePath,
            bytes: uploadBytes,
            chatId: widget.groupId,
            fileName: name,
            mimeType: mimeType,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );

      await ref.read(groupRepositoryProvider).sendGroupMessage(
            groupId: widget.groupId,
            senderId: uid,
            senderName: senderName,
            text: '',
            type: type,
            mediaUrl: downloadUrl,
            fileName: name,
            fileSize: size,
            replyTo: _replyTo?.id,
            replyToText: _replyTo?.text,
            replyToSender: _replyTo?.senderName,
          );

      setState(() => _replyTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload media: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _startRecording() async {
    final path = await _audioService.startRecording();
    if (path != null) {
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    }
  }

  void _stopAndSendVoice() async {
    _recordingTimer?.cancel();
    final path = await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
    });

    if (path == null) return;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;
    final senderName = user?.displayName ?? 'Unknown';

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final msgId = const Uuid().v4();
      final downloadUrl = await ref.read(storageServiceProvider).uploadVoiceNote(
            filePath: path,
            bytes: null,
            chatId: widget.groupId,
            messageId: msgId,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );

      await ref.read(groupRepositoryProvider).sendGroupMessage(
            groupId: widget.groupId,
            senderId: uid,
            senderName: senderName,
            text: '🎤 Voice note',
            type: MessageType.voiceNote,
            voiceNoteUrl: downloadUrl,
            voiceNoteDuration: _recordingDuration,
            replyTo: _replyTo?.id,
            replyToText: _replyTo?.text,
            replyToSender: _replyTo?.senderName,
          );

      setState(() => _replyTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload voice note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioService.cancelRecording();
    setState(() {
      _isRecording = false;
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primaryLight),
                title: const Text('Send Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(MessageType.image);
                },
              ),

              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.amber),
                title: const Text('Send Document / File', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(MessageType.file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendSticker(String stickerUrl) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;
    final senderName = user?.displayName ?? 'Unknown';

    await ref.read(groupRepositoryProvider).sendGroupMessage(
      groupId: widget.groupId,
      senderId: uid,
      senderName: senderName,
      text: '',
      type: MessageType.sticker,
      mediaUrl: stickerUrl,
      replyTo: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
    );
    setState(() => _replyTo = null);
  }

  void _sendGif(String gifUrl) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;
    final senderName = user?.displayName ?? 'Unknown';

    await ref.read(groupRepositoryProvider).sendGroupMessage(
      groupId: widget.groupId,
      senderId: uid,
      senderName: senderName,
      text: '',
      type: MessageType.gif,
      mediaUrl: gifUrl,
      replyTo: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
    );
    setState(() => _replyTo = null);
  }

  void _showMessageOptions(BuildContext context, MessageModel msg, bool isSent) {
    final uid = ref.read(authStateProvider).value?.uid ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Emojis
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      final reactions = Map<String, String>.from(msg.reactions);
                      reactions[uid] = emoji;
                      await ref.read(supabaseServiceProvider).db
                          .from('messages')
                          .update({'reactions': reactions})
                          .eq('id', msg.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.white70),
              title: const Text('Reply', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyTo = msg);
              },
            ),
            if (msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white70),
                title: const Text('Copy Text', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied to clipboard')),
                  );
                },
              ),
            if (isSent && msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = msg;
                    _messageController.text = msg.text;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.white70),
              title: const Text('Delete for me', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final deletedFor = List<String>.from(msg.deletedFor)..add(uid);
                await ref.read(supabaseServiceProvider).db
                    .from('messages')
                    .update({'deletedFor': deletedFor})
                    .eq('id', msg.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            if (isSent)
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Delete for everyone', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  await ref.read(supabaseServiceProvider).db
                      .from('messages')
                      .update({'deletedForEveryone': true, 'text': ''})
                      .eq('id', msg.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, MessageModel msg) {
    final uid = ref.read(authStateProvider).value?.uid ?? '';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: EmojiReactionWidget(
          onReact: (emoji) async {
            final reactions = Map<String, String>.from(msg.reactions);
            reactions[uid] = emoji;
            await ref.read(supabaseServiceProvider).db
                .from('messages')
                .update({'reactions': reactions})
                .eq('id', msg.id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search in group...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : groupAsync.when(
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Group'),
                data: (group) {
                  if (group == null) return const Text('Group');
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailsScreen(groupId: widget.groupId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        AvatarWidget(
                          name: group.name,
                          imageUrl: group.groupImage.isNotEmpty ? group.groupImage : null,
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                              Text('${group.memberCount} members',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Upload state indicator
          if (_isUploading)
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
            ),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) {
                debugPrint('Group messages stream error: $err');
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              },
              data: (messages) {
                final displayMessages = _searchQuery.isEmpty
                    ? messages
                    : messages.where((msg) => msg.text.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'No messages yet\nSay hello! 👋' : 'No messages match search',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: displayMessages.length,
                  itemBuilder: (_, i) {
                    final msg = displayMessages[i];
                    if (msg.isDeletedFor(uid)) return const SizedBox.shrink();

                    final isSent = msg.senderId == uid;

                    return ChatBubble(
                      text: msg.displayText(uid),
                      isSent: isSent,
                      timestamp: msg.timestamp,
                      status: msg.status,
                      isReply: msg.isReply,
                      replyToSender: msg.replyToSender,
                      replyToText: msg.replyToText,
                      isForwarded: msg.isForwarded,
                      isDeletedForEveryone: msg.deletedForEveryone,
                      reactions: msg.reactions,
                      senderName: isSent ? null : msg.senderName,
                      type: msg.type,
                      mediaUrl: msg.mediaUrl,
                      fileName: msg.fileName,
                      fileSize: msg.fileSize,
                      voiceNoteUrl: msg.voiceNoteUrl,
                      voiceNoteDuration: msg.voiceNoteDuration,
                      onLongPress: () => _showMessageOptions(context, msg, isSent),
                      onDoubleTap: () => _showReactionPicker(context, msg),
                    );
                  },
                );
              },
            ),
          ),

          // Reply or Edit preview banner
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              color: AppColors.card,
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_replyTo!.senderName, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                        Text(_replyTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),

          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              color: AppColors.card,
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Editing Message', style: AppTextStyles.labelSmall.copyWith(color: Colors.blue)),
                        Text(_editingMessage!.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _editingMessage = null;
                        _messageController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input Bar
          MessageInput(
            controller: _messageController,
            onTextChanged: _onTextChanged,
            onSendMessage: _sendMessage,
            onAttachmentPressed: _showMediaPicker,
            onMicTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hold mic button to record voice note')),
              );
            },
            onMicLongPress: _startRecording,
            onCancelRecording: _cancelRecording,
            onStopRecording: _stopAndSendVoice,
            onStickerSend: _sendSticker,
            onGifSend: _sendGif,
            isRecording: _isRecording,
            recordingDuration: _recordingDuration,
            hasText: _messageController.text.trim().isNotEmpty,
            isEditing: _editingMessage != null,
          ),
        ],
      ),
    );
  }
}
