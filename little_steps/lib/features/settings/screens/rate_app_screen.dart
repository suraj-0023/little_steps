// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_providers.dart';

class RateAppScreen extends ConsumerStatefulWidget {
  const RateAppScreen({super.key});

  @override
  ConsumerState<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends ConsumerState<RateAppScreen> {
  int _rating = 0;
  final _feedbackCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'rating': _rating,
        'feedback': _feedbackCtrl.text.trim(),
        'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'email': user?.email,
        'uid': user?.uid,
        'submittedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      AppLogger.e('Feedback submit failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate LittleSteps')),
      body: _submitted ? _SuccessView() : _FormView(
        rating: _rating,
        onRatingChanged: (r) => setState(() => _rating = r),
        feedbackCtrl: _feedbackCtrl,
        nameCtrl: _nameCtrl,
        saving: _saving,
        onSubmit: _submit,
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.rating,
    required this.onRatingChanged,
    required this.feedbackCtrl,
    required this.nameCtrl,
    required this.saving,
    required this.onSubmit,
  });
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController feedbackCtrl;
  final TextEditingController nameCtrl;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.star_rounded,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('How are we doing?', style: AppTextStyles.headline),
                const SizedBox(height: 6),
                Text(
                  'Your feedback helps us make LittleSteps better for every family.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Star rating
          Text('Your rating', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRatingChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 42,
                    color: i < rating
                        ? const Color(0xFFFFC107)
                        : AppColors.divider,
                  ),
                ),
              ),
            ),
          ),
          if (rating > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][rating],
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Feedback text
          Text('Tell us more (optional)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: feedbackCtrl,
            maxLines: 5,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText:
                  'What do you love? What could be better?',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text('Your name (optional)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'First name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : onSubmit,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You can submit feedback multiple times.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded,
                size: 72, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('Thank you!', style: AppTextStyles.headline),
            const SizedBox(height: 12),
            Text(
              'Your feedback means a lot. We\'ll keep making LittleSteps better for your family.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
