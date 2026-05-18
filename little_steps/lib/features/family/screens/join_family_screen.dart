// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/family_providers.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-character invite code');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await ref.read(familyRepositoryProvider).acceptInvite(
            code: code,
            user: user,
          );
      if (!mounted) return;
      context.go('/home');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Family')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text("Enter invite code", style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              "Ask a family member to share their 6-character invite code.",
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                  letterSpacing: 8, fontSize: 28, color: AppColors.primary),
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                hintStyle: AppTextStyles.title.copyWith(
                    letterSpacing: 8,
                    fontSize: 28,
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
                counterText: '',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _join(),
            ),
            const Spacer(),
            _joining
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _join,
                      child: const Text('Join Family'),
                    ),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
