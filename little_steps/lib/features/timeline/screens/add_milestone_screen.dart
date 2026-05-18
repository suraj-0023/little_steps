// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../models/milestone.dart';
import '../providers/timeline_providers.dart';

class AddMilestoneScreen extends ConsumerStatefulWidget {
  const AddMilestoneScreen({super.key});

  @override
  ConsumerState<AddMilestoneScreen> createState() => _AddMilestoneScreenState();
}

class _AddMilestoneScreenState extends ConsumerState<AddMilestoneScreen> {
  MilestoneType _selectedType = MilestoneType.firstSmile;
  final _noteController = TextEditingController();
  DateTime _achievedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _achievedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _achievedAt = picked);
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(milestoneRepositoryProvider).addMilestone(
            familyId: user!.familyId!,
            babyId: baby.id,
            type: _selectedType,
            title: _selectedType == MilestoneType.custom &&
                    _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : _selectedType.label,
            achievedAt: _achievedAt,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Milestone')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select milestone', style: AppTextStyles.body),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MilestoneType.values.map((type) {
                final selected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? type.color.withValues(alpha: 0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? type.color
                            : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji),
                        const SizedBox(width: 6),
                        Text(type.label,
                            style: AppTextStyles.caption.copyWith(
                                color: selected ? type.color : null,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : null)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('When did it happen?', style: AppTextStyles.body),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.card,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_achievedAt.day}/${_achievedAt.month}/${_achievedAt.year}',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'e.g. First said "mama" at breakfast!',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Milestone'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
