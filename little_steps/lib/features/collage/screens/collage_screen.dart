import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/models/memory.dart';
import '../../memory/notifiers/upload_notifier.dart';
import '../../memory/providers/memory_providers.dart';
import '../../memory/widgets/memory_card.dart';
import '../widgets/on_this_day_card.dart';


// Wrapper widget to hold original body content for Stack
class _CollageBody extends StatelessWidget {
  const _CollageBody({required this.memoriesAsync, required this.grouped});
  final AsyncValue<List<Memory>> memoriesAsync;
  final Map<String, List<Memory>> grouped;

  @override
  Widget build(BuildContext context) {
    return memoriesAsync.when(
      loading: () => _ShimmerGrid(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (_) {
        if (grouped.isEmpty) return _EmptyState();
        return _MasonryCollage(grouped: grouped);
      },
    );
  }
}


class CollageScreen extends ConsumerWidget {
  const CollageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    final memoriesAsync = ref.watch(memoriesProvider);
    final grouped = ref.watch(memoriesByMonthProvider);

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
      body: _CollageBody(memoriesAsync: memoriesAsync, grouped: grouped),
      appBar: AppBar(
        title: Text(
          baby != null
              ? "${(baby.nickname != null && baby.nickname!.isNotEmpty) ? baby.nickname : baby.displayName}'s Memory Book"
              : AppStrings.appName,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
        actions: [],
      ),
    );
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
                      Expanded(
                        child: _DottedDivider(
                          color: AppColors.textSecondary.withValues(alpha: 0.25),
                          dotRadius: 1.0,
                          spacing: 3.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              month,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${memories.length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _DottedDivider(
                          color: AppColors.textSecondary.withValues(alpha: 0.25),
                          dotRadius: 1.0,
                          spacing: 3.5,
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
                    )
                        .animate()
                        .fadeIn(
                          duration: 450.ms,
                          delay: (i * 45).clamp(0, 550).ms,
                        )
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          );
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for floating bottom nav dock
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

class _DottedDivider extends StatelessWidget {
  const _DottedDivider({
    required this.color,
    required this.dotRadius,
    required this.spacing,
  });

  final Color color;
  final double dotRadius;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(
        color: color,
        dotRadius: dotRadius,
        spacing: spacing,
      ),
      child: const SizedBox(height: 1),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({
    required this.color,
    required this.dotRadius,
    required this.spacing,
  });

  final Color color;
  final double dotRadius;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double startX = 0;
    final double y = size.height / 2;

    while (startX < size.width) {
      canvas.drawCircle(Offset(startX + dotRadius, y), dotRadius, paint);
      startX += 2 * dotRadius + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
