// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../providers/family_providers.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  String? _code;
  UserRole _selectedRole = UserRole.editor;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateCode());
  }

  Future<void> _generateCode() async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    setState(() => _generating = true);
    try {
      final code = await ref.read(familyRepositoryProvider).createInvite(
            familyId: user!.familyId!,
            babyId: baby.id,
            createdByUid: user.uid,
            role: _selectedRole,
          );
      if (mounted) setState(() => _code = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate invite code'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied!')),
    );
  }

  void _share() {
    if (_code == null) return;
    SharePlus.instance.share(ShareParams(
      text: 'Join our baby memory book on LittleSteps! Use invite code: $_code\n\nOpen LittleSteps → Family → Join with code.',
      subject: 'LittleSteps Family Invite',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Family Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text('Share this code with a family member',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _RoleSelector(
              selected: _selectedRole,
              onChanged: (role) {
                setState(() {
                  _selectedRole = role;
                  _code = null;
                });
                _generateCode();
              },
            ),
            const SizedBox(height: 32),
            if (_generating)
              const CircularProgressIndicator()
            else if (_code != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _code!,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF6C3FC5),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF6C3FC5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('or share the code', style: AppTextStyles.bodySecondary),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_code!,
                          style: AppTextStyles.title.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 6,
                              fontSize: 28)),
                      const SizedBox(width: 12),
                      Icon(Icons.copy, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Tap to copy • Valid for 48 hours',
                  style: AppTextStyles.caption),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Invite'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite as', style: AppTextStyles.body),
        const SizedBox(height: 8),
        Row(
          children: [
            _RoleOption(
              role: UserRole.editor,
              label: 'Editor',
              subtitle: 'Can add & view',
              selected: selected,
              onTap: onChanged,
            ),
            const SizedBox(width: 8),
            _RoleOption(
              role: UserRole.viewer,
              label: 'Viewer',
              subtitle: 'Can only view',
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final UserRole role;
  final String label;
  final String subtitle;
  final UserRole selected;
  final ValueChanged<UserRole> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.body.copyWith(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}
