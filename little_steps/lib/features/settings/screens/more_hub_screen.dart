import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../baby/providers/baby_providers.dart';

class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(currentBabyProvider).valueOrNull;

    final hubItems = [
      (
        icon: Icons.show_chart_outlined,
        title: 'Growth Journal',
        subtitle: 'Log heights & weights',
        path: '/growth',
        color: AppColors.primary,
      ),
      (
        icon: Icons.play_circle_outline,
        title: 'Photo Reel',
        subtitle: 'Watch video slideshows',
        path: '/reel',
        color: AppColors.secondary,
      ),
      (
        icon: Icons.favorite_border,
        title: 'Letters',
        subtitle: 'Write letters to your baby',
        path: '/letters',
        color: const Color(0xFFE08B8B),
      ),
      (
        icon: Icons.picture_as_pdf_outlined,
        title: 'Memory Albums',
        subtitle: 'Design custom AI scrapbooks',
        path: '/export',
        color: const Color(0xFF9E8E7D),
      ),
      (
        icon: Icons.people_outline,
        title: 'Family Circle',
        subtitle: 'Manage family permissions',
        path: '/family',
        color: const Color(0xFF7E8B83),
      ),
      (
        icon: Icons.calendar_today_outlined,
        title: 'Calendar',
        subtitle: 'Save activities & targets',
        path: '/calendar',
        color: const Color(0xFF8F7EAB),
      ),
    ];


    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'More to Explore',
                      style: AppTextStyles.display,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      baby != null
                          ? "Journal tools and circles for ${baby.displayName}"
                          : "Journal tools and account circles",
                      style: AppTextStyles.bodySecondary,
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = hubItems[index];
                    final comingSoon = item.path == '/export' || item.path == '/reel';
                    return _HubCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: comingSoon ? 'Coming soon!' : item.subtitle,
                      path: item.path,
                      color: item.color,
                      comingSoon: comingSoon,
                    )
                        .animate()
                        .fadeIn(delay: (200 + index * 60).ms, duration: 350.ms)
                        .slideY(begin: 0.15, end: 0);
                  },
                  childCount: hubItems.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider, width: 0.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Settings',
                                style: AppTextStyles.title.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage profiles, family preferences, and account',
                                style: AppTextStyles.caption.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.color,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String path;
  final Color color;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = comingSoon ? AppColors.textSecondary.withValues(alpha: 0.35) : color;
    return GestureDetector(
      onTap: () {
        if (comingSoon) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title is coming soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          context.push(path);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: 22,
                  ),
                ),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Soon',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                letterSpacing: -0.1,
                color: comingSoon ? AppColors.textSecondary.withValues(alpha: 0.5) : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 1.3,
                color: comingSoon ? AppColors.textSecondary.withValues(alpha: 0.4) : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
