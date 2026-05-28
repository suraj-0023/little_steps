// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../providers/baby_providers.dart';
import '../models/baby.dart';

class BabyProfileEditScreen extends ConsumerStatefulWidget {
  const BabyProfileEditScreen({super.key});

  @override
  ConsumerState<BabyProfileEditScreen> createState() => _BabyProfileEditScreenState();
}

class _BabyProfileEditScreenState extends ConsumerState<BabyProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _molesController = TextEditingController();

  DateTime? _selectedDob;
  String? _birthTime;
  String _bloodGroup = 'Unknown';
  File? _pickedCoverPhoto;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _molesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _pickedCoverPhoto = File(picked.path));
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now,
      helpText: 'Date of birth',
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _birthTime = picked.format(context));
    }
  }

  Future<void> _saveProfile(Baby baby) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String? coverPhotoUrl = baby.coverPhotoUrl;
      if (_pickedCoverPhoto != null) {
        coverPhotoUrl = await ref
            .read(babyRepositoryProvider)
            .uploadCoverPhoto(baby.familyId, baby.id, _pickedCoverPhoto!);
      }

      final updatedBaby = baby.copyWith(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim(),
        dob: _selectedDob,
        bloodGroup: _bloodGroup == 'Unknown' ? null : _bloodGroup,
        birthTime: _birthTime,
        birthHeight: double.tryParse(_heightController.text),
        birthWeight: double.tryParse(_weightController.text),
        moles: _molesController.text.trim().isEmpty
            ? null
            : _molesController.text.trim(),
        coverPhotoUrl: coverPhotoUrl,
      );

      await ref.read(babyRepositoryProvider).updateBaby(updatedBaby);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baby profile saved!')),
      );
      context.pop();
    } catch (e) {
      AppLogger.e('Failed to save baby profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.genericError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year}';

  @override
  Widget build(BuildContext context) {
    final babyState = ref.watch(currentBabyProvider);
    final baby = babyState.valueOrNull;

    if (baby != null && !_initialized) {
      _nameController.text = baby.name;
      _nicknameController.text = baby.nickname ?? '';
      _selectedDob = baby.dob;
      _birthTime = baby.birthTime;
      _bloodGroup = baby.bloodGroup ?? 'Unknown';
      _heightController.text = baby.birthHeight?.toString() ?? '';
      _weightController.text = baby.birthWeight?.toString() ?? '';
      _molesController.text = baby.moles ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Baby Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: baby == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover photo selection centerpiece
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  width: 2.5,
                                ),
                                image: _pickedCoverPhoto != null
                                    ? DecorationImage(
                                        image: FileImage(_pickedCoverPhoto!),
                                        fit: BoxFit.cover,
                                      )
                                    : (baby.coverPhotoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(baby.coverPhotoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: _pickedCoverPhoto == null && baby.coverPhotoUrl == null
                                  ? const Icon(Icons.child_care, size: 50, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                onPressed: _pickPhoto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs Section
                    Text('General Info'.toUpperCase(), style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.body,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nicknameController,
                      style: AppTextStyles.body,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nickname (uses as the memory book title)',
                        prefixIcon: Icon(Icons.favorite_border),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date of Birth & Time pickers
                    Text('Birth Details'.toUpperCase(), style: AppTextStyles.label),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDob,
                            child: _StyledSelectTile(
                              icon: Icons.cake_outlined,
                              label: _selectedDob != null ? _fmtDate(_selectedDob!) : 'Date of Birth',
                              isSet: _selectedDob != null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: _StyledSelectTile(
                              icon: Icons.access_time,
                              label: _birthTime ?? 'Birth Time',
                              isSet: _birthTime != null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Blood group selection
                    DropdownButtonFormField<String>(
                      initialValue: _bloodGroup,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        prefixIcon: Icon(Icons.bloodtype_outlined),
                      ),
                      items: ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _bloodGroup = v ?? 'Unknown'),
                    ),
                    const SizedBox(height: 16),

                    // Height and weight measurements
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              labelText: 'Birth Height',
                              suffixText: 'cm',
                              prefixIcon: Icon(Icons.height_outlined),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
                                return 'Enter a number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              labelText: 'Birth Weight',
                              suffixText: 'kg',
                              prefixIcon: Icon(Icons.monitor_weight_outlined),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
                                return 'Enter a number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Moles / Marks description
                    Text('Physical Characteristics'.toUpperCase(), style: AppTextStyles.label),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _molesController,
                      style: AppTextStyles.body,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Moles, birthmarks, or special features',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.color_lens_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save CTA button
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () => _saveProfile(baby),
                              child: const Text('Save Changes'),
                            ),
                          ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StyledSelectTile extends StatelessWidget {
  const _StyledSelectTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSet ? AppColors.primary.withValues(alpha: 0.8) : AppColors.divider,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.card,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSet ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: isSet
                  ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)
                  : AppTextStyles.bodySecondary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
