import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/parent_profile_service.dart';
import '../../../core/utils/app_logger.dart';

class ParentProfileEditScreen extends ConsumerStatefulWidget {
  const ParentProfileEditScreen({super.key});

  @override
  ConsumerState<ParentProfileEditScreen> createState() => _ParentProfileEditScreenState();
}

class _ParentProfileEditScreenState extends ConsumerState<ParentProfileEditScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final service = ref.read(parentProfileServiceProvider);
    final data = await service.loadProfiles();
    if (mounted) {
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(
          (data['profiles'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
        // Ensure at least Mother and Father are present
        if (!_profiles.any((p) => p['role'] == 'Mother')) {
          _profiles.insert(0, {'role': 'Mother', 'name': '', 'details': ''});
        }
        if (!_profiles.any((p) => p['role'] == 'Father')) {
          final index = _profiles.indexWhere((p) => p['role'] == 'Mother');
          _profiles.insert(index + 1, {'role': 'Father', 'name': '', 'details': ''});
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveProfiles() async {
    setState(() => _saving = true);
    final service = ref.read(parentProfileServiceProvider);
    try {
      await service.saveProfiles({'profiles': _profiles});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Parent profiles saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.e('Failed to save parent profiles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addFamilyMember() {
    setState(() {
      _profiles.add({'role': 'Grandparent', 'name': '', 'details': ''});
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _profiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Parent & Family Profiles', style: AppTextStyles.title),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfiles,
              child: Text(
                'Save',
                style: AppTextStyles.button.copyWith(color: AppColors.primaryDark),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Visual Details for AI Recognition',
              style: AppTextStyles.headline.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Describe the physical features of the parents and close family members (hair, beard, glasses, etc.). The AI uses these clues to correctly identify who is who in your photos instead of writing generic descriptions.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._profiles.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final role = p['role'] ?? 'Parent';
              final isDefaultRole = role == 'Mother' || role == 'Father';

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider, width: 0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDefaultRole ? Icons.favorite : Icons.person_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        if (isDefaultRole)
                          Text(
                            role,
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          )
                        else
                          Expanded(
                            child: TextFormField(
                              initialValue: role,
                              onChanged: (val) => p['role'] = val.trim(),
                              decoration: const InputDecoration(
                                labelText: 'Relation/Role',
                                hintText: 'e.g. Sibling, Grandparent',
                                isDense: true,
                              ),
                              style: AppTextStyles.title.copyWith(fontSize: 16),
                            ),
                          ),
                        if (!isDefaultRole) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () => _removeFamilyMember(index),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: p['name'] ?? '',
                      onChanged: (val) => p['name'] = val.trim(),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                        hintText: 'Enter name',
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: p['details'] ?? '',
                      onChanged: (val) => p['details'] = val.trim(),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Appearance & Face Details',
                        labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                        hintText: 'e.g., Long dark wavy hair, wears thin glasses, warm brown eyes, clean-shaven.',
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addFamilyMember,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Add Family Member'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                'Save Profiles'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
