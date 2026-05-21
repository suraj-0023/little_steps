// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/app_shell.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/models/baby.dart';
import '../../baby/providers/baby_providers.dart';
import '../providers/family_providers.dart';
import '../widgets/member_tile.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  String? _inviteCode;
  bool _generatingCode = false;
  bool _childCodeRevealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateWeeklyCode());
  }

  Future<void> _generateWeeklyCode() async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    setState(() => _generatingCode = true);
    try {
      final code = await ref.read(familyRepositoryProvider).createInvite(
            familyId: user!.familyId!,
            babyId: baby.id,
            createdByUid: user.uid,
            role: UserRole.editor,
          );
      if (mounted) setState(() => _inviteCode = code);
    } catch (e) {
      // Error is logged but not shown to user; they can retry with "Retry" button
    } finally {
      if (mounted) setState(() => _generatingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final baby = ref.watch(currentBabyProvider).valueOrNull;

    ref.listen(currentUserProvider, (_, u) {
      if (u?.familyId != null) {
        ref.read(familyRepositoryProvider).ensureAdminMemberDoc(
              u!.familyId!,
              u,
            ).ignore(); // Fire and forget; errors are not fatal
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Invite options',
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Members ───────────────────────────────────────────────
          Text('Members', style: AppTextStyles.label),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) => members.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No members yet.',
                        style: AppTextStyles.bodySecondary),
                  )
                : Column(
                    children: members
                        .map((m) => MemberTile(
                              member: m,
                              isCurrentUser: m.uid == user?.uid,
                            ))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // ── Invite via QR ─────────────────────────────────────────
          Text('Invite to Family', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _generatingCode
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _inviteCode == null
                      ? Column(
                          children: [
                            const Text('Could not generate invite code.',
                                style: AppTextStyles.bodySecondary),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _generateWeeklyCode,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // QR code
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _inviteCode!,
                                version: QrVersions.auto,
                                size: 160,
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
                            const SizedBox(height: 16),
                            Text(
                              'Scan to join · or share the code below',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Code display
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: _inviteCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Code copied!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _inviteCode!,
                                      style: AppTextStyles.title.copyWith(
                                          color: AppColors.primary,
                                          letterSpacing: 4),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.copy,
                                        color: AppColors.primary, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Tap code to copy · Valid for 48 hours',
                                style: AppTextStyles.caption),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        SharePlus.instance.share(ShareParams(
                                      text:
                                          'Join our family on LittleSteps! Code: $_inviteCode',
                                    )),
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Share'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        context.push('/family/invite'),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: const Text('Options'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Child Access Code ─────────────────────────────────────
          if (baby != null && baby.childCode != null) ...[
            Text('Child Access', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _ChildCodeCard(
              baby: baby,
              revealed: _childCodeRevealed,
              onReveal: () => setState(() => _childCodeRevealed = true),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ── Child Code Card ───────────────────────────────────────────────

class _ChildCodeCard extends StatelessWidget {
  const _ChildCodeCard({
    required this.baby,
    required this.revealed,
    required this.onReveal,
  });

  final Baby baby;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final dob = baby.dob;
    final code = baby.childCode!;
    final name = baby.displayName;

    int? daysUntilSeven;
    bool hasUnlocked = false;

    if (dob != null) {
      final seventhBirthday = DateTime(dob.year + 7, dob.month, dob.day);
      final diff = seventhBirthday.difference(DateTime.now()).inDays;
      if (diff > 0) {
        daysUntilSeven = diff;
      } else {
        hasUnlocked = true;
      }
    }

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasUnlocked ? Icons.lock_open : Icons.lock_outline,
                  color: hasUnlocked ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasUnlocked
                        ? 'Ready to share with $name'
                        : 'Locked until $name turns 7',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dob == null) ...[
              Text(
                'Set $name\'s birthday to see the child access code countdown.',
                style: AppTextStyles.bodySecondary,
              ),
            ] else if (!hasUnlocked) ...[
              // Masked code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '●●●● ●●●● ●●●●',
                  style: AppTextStyles.title.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      letterSpacing: 6),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.hourglass_empty,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '$daysUntilSeven days until unlocked',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This code is hidden until $name\'s 7th birthday — even parents cannot view it.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ] else ...[
              // Unlocked — reveal on tap
              if (!revealed) ...[
                Text(
                  'Share this code with $name to give them access to their memories. '
                  'Child accounts can view and add photos.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onReveal,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Reveal Code'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    code,
                    style: AppTextStyles.title.copyWith(
                        color: AppColors.success,
                        letterSpacing: 4),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Code copied!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            SharePlus.instance.share(ShareParams(
                          text:
                              'Here\'s your LittleSteps child access code: $code',
                        )),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
