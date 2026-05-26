import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/baby/providers/selected_baby_provider.dart';
import '../features/baby/widgets/baby_switcher_sheet.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _mainItems = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/home'),
    (icon: Icons.timeline_outlined, activeIcon: Icons.timeline, label: 'Timeline', path: '/timeline'),
    (icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, label: 'Stories', path: '/stories'),
    (icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart, label: 'Growth', path: '/growth'),
  ];

  static const _featureItems = [
    (icon: Icons.mail_outline, activeIcon: Icons.mail, label: 'Letters to Future', path: '/letters'),
    (icon: Icons.picture_as_pdf_outlined, activeIcon: Icons.picture_as_pdf, label: 'Memory Albums', path: '/export'),
    (icon: Icons.play_circle_outline, activeIcon: Icons.play_circle, label: 'Photo Reel', path: '/reel'),
  ];

  static const _bottomItems = [
    (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Family Circle', path: '/family'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final allBabies = ref.watch(allBabiesProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedBabyIdProvider);
    final currentBaby = allBabies.where((b) => b.id == selectedId).firstOrNull
        ?? allBabies.firstOrNull;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header: baby profile + switcher ──────────────────────
            InkWell(
              onTap: allBabies.length > 1
                  ? () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => const BabySwitcherSheet(),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: currentBaby?.coverPhotoUrl != null
                          ? NetworkImage(currentBaby!.coverPhotoUrl!)
                          : null,
                      child: currentBaby?.coverPhotoUrl == null
                          ? Text(
                              currentBaby?.displayName.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBaby?.displayName ?? 'Baby',
                            style: AppTextStyles.title,
                          ),
                          if (currentBaby?.isUnborn == true)
                            Text('Due soon',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (allBabies.length > 1)
                      const Icon(Icons.swap_horiz,
                          color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // ── Main destinations ──────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._mainItems.map((item) => _DrawerTile(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: item.label,
                        selected: location == item.path ||
                            location.startsWith(item.path),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.path);
                        },
                      )),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  ..._featureItems.map((item) {
                    final comingSoon = item.path == '/export' || item.path == '/reel';
                    return _DrawerTile(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                      selected: !comingSoon &&
                          (location == item.path ||
                              location.startsWith(item.path)),
                      comingSoon: comingSoon,
                      onTap: () {
                        if (comingSoon) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.label} is coming soon!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop();
                          context.go(item.path);
                        }
                      },
                    );
                  }),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  ..._bottomItems.map((item) => _DrawerTile(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: item.label,
                        selected: location == item.path ||
                            location.startsWith(item.path),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.path);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.comingSoon = false,
  });
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconTheme(
        data: IconThemeData(
          color: comingSoon
              ? AppColors.textSecondary.withValues(alpha: 0.4)
              : selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
        ),
        child: selected ? selectedIcon : icon,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: comingSoon
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : selected
                        ? AppColors.primary
                        : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (comingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
