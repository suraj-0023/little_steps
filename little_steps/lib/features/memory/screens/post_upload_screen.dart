// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/memory_providers.dart';
import '../widgets/voice_note_recorder.dart';
import '../widgets/voice_note_player.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../models/memory.dart';

class UploadItem {
  UploadItem({required this.memoryId, required this.file});
  final String memoryId;
  final File file;
}

class PostUploadScreen extends ConsumerStatefulWidget {
  const PostUploadScreen({super.key, required this.uploadItems});
  final List<UploadItem> uploadItems;

  @override
  ConsumerState<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends ConsumerState<PostUploadScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch memories to get latest updates
    final allMemories = ref.watch(memoriesProvider).valueOrNull ?? [];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Add Details',
          style: AppTextStyles.headline.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.uploadItems.length,
        itemBuilder: (context, index) {
          final item = widget.uploadItems[index];
          final memory = allMemories.where((m) => m.id == item.memoryId).firstOrNull;
          return _PostUploadMemoryPage(item: item, memory: memory);
        },
      ),
    );
  }
}

class _PostUploadMemoryPage extends ConsumerStatefulWidget {
  const _PostUploadMemoryPage({required this.item, this.memory});
  final UploadItem item;
  final Memory? memory;

  @override
  ConsumerState<_PostUploadMemoryPage> createState() => _PostUploadMemoryPageState();
}

class _PostUploadMemoryPageState extends ConsumerState<_PostUploadMemoryPage> {
  late final TextEditingController _captionController;
  bool _editingCaption = false;
  bool _showRecorder = false;
  bool _uploadingVoice = false;
  bool _captionInitialized = false;
  bool _isPolishing = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _captionController.dispose();
    super.dispose();
  }

  void _scheduleSave(String val, String familyId, String memoryId) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1200), () async {
      try {
        await ref.read(memoryRepositoryProvider).updateCaption(familyId, memoryId, val);
      } catch (e) {
        AppLogger.e('Failed to save caption', e);
      }
    });
  }

  Future<void> _polishNote() async {
    final currentText = _captionController.text.trim();
    if (currentText.isEmpty) return;

    setState(() => _isPolishing = true);
    try {
      final gemini = ref.read(geminiVisionServiceProvider);
      final polished = await gemini.polishMemoryNotes(currentText);
      if (polished != currentText && mounted) {
        setState(() {
          _captionController.text = polished;
          _editingCaption = true;
        });
        final user = ref.read(currentUserProvider);
        if (user?.familyId != null) {
          _scheduleSave(polished, user!.familyId!, widget.item.memoryId);
        }
      }
    } catch (e) {
      AppLogger.e('Error polishing note', e);
    } finally {
      if (mounted) setState(() => _isPolishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final user = ref.watch(currentUserProvider);

    if (!_captionInitialized && memory != null && memory.caption != null) {
      _captionController.text = memory.caption!;
      _captionInitialized = true;
    }

    return Column(
      children: [
        // Full-width photo
        Expanded(
          child: memory != null 
            ? CachedNetworkImage(
                imageUrl: memory.photoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Image.file(
                  widget.item.file,
                  fit: BoxFit.contain,
                ),
              )
            : Image.file(
                widget.item.file,
                fit: BoxFit.contain,
              ),
        ),
        // Caption + tags panel
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker Pill
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: memory?.takenAt ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (newDate != null && user?.familyId != null && memory != null) {
                        ref.read(memoryRepositoryProvider).updateDate(user!.familyId!, memory.id, newDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryDark),
                          const SizedBox(width: 8),
                          Text(
                            memory != null ? _formatDate(memory.takenAt) : _formatDate(DateTime.now()),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (memory != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, size: 14, color: AppColors.primaryDark),
                          ] else ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Text note section
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Story', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                  const Spacer(),
                  if (_captionController.text.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _isPolishing ? null : _polishNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: _isPolishing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('✨'),
                      label: const Text('Polish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_editingCaption)
                    TextButton(
                      onPressed: () => setState(() => _editingCaption = false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _editingCaption
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
                        ]
                      ),
                      child: TextField(
                        controller: _captionController,
                        autofocus: true,
                        style: AppTextStyles.body.copyWith(height: 1.5, fontSize: 15),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Write the story behind this moment...',
                          hintStyle: AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (val) {
                          if (user?.familyId != null) {
                            _scheduleSave(val, user!.familyId!, widget.item.memoryId);
                          }
                        },
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _editingCaption = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Text(
                          _captionController.text.isNotEmpty
                              ? _captionController.text
                              : 'Tap to write the story behind this moment...',
                          style: _captionController.text.isNotEmpty
                              ? AppTextStyles.body.copyWith(height: 1.5, fontSize: 15)
                              : AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Voice note section
              Row(
                children: [
                  const Icon(Icons.mic_rounded, size: 22, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Voice Note', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              if (memory?.voiceNoteUrl != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: VoiceNotePlayer(audioUrl: memory!.voiceNoteUrl!)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Delete voice note',
                      onPressed: () => _deleteVoiceNote(memory.familyId, memory.id),
                    ),
                  ],
                ),
                if (memory.voiceNoteTranscription != null && memory.voiceNoteTranscription!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 32, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          memory.voiceNoteTranscription!,
                          style: AppTextStyles.body.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.primaryDark,
                            height: 1.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (_showRecorder && memory != null)
                VoiceNoteRecorder(
                  onRecorded: (file) =>
                      _uploadVoiceNote(file, memory.familyId, memory.id),
                )
              else
                InkWell(
                  onTap: memory == null ? null : () => setState(() => _showRecorder = true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        _uploadingVoice
                            ? const CircularProgressIndicator(color: AppColors.primary)
                            : const Icon(Icons.mic_none_rounded, size: 36, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          _uploadingVoice ? 'Uploading…' : (memory == null ? 'Wait to add voice' : 'Record a voice note'),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryDark, 
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _deleteVoiceNote(String familyId, String memoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete voice note?'),
        content: const Text('This will permanently delete the audio recording and transcription.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      try {
        await ref.read(memoryRepositoryProvider).deleteVoiceNote(familyId, memoryId);
      } catch (e) {
        AppLogger.e('Failed to delete voice note', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.genericError)),
          );
        }
      }
    }
  }

  Future<void> _uploadVoiceNote(File file, String familyId, String memoryId) async {
    if (!mounted) return;
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
}
