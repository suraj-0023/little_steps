// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/app_shell.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    final isEditor = user?.role == UserRole.admin ||
        user?.role == UserRole.editor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
      ),
      body: ListView(
        children: [
          // Account
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: user?.photoUrl.isNotEmpty == true
                ? CircleAvatar(
                    backgroundImage: NetworkImage(user!.photoUrl),
                  )
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.displayName ?? 'User', style: AppTextStyles.body),
            subtitle:
                Text(user?.email ?? '', style: AppTextStyles.caption),
          ),
          const Divider(indent: 16, endIndent: 16),

          // Baby profile
          if (baby != null) ...[
            _SectionHeader(title: 'Baby Profile'),
            ListTile(
              leading:
                  const Icon(Icons.child_care, color: AppColors.primary),
              title: Text(baby.name, style: AppTextStyles.body),
              subtitle: Text(
                baby.dob != null
                    ? 'Born ${_formatDate(baby.dob!)}'
                    : baby.isUnborn
                        ? baby.expectedDeliveryDate != null
                            ? 'Due ${_formatDate(baby.expectedDeliveryDate!)}'
                            : 'Not born yet'
                        : 'Birthday not set',
                style: AppTextStyles.caption,
              ),
            ),
            if (baby.nickname != null) ...[
              // Nickname display toggle — editor/admin only, family-wide
              ListTile(
                leading: const Icon(Icons.favorite_outline,
                    color: AppColors.primary),
                title: Text(
                  'Show nickname "${baby.nickname}"',
                  style: AppTextStyles.body,
                ),
                subtitle: Text(
                  isEditor
                      ? 'Changes display name for all family members'
                      : 'Only editors can change this',
                  style: AppTextStyles.caption,
                ),
                trailing: Switch(
                  value: baby.useNicknameDisplay,
                  onChanged: isEditor
                      ? (val) async {
                          try {
                            await ref
                                .read(babyRepositoryProvider)
                                .updateBaby(
                                    baby.copyWith(useNicknameDisplay: val));
                          } catch (e) {
                            AppLogger.e('Update display name pref failed', e);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text(AppStrings.genericError)),
                              );
                            }
                          }
                        }
                      : null,
                  thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
                ),
              ),
            ],
            const Divider(indent: 16, endIndent: 16),
          ],

          // Support
          _SectionHeader(title: 'Support'),
          _NavTile(
            icon: Icons.star_outline,
            title: 'Rate LittleSteps',
            onTap: () {/* TODO: Play Store link */},
          ),
          _NavTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {/* TODO: open URL */},
          ),
          _NavTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => _showAbout(context),
          ),
          const Divider(indent: 16, endIndent: 16),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text('Sign out',
                style: AppTextStyles.body.copyWith(color: AppColors.error)),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 40),
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

  Future<void> _showAbout(BuildContext context) async {
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion:
          info != null ? 'v${info.version}+${info.buildNumber}' : '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text(
            'A beautiful baby memory book with AI-powered monthly stories.'),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your memories stay safe in the cloud.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.signOut)),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(authRepositoryProvider).signOut();
        if (context.mounted) context.go('/auth');
      } catch (e) {
        AppLogger.e('Sign out failed', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sign out failed. Please try again.')),
          );
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title.toUpperCase(), style: AppTextStyles.label),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
