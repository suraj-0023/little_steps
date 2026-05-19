import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/letter_providers.dart';

class LetterDetailScreen extends ConsumerWidget {
  const LetterDetailScreen({super.key, required this.letterId});
  final String letterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider);

    return lettersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load letter')),
      ),
      data: (letters) {
        final letter =
            letters.where((l) => l.id == letterId).firstOrNull;
        if (letter == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Letter not found')),
          );
        }
        if (!letter.isUnlocked) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sealed Letter')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(letter.title, style: AppTextStyles.headline, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'This letter unlocks on\n${DateFormat("d MMMM yyyy").format(letter.unlockAt)}',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        String decryptedBody = '';
        try {
          final user = ref.read(currentUserProvider);
          if (user?.familyId != null) {
            decryptedBody = ref
                .read(letterRepositoryProvider)
                .decryptBody(letter.encryptedBody, user!.familyId!, letter.iv);
          }
        } catch (e) {
          AppLogger.e('Decrypt letter failed', e);
          decryptedBody = '[Could not decrypt letter]';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFDF8F0),
            elevation: 0,
            title: const Text('Letter'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.drafts, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked · ${DateFormat("d MMMM yyyy").format(letter.unlockAt)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(letter.title, style: AppTextStyles.storyTitle),
                const SizedBox(height: 8),
                Text(
                  'Written on ${DateFormat("d MMMM yyyy").format(letter.createdAt)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                Text(decryptedBody, style: AppTextStyles.storyBody),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
