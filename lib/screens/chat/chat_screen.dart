import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import '../../core/enums/enums.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/emoji_reaction.dart';
import '../../services/storage_service.dart';
import '../../services/audio_service.dart';
import '../../services/compression_service.dart';
import '../profile/user_profile_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSearching = false;
  String _searchQuery = '';

  // Media & Recording states
  bool _isUploading = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  final AudioService _audioService = AudioService();

  // Reply & Edit states
  MessageModel? _replyTo;
  MessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).markAllAsSeen(widget.chatId, uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioService.dispose();
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
    }
    super.dispose();
  }

  void _onTextChanged(String text) {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _editingMessage == null) return;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final userAsync = ref.read(userByIdProvider(uid));
    final senderName = userAsync.value?.displayName ?? 'Unknown';

    if (_editingMessage != null) {
      // Editing message
      await ref.read(chatRepositoryProvider).editMessage(_editingMessage!.id, text);
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
      return;
    }

    // Regular send
    ref.read(chatRepositoryProvider).sendMessage(
      chatId: widget.chatId,
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

    _isTyping = false;
    _typingTimer?.cancel();
    ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
  }

  String _lookupMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
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
    final userAsync = ref.read(userByIdProvider(uid));
    final senderName = userAsync.value?.displayName ?? 'Unknown';

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
      } else if (type == MessageType.video) {
        final picker = ImagePicker();
        final file = await picker.pickVideo(source: ImageSource.gallery);
        if (file != null) {
          filePath = file.path;
          name = file.name;
          mimeType = 'video/mp4';
          final originalBytes = await file.readAsBytes();
          final compressResult = await ref.read(compressionServiceProvider).compressVideo(
            filePath: file.path,
            originalBytes: originalBytes,
          );
          filePath = compressResult.filePath ?? file.path;
          uploadBytes = compressResult.bytes;
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
            uploadBytes = await io.File(file.path!).readAsBytes();
          } else {
            uploadBytes = pickedBytes;
          }
          mimeType = _lookupMimeType(name);
        }
      }

      if (name == null) return;
      if (uploadBytes == null && filePath != null) {
        uploadBytes = await io.File(filePath).readAsBytes();
      }
      if (uploadBytes == null) return;
      size ??= uploadBytes.length;

      setState(() => _isUploading = true);

      final downloadUrl = await ref.read(storageServiceProvider).uploadMedia(
            filePath: filePath,
            bytes: uploadBytes,
            chatId: widget.chatId,
            fileName: name,
            mimeType: mimeType,
          );

      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: widget.chatId,
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
    final userAsync = ref.read(userByIdProvider(uid));
    final senderName = userAsync.value?.displayName ?? 'Unknown';

    setState(() => _isUploading = true);

    try {
      final msgId = const Uuid().v4();
      final downloadUrl = await ref.read(storageServiceProvider).uploadVoiceNote(
            filePath: path,
            bytes: null,
            chatId: widget.chatId,
            messageId: msgId,
          );

      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: widget.chatId,
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
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: const Text('Send Video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(MessageType.video);
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
                      await ref.read(chatRepositoryProvider).addReaction(widget.chatId, msg.id, uid, emoji);
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
                    const SnackBar(content: Text('Copied')),
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
                await ref.read(chatRepositoryProvider).deleteForMe(widget.chatId, msg.id, uid);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            if (isSent)
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Delete for everyone', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  await ref.read(chatRepositoryProvider).deleteForEveryone(widget.chatId, msg.id);
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
          onReact: (emoji) {
            ref.read(chatRepositoryProvider).addReaction(widget.chatId, msg.id, uid, emoji);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final otherUser = ref.watch(userStreamProvider(widget.otherUserId));
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final chatAsync = ref.watch(chatProvider(widget.chatId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 30,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : otherUser.when(
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Chat'),
                data: (user) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          userId: widget.otherUserId,
                          chatId: widget.chatId,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      AvatarWidget(
                        name: user?.displayName ?? '?',
                        imageUrl: user?.photoUrl,
                        size: 36,
                        showOnline: true,
                        isOnline: user?.isOnline ?? false,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Unknown',
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                            ),
                            Text(
                              user?.isOnline == true
                                  ? 'online'
                                  : user?.lastSeen != null
                                      ? DateFormatter.formatLastSeen(user!.lastSeen!)
                                      : '',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          chatAsync.when(
            data: (chat) {
              final isPinned = chat?.isPinnedBy(uid) ?? false;
              final isArchived = chat?.isArchivedBy(uid) ?? false;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) {
                  switch (val) {
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: widget.otherUserId, chatId: widget.chatId),
                        ),
                      );
                      break;
                    case 'pin':
                      ref.read(chatRepositoryProvider).togglePin(widget.chatId, uid, !isPinned);
                      break;
                    case 'archive':
                      ref.read(chatRepositoryProvider).toggleArchive(widget.chatId, uid, !isArchived);
                      if (!isArchived) {
                        Navigator.pop(context); // close chat screen if archived
                      }
                      break;
                    case 'clear':
                      _clearChatConfirm(context, uid);
                      break;
                    case 'delete':
                      _deleteChatConfirm(context, uid);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'profile', child: Text('View Profile')),
                  PopupMenuItem(value: 'pin', child: Text(isPinned ? 'Unpin Chat' : 'Pin Chat')),
                  PopupMenuItem(value: 'archive', child: Text(isArchived ? 'Unarchive Chat' : 'Archive Chat')),
                  const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Chat', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Upload state indicator
          if (_isUploading)
            const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.card),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
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

                // Setup typing list indicator
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

          // Typing indicator
          chatAsync.when(
            data: (chat) {
              if (chat == null) return const SizedBox.shrink();
              final isOtherTyping = chat.typingUsers.contains(widget.otherUserId);
              if (isOtherTyping) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicator(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
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

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (!_isRecording) ...[
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryLight, size: 26),
                      onPressed: _showMediaPicker,
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: _cancelRecording,
                    ),
                  ],
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _isRecording
                          ? Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Recording Voice... ${_recordingDuration}s',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                ),
                              ],
                            )
                          : TextField(
                              controller: _messageController,
                              onChanged: _onTextChanged,
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
                  ),
                  const SizedBox(width: 8),
                  if (!_isRecording && _messageController.text.trim().isEmpty && _editingMessage == null) ...[
                    GestureDetector(
                      onLongPress: _startRecording,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hold mic button to record voice note')),
                        );
                      },
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
                      onTap: _isRecording ? _stopAndSendVoice : _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _editingMessage != null
                              ? Icons.check
                              : _isRecording
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
        ],
      ),
    );
  }

  void _clearChatConfirm(BuildContext context, String uid) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Chat?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete all messages for you. This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (clear == true) {
      await ref.read(chatRepositoryProvider).clearChat(widget.chatId, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared')),
        );
      }
    }
  }

  void _deleteChatConfirm(BuildContext context, String uid) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Chat?', style: TextStyle(color: Colors.white)),
        content: const Text('This will clear and remove this chat from your list.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (delete == true) {
      await ref.read(chatRepositoryProvider).deleteChat(widget.chatId, uid);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
