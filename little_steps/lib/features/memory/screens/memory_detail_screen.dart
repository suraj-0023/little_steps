import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/memory_providers.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});
  final String memoryId;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  late final TextEditingController _captionController;
  bool _editingCaption = false;

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

    if (_captionController.text.isEmpty && memory.caption != null) {
      _captionController.text = memory.caption!;
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
                // Caption
                GestureDetector(
                  onTap: () => setState(() => _editingCaption = true),
                  child: _editingCaption
                      ? TextField(
                          controller: _captionController,
                          autofocus: true,
                          style: AppTextStyles.body,
                          decoration: const InputDecoration(
                            hintText: 'Add a caption…',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            setState(() => _editingCaption = false);
                            if (user?.familyId != null) {
                              ref.read(memoryRepositoryProvider)
                                  .updateCaption(user!.familyId!, memory.id, val);
                            }
                          },
                        )
                      : Text(
                          memory.caption?.isNotEmpty == true
                              ? memory.caption!
                              : 'Add a caption…',
                          style: memory.caption?.isNotEmpty == true
                              ? AppTextStyles.body
                              : AppTextStyles.bodySecondary,
                        ),
                ),
                // Date
                const SizedBox(height: 8),
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
