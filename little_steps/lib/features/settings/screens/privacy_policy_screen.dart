import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PolicyHeader(
          title: 'Privacy Policy',
          subtitle: 'Last updated: May 2026',
        ),
        SizedBox(height: 24),
        _Section(
          title: '1. Information We Collect',
          body:
              'LittleSteps collects information you provide when creating a family, '
              'including your Google account display name and email address. We also '
              'store photos, voice notes, captions, milestone data, and letters you '
              'upload or create within the app. All data is stored securely in Google '
              'Firebase, a cloud platform governed by Google\'s Privacy Policy.',
        ),
        _Section(
          title: '2. How We Use Your Information',
          body:
              'Your information is used solely to provide LittleSteps features: '
              'displaying memories, generating AI monthly stories, sharing within your '
              'family circle, and sending push notifications. We do not sell, rent, or '
              'share your personal information with third parties for marketing purposes.',
        ),
        _Section(
          title: '3. Data Sharing',
          body:
              'Photos, memories, and letters are shared only within your defined family '
              'circle — meaning users you have explicitly invited. Public letters become '
              'visible to all family members after their unlock date. Private letters are '
              'visible only to the author. We do not share your content with anyone '
              'outside your family circle.',
        ),
        _Section(
          title: '4. AI Features',
          body:
              'Monthly story generation uses your photos\' captions and voice note '
              'transcriptions as context. This data is sent to Google Vertex AI (Gemini) '
              'to generate narrative text. We do not use your personal data to train '
              'AI models. Stories are stored securely in your family\'s Firestore database.',
        ),
        _Section(
          title: '5. Children\'s Privacy',
          body:
              'LittleSteps is designed for parents and family members documenting a '
              'child\'s growth. Children under 13 should not create accounts directly. '
              'The Child Access Code feature, available when a child reaches 7 years old, '
              'is shared by a parent and allows read and upload access only — not '
              'administrative access.',
        ),
        _Section(
          title: '6. Data Security',
          body:
              'All data is protected by Firebase Security Rules which ensure only '
              'authenticated family members can access your content. Photos are stored '
              'in Firebase Storage with access controls. Letters are client-side '
              'encrypted before storage. We use Firebase App Check to verify that only '
              'the genuine LittleSteps app can access our backend.',
        ),
        _Section(
          title: '7. Data Retention & Deletion',
          body:
              'Your data is retained for as long as your account is active. To delete '
              'your account and all associated data, contact us at support@littlesteps.app. '
              'Individual photos and memories can be deleted from within the app by '
              'editors and admins.',
        ),
        _Section(
          title: '8. Contact Us',
          body:
              'If you have questions about this Privacy Policy or how we handle your '
              'data, please contact us at support@littlesteps.app.',
        ),
      ],
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(body, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}
