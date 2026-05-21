import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/app_shell.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/models/memory.dart';
import '../../memory/notifiers/upload_notifier.dart';
import '../../memory/providers/memory_providers.dart';
import '../../memory/widgets/memory_card.dart';
import '../widgets/on_this_day_card.dart';

class CollageScreen extends ConsumerWidget {
  const CollageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    final memoriesAsync = ref.watch(memoriesProvider);
    final grouped = ref.watch(memoriesByMonthProvider);
    final uploadState = ref.watch(uploadNotifierProvider);

    ref.listen(uploadNotifierProvider, (_, state) {
      if (state is UploadSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory saved!')),
        );
        ref.read(uploadNotifierProvider.notifier).reset();
      } else if (state is UploadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text((state).message),
              backgroundColor: AppColors.error),
        );
        ref.read(uploadNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
        title: Text(
          baby != null ? "${baby.displayName}'s Memory Book" : AppStrings.appName,
          style: AppTextStyles.title,
        ),
      ),
      body: memoriesAsync.when(
        loading: () => _ShimmerGrid(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (grouped.isEmpty) return _EmptyState();
          return _MasonryCollage(grouped: grouped);
        },
      ),
      // Icon-only FAB — no text label
      floatingActionButton: uploadState is UploadInProgress
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.6),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              ),
            )
          : FloatingActionButton(
              onPressed: () => _showUploadSheet(context, ref),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_a_photo, color: Colors.white),
            ),
    );
  }

  void _showUploadSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text(AppStrings.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text(AppStrings.chooseFromGallery),
                subtitle: const Text('Select multiple photos at once'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleAndUpload(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    if (ref.read(uploadNotifierProvider) is UploadInProgress) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked == null) return;
    await ref
        .read(uploadNotifierProvider.notifier)
        .uploadPhoto(File(picked.path));
  }

  Future<void> _pickMultipleAndUpload(
      BuildContext context, WidgetRef ref) async {
    if (ref.read(uploadNotifierProvider) is UploadInProgress) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked.isEmpty) return;
    // Upload one by one — each triggers its own upload notifier cycle
    for (final xFile in picked) {
      await ref
          .read(uploadNotifierProvider.notifier)
          .uploadPhoto(File(xFile.path));
    }
  }
}

// ── Masonry collage ───────────────────────────────────────────────

class _MasonryCollage extends StatelessWidget {
  const _MasonryCollage({required this.grouped});
  final Map<String, List<Memory>> grouped;

  @override
  Widget build(BuildContext context) {
    final months = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        const OnThisDayCard(),
        ...months.map((month) {
          final memories = grouped[month]!;
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Text(month, style: AppTextStyles.title),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${memories.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childCount: memories.length,
                  itemBuilder: (context, i) {
                    final memory = memories[i];
                    return AspectRatio(
                      aspectRatio: i % 3 == 0 ? 0.85 : 1.1,
                      child: MemoryCard(
                        memory: memory,
                        onTap: () => context.push('/memory/${memory.id}'),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          );
        }),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text(AppStrings.addFirstMemory, style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(
              AppStrings.addFirstMemorySubtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: 6,
        itemBuilder: (_, i) => Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: AspectRatio(
            aspectRatio: i % 3 == 0 ? 0.85 : 1.1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
