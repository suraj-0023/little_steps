import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../models/letter.dart';
import '../providers/letter_providers.dart';

class WriteLetterScreen extends ConsumerStatefulWidget {
  const WriteLetterScreen({super.key});

  @override
  ConsumerState<WriteLetterScreen> createState() => _WriteLetterScreenState();
}

class _WriteLetterScreenState extends ConsumerState<WriteLetterScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  DateTime _unlockAt = DateTime.now().add(const Duration(days: 365));
  bool _saving = false;
  bool _isPublic = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and message')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(letterRepositoryProvider);
      final iv = repo.generateIv();
      final encrypted = repo.encryptBody(
        _bodyCtrl.text.trim(),
        user!.familyId!,
        iv,
      );

      final letter = Letter(
        id: const Uuid().v4(),
        familyId: user.familyId!,
        babyId: baby.id,
        authorId: user.uid,
        title: _titleCtrl.text.trim(),
        encryptedBody: encrypted,
        iv: iv,
        createdAt: DateTime.now(),
        unlockAt: _unlockAt,
        isPublic: _isPublic,
      );

      await repo.saveLetter(user.familyId!, letter);
      if (mounted) context.pop();
    } catch (e) {
      AppLogger.e('Save letter failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Letter'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This letter is encrypted and will be sealed until the unlock date.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleCtrl,
              style: AppTextStyles.title,
              decoration: const InputDecoration(
                hintText: 'Letter title…',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
              maxLength: 100,
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: null,
              minLines: 12,
              style: AppTextStyles.storyBody,
              decoration: const InputDecoration(
                hintText: 'Dear little one,\n\nToday I want to tell you…',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('Unlock date', style: AppTextStyles.label),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_clock, color: AppColors.primary),
              title: Text(
                DateFormat('d MMMM yyyy').format(_unlockAt),
                style: AppTextStyles.body,
              ),
              subtitle: Text(
                _daysUntilLabel(),
                style: AppTextStyles.caption,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickUnlockDate,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _DateChip(label: '1 year', onTap: () => _setUnlock(365)),
                _DateChip(label: '5 years', onTap: () => _setUnlock(5 * 365)),
                _DateChip(label: '10 years', onTap: () => _setUnlock(10 * 365)),
                _DateChip(label: '18 years', onTap: () => _setUnlock(18 * 365)),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Public / private toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPublic ? 'Visible to all family' : 'Private to you',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPublic
                            ? 'All family members can read this letter once unlocked.'
                            : 'Only you can read this letter after the unlock date.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysUntilLabel() {
    final days = _unlockAt.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Unlocks today';
    if (days < 365) return 'In $days days';
    final years = (days / 365).floor();
    return 'In $years year${years != 1 ? "s" : ""}';
  }

  void _setUnlock(int days) {
    setState(() => _unlockAt = DateTime.now().add(Duration(days: days)));
  }

  Future<void> _pickUnlockDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _unlockAt,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _unlockAt = picked);
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: AppTextStyles.caption),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
    );
  }
}
