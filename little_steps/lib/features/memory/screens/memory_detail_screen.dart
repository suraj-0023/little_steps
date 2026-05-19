import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/memory_providers.dart';
import '../widgets/voice_note_recorder.dart';
import '../widgets/voice_note_player.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});
  final String memoryId;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  late final TextEditingController _captionController;
  bool _editingCaption = false;
  bool _showRecorder = false;
  bool _uploadingVoice = false;
  bool _captionInitialized = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final memory = memories.where((m) => m.id == widget.memoryId).firstOrNull;
    final user = ref.watch(currentUserProvider);

    if (memory == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_captionInitialized && memory.caption != null) {
      _captionController.text = memory.caption!;
      _captionInitialized = true;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, memory.familyId),
            ),
        ],
      ),
      body: Column(
        children: [
          // Full-width photo
          Expanded(
            child: CachedNetworkImage(
              imageUrl: memory.photoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => CachedNetworkImage(
                imageUrl: memory.thumbnailUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Caption + tags panel
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Text(
                  _formatDate(memory.takenAt),
                  style: AppTextStyles.caption,
                ),
                // Tags
                if (memory.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: memory.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Text note section
                Row(
                  children: [
                    const Icon(Icons.edit_note,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Text note', style: AppTextStyles.label),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _editingCaption = true),
                  child: _editingCaption
                      ? TextField(
                          controller: _captionController,
                          autofocus: true,
                          style: AppTextStyles.body,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Write a note about this memory…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                          onSubmitted: (val) {
                            setState(() => _editingCaption = false);
                            if (user?.familyId != null) {
                              ref.read(memoryRepositoryProvider)
                                  .updateCaption(
                                      user!.familyId!, memory.id, val);
                            }
                          },
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.card,
                          ),
                          child: Text(
                            memory.caption?.isNotEmpty == true
                                ? memory.caption!
                                : 'Tap to add a note…',
                            style: memory.caption?.isNotEmpty == true
                                ? AppTextStyles.body
                                : AppTextStyles.bodySecondary,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Voice note section
                Row(
                  children: [
                    const Icon(Icons.mic,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Voice note', style: AppTextStyles.label),
                  ],
                ),
                const SizedBox(height: 6),
                if (memory.voiceNoteUrl != null)
                  VoiceNotePlayer(audioUrl: memory.voiceNoteUrl!)
                else if (_showRecorder)
                  VoiceNoteRecorder(
                    onRecorded: (file) =>
                        _uploadVoiceNote(file, memory.familyId, memory.id),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _showRecorder = true),
                    icon: _uploadingVoice
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.mic_none),
                    label: Text(
                      _uploadingVoice ? 'Uploading…' : 'Add voice note',
                      style: AppTextStyles.caption,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _uploadVoiceNote(File file, String familyId, String memoryId) async {
    setState(() {
      _showRecorder = false;
      _uploadingVoice = true;
    });
    try {
      await ref
          .read(memoryRepositoryProvider)
          .attachVoiceNote(familyId, memoryId, file);
    } catch (e) {
      AppLogger.e('Voice note upload failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVoice = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String familyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete memory?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(memoryRepositoryProvider)
          .deleteMemory(familyId, widget.memoryId);
    }
  }
}
