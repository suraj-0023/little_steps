// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/baby_providers.dart';

class BabySetupScreen extends ConsumerStatefulWidget {
  const BabySetupScreen({super.key});

  @override
  ConsumerState<BabySetupScreen> createState() => _BabySetupScreenState();
}

class _BabySetupScreenState extends ConsumerState<BabySetupScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _nameFocus = FocusNode();

  DateTime? _selectedDob;
  DateTime? _expectedDeliveryDate;
  bool _isUnborn = false;
  File? _coverPhoto;
  bool _saving = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _coverPhoto = File(picked.path));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
      helpText: 'When was your baby born?',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _pickEdd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 300)),
      helpText: 'Expected delivery date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expectedDeliveryDate = picked);
  }

  Future<void> _createBabyAndFamily() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final familyId = ref.read(newFamilyIdProvider);
      await ref.read(babyRepositoryProvider).createBaby(
            familyId: familyId,
            uid: user.uid,
            name: name,
            nickname: _nicknameController.text.trim().isEmpty
                ? null
                : _nicknameController.text.trim(),
            dob: _isUnborn ? null : _selectedDob,
            isUnborn: _isUnborn,
            expectedDeliveryDate: _isUnborn ? _expectedDeliveryDate : null,
            coverPhoto: _coverPhoto,
          );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      AppLogger.e('Baby setup failed', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.genericError),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(current: _currentPage),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _NameStep(
                    nameController: _nameController,
                    nicknameController: _nicknameController,
                    focusNode: _nameFocus,
                    onNext: () {
                      if (_nameController.text.trim().isEmpty) return;
                      _nameFocus.unfocus();
                      _nextPage();
                    },
                  ),
                  _DobStep(
                    selectedDob: _selectedDob,
                    expectedDeliveryDate: _expectedDeliveryDate,
                    isUnborn: _isUnborn,
                    onToggleUnborn: (v) => setState(() => _isUnborn = v),
                    onPickDob: _pickDob,
                    onPickEdd: _pickEdd,
                    onNext: _nextPage,
                  ),
                  _PhotoStep(
                    coverPhoto: _coverPhoto,
                    onPickPhoto: _pickPhoto,
                    onSkip: _createBabyAndFamily,
                    onFinish: _createBabyAndFamily,
                    saving: _saving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: (active || done) ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Name + Nickname ────────────────────────────────────────

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.nameController,
    required this.nicknameController,
    required this.focusNode,
    required this.onNext,
  });

  final TextEditingController nameController;
  final TextEditingController nicknameController;
  final FocusNode focusNode;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text("What's your baby's name?", style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text('You can always change this later.',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: 32),
          TextField(
            controller: nameController,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.title,
            decoration: const InputDecoration(
              hintText: AppStrings.babyName,
              prefixIcon: Icon(Icons.child_care_outlined),
            ),
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nicknameController,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              hintText: 'Nickname (optional) — e.g. Cub, Bunny',
              prefixIcon: Icon(Icons.favorite_outline),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The nickname can be set as the display name in the app.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/join'),
              child: const Text('Have an invite code? Join a family'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Step 2: Date of Birth (optional) ──────────────────────────────

class _DobStep extends StatelessWidget {
  const _DobStep({
    required this.selectedDob,
    required this.expectedDeliveryDate,
    required this.isUnborn,
    required this.onToggleUnborn,
    required this.onPickDob,
    required this.onPickEdd,
    required this.onNext,
  });

  final DateTime? selectedDob;
  final DateTime? expectedDeliveryDate;
  final bool isUnborn;
  final ValueChanged<bool> onToggleUnborn;
  final VoidCallback onPickDob;
  final VoidCallback onPickEdd;
  final VoidCallback onNext;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            isUnborn ? 'When is the baby due?' : 'When was your baby born?',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 8),
          Text(
            'Used to calculate milestones and age.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          // Unborn toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.pregnant_woman_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Baby is not born yet',
                      style: AppTextStyles.body),
                ),
                Switch(
                  value: isUnborn,
                  onChanged: onToggleUnborn,
                  thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isUnborn) ...[
            GestureDetector(
              onTap: onPickDob,
              child: _DateField(
                icon: Icons.cake_outlined,
                label: selectedDob != null
                    ? _fmt(selectedDob!)
                    : AppStrings.babyDob,
                isSet: selectedDob != null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional — you can add this later.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            GestureDetector(
              onTap: onPickEdd,
              child: _DateField(
                icon: Icons.event_outlined,
                label: expectedDeliveryDate != null
                    ? 'Due ${_fmt(expectedDeliveryDate!)}'
                    : 'Set expected delivery date',
                isSet: expectedDeliveryDate != null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll remind you to update the birth date after the due date arrives.",
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.icon,
    required this.label,
    required this.isSet,
  });
  final IconData icon;
  final String label;
  final bool isSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSet ? AppColors.primary : AppColors.divider,
          width: isSet ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.card,
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isSet ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: isSet
                ? AppTextStyles.title.copyWith(color: AppColors.primary)
                : AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Cover Photo ────────────────────────────────────────────

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.coverPhoto,
    required this.onPickPhoto,
    required this.onSkip,
    required this.onFinish,
    required this.saving,
  });

  final File? coverPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onSkip;
  final VoidCallback onFinish;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('Add a cover photo', style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text('A photo of your baby for the memory book cover.',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: onPickPhoto,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  image: coverPhoto != null
                      ? DecorationImage(
                          image: FileImage(coverPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 36, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(AppStrings.addCoverPhoto,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                              textAlign: TextAlign.center),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const Spacer(),
          saving
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onFinish,
                        child: const Text(AppStrings.createMemoryBook),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onSkip,
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
