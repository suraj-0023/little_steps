import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/baby.dart';
import '../providers/selected_baby_provider.dart';

class BabySwitcherSheet extends ConsumerWidget {
  const BabySwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babiesAsync = ref.watch(allBabiesProvider);
    final selectedId = ref.watch(selectedBabyIdProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Select Baby', style: AppTextStyles.headline),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: babiesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('Error loading babies')),
                data: (babies) => ListView.builder(
                  controller: scrollCtrl,
                  itemCount: babies.length,
                  itemBuilder: (_, i) =>
                      _BabyTile(baby: babies[i], selected: babies[i].id == selectedId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BabyTile extends ConsumerWidget {
  const _BabyTile({required this.baby, required this.selected});
  final Baby baby;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage: baby.coverPhotoUrl != null
            ? CachedNetworkImageProvider(baby.coverPhotoUrl!)
            : null,
        child: baby.coverPhotoUrl == null
            ? Text(baby.firstName[0].toUpperCase(),
                style: AppTextStyles.title.copyWith(color: AppColors.primary))
            : null,
      ),
      title: Text(baby.name, style: AppTextStyles.body),
      subtitle: Text(
          baby.dob != null ? _ageLabel(baby.dob!) : (baby.isUnborn ? 'Due soon' : ''),
          style: AppTextStyles.caption),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(selectedBabyIdProvider.notifier).select(baby.id);
        Navigator.of(context).pop();
      },
    );
  }

  String _ageLabel(DateTime dob) {
    final age = DateTime.now().difference(dob);
    final months = (age.inDays / 30.44).floor();
    if (months < 1) return '${age.inDays} days old';
    if (months < 24) return '$months month${months != 1 ? "s" : ""} old';
    final years = (months / 12).floor();
    return '$years year${years != 1 ? "s" : ""} old';
  }
}
