import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/on_this_day_provider.dart';

class OnThisDayCard extends ConsumerWidget {
  const OnThisDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(onThisDayProvider);
    if (memories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final yearsAgo = DateTime.now().year - memories.first.takenAt.year;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined,
                    color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'On This Day · $yearsAgo ${yearsAgo == 1 ? 'year' : 'years'} ago',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: memories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final m = memories[i];
                  return GestureDetector(
                    onTap: () => context.push('/memory/${m.id}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: m.thumbnailUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.shimmerBase),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
