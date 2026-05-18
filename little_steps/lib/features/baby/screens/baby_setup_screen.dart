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
  final _nameFocus = FocusNode();

  DateTime? _selectedDob;
  File? _coverPhoto;
  bool _saving = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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
      initialDate: now.subtract(const Duration(days: 90)),
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
      helpText: "When was your baby born?",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _createBabyAndFamily() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDob == null) return;

    setState(() => _saving = true);
    try {
      final familyId = ref.read(newFamilyIdProvider);
      await ref.read(babyRepositoryProvider).createBaby(
            familyId: familyId,
            uid: user.uid,
            name: name,
            dob: _selectedDob!,
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
                    controller: _nameController,
                    focusNode: _nameFocus,
                    onNext: () {
                      if (_nameController.text.trim().isEmpty) return;
                      _nameFocus.unfocus();
                      _nextPage();
                    },
                  ),
                  _DobStep(
                    selectedDob: _selectedDob,
                    onPickDob: _pickDob,
                    onNext: () {
                      if (_selectedDob == null) return;
                      _nextPage();
                    },
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

// ── Step indicator ────────────────────────────────────────────────

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

// ── Step 1: Name ──────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.focusNode,
    required this.onNext,
  });

  final TextEditingController controller;
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
          Text("You can always change this later.",
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
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

// ── Step 2: Date of Birth ─────────────────────────────────────────

class _DobStep extends StatelessWidget {
  const _DobStep({
    required this.selectedDob,
    required this.onPickDob,
    required this.onNext,
  });

  final DateTime? selectedDob;
  final VoidCallback onPickDob;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text("When was your baby born?", style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text("Used to calculate milestones and age.",
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPickDob,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedDob != null
                      ? AppColors.primary
                      : AppColors.divider,
                  width: selectedDob != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.card,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    color: selectedDob != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedDob != null
                        ? "${selectedDob!.day} / ${selectedDob!.month} / ${selectedDob!.year}"
                        : AppStrings.babyDob,
                    style: selectedDob != null
                        ? AppTextStyles.title.copyWith(color: AppColors.primary)
                        : AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedDob != null ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Step 3: Cover Photo ───────────────────────────────────────────

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
          const Text("Add a cover photo", style: AppTextStyles.headline),
          const SizedBox(height: 8),
          Text("A photo of your baby for the memory book cover.",
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
