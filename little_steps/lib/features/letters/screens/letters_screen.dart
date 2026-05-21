import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/app_shell.dart';
import '../models/letter.dart';
import '../providers/letter_providers.dart';

class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters to the Future'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(AppStrings.genericError, style: AppTextStyles.body)),
        data: (letters) => letters.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: letters.length + 1, // +1 for the info card at top
                itemBuilder: (_, i) {
                  if (i == 0) return const _InfoCard();
                  return _LetterCard(letter: letters[i - 1]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/letters/write'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Write a Letter'),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────

class _InfoCard extends StatefulWidget {
  const _InfoCard();

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.primary.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'About Letters to the Future',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              _Faq(
                icon: Icons.lock_clock,
                question: 'Can the letter be opened before the date?',
                answer:
                    'No. The letter is completely inaccessible until the unlock date you choose. Even family admins cannot bypass the date lock.',
              ),
              _Faq(
                icon: Icons.edit_off_outlined,
                question: 'Can I edit the letter after sending?',
                answer:
                    'No. Once a letter is sent, it is encrypted and sealed — it cannot be edited or deleted. Write it like you mean it.',
              ),
              _Faq(
                icon: Icons.people_outline,
                question: 'Who can read the letter when it unlocks?',
                answer:
                    'If you mark the letter as "private", only you can read it. If you mark it "public", all family members (including the child when they join the family) can read it after the unlock date.',
              ),
              _Faq(
                icon: Icons.child_care_outlined,
                question: 'How will the child open their letters?',
                answer:
                    'When the child is old enough, a parent invites them to the family circle using the invite code. They sign in with their own Google account and can read any public unlocked letters addressed to them.',
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({
    required this.icon,
    required this.question,
    required this.answer,
  });
  final IconData icon;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(answer, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline,
                    size: 72,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                Text('Letters to the Future',
                    style: AppTextStyles.headline),
                const SizedBox(height: 12),
                Text(
                  'Write a heartfelt letter to your baby — to be opened on their birthday, graduation, or any special day.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () =>
                      GoRouter.of(context).push('/letters/write'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Write your first letter'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Letter card ───────────────────────────────────────────────────

class _LetterCard extends ConsumerWidget {
  const _LetterCard({required this.letter});
  final Letter letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final unlocked = now.isAfter(letter.unlockAt);
    final daysLeft = letter.unlockAt.difference(now).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unlocked
            ? () => context.push('/letters/${letter.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.drafts : Icons.lock_outline,
                  color: unlocked ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(letter.title,
                              style: AppTextStyles.title),
                        ),
                        // Public / private badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: letter.isPublic
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            letter.isPublic ? 'Public' : 'Private',
                            style: AppTextStyles.caption.copyWith(
                              color: letter.isPublic
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? 'Unlocked · ${DateFormat('d MMM yyyy').format(letter.unlockAt)}'
                          : daysLeft > 0
                              ? 'Opens in $daysLeft day${daysLeft != 1 ? "s" : ""}'
                              : 'Opens today!',
                      style: AppTextStyles.caption.copyWith(
                        color: unlocked
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Written ${DateFormat('d MMM yyyy').format(letter.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (unlocked)
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
