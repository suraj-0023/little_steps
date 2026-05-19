import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/app_shell.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/family_providers.dart';
import '../widgets/member_tile.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    // Ensure admin member doc exists (idempotent)
    ref.listen(currentUserProvider, (_, u) {
      if (u?.familyId != null) {
        ref.read(familyRepositoryProvider).ensureAdminMemberDoc(
              u!.familyId!,
              u,
            );
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
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite',
            onPressed: () => context.push('/family/invite'),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyFamily(
              onInvite: () => context.push('/family/invite'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: 72, height: 1),
            itemBuilder: (context, i) {
              final member = members[i];
              return MemberTile(
                member: member,
                isCurrentUser: member.uid == user?.uid,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/family/invite'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Invite'),
      ),
    );
  }
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 72,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text('Your family circle', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Invite your partner, grandparents, or anyone special to share memories together.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite family member'),
            ),
          ],
        ),
      ),
    );
  }
}
