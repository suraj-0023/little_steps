import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'offline_banner.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/memory/notifiers/upload_notifier.dart';
import '../features/baby/providers/baby_providers.dart';
import '../features/baby/widgets/baby_switcher_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final uploadState = ref.watch(uploadNotifierProvider);

    // Determine selected tab index based on route location
    int selectedIndex = 0;
    if (location.startsWith('/timeline')) {
      selectedIndex = 1;
    } else if (location.startsWith('/stories')) {
      selectedIndex = 2;
    } else if (location.startsWith('/more') ||
               location.startsWith('/settings') ||
               location.startsWith('/family') ||
               location.startsWith('/growth') ||
               location.startsWith('/export') ||
               location.startsWith('/reel') ||
               location.startsWith('/letters')) {
      selectedIndex = 3;
    }

    final navigationItems = [
      (icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Collage', path: '/home'),
      (icon: Icons.timeline_outlined, activeIcon: Icons.timeline, label: 'Timeline', path: '/timeline'),
      (icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, label: 'Stories', path: '/stories'),
      (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'More', path: '/more'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        try {
          if (location != '/home') {
            context.go('/home');
          }
        } catch (_) {
          // Ignore if GoRouter not in scope
        }
      },
      child: Scaffold(
        extendBody: true, // Content scrolls behind bottom nav bar
        body: OfflineBanner(child: child),
        // Floating + button — only visible on Collage screen
        floatingActionButton: location.startsWith('/home')
            ? (uploadState is UploadInProgress
                ? FloatingActionButton.small(
                    onPressed: null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.7),
                    elevation: 4,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.0, color: Colors.white),
                    ),
                  )
                : FloatingActionButton.small(
                    onPressed: () => _showUploadSheet(context, ref),
                    backgroundColor: AppColors.primary,
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ))
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildNavItem(context, 0, navigationItems[0], selectedIndex == 0),
                          _buildNavItem(context, 1, navigationItems[1], selectedIndex == 1),
                          const SizedBox(width: 72), // Gap for the popping avatar
                          _buildNavItem(context, 2, navigationItems[2], selectedIndex == 2),
                          _buildNavItem(context, 3, navigationItems[3], selectedIndex == 3),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -24, // Elevates the avatar above the bar
                  child: _buildCentreAvatar(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    ({IconData activeIcon, IconData icon, String label, String path}) item,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(item.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentreAvatar(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const BabySwitcherSheet(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: baby?.coverPhotoUrl != null
              ? NetworkImage(baby!.coverPhotoUrl!)
              : null,
          child: baby?.coverPhotoUrl == null
              ? Text(
                  baby?.displayName.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                )
              : null,
        ),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from Gallery'),
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
    await ref.read(uploadNotifierProvider.notifier).uploadPhoto(File(picked.path));
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
    for (final xFile in picked) {
      await ref.read(uploadNotifierProvider.notifier).uploadPhoto(File(xFile.path));
    }
  }
}
