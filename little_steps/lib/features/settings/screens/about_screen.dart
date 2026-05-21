import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    _Feature(
      icon: Icons.photo_library_outlined,
      title: 'Memory Book',
      description:
          'Capture every moment in a beautiful masonry collage. Upload photos from your gallery or take them directly in the app.',
    ),
    _Feature(
      icon: Icons.timeline_outlined,
      title: 'Timeline',
      description:
          'See your baby\'s journey laid out chronologically. Add custom milestones like first steps, first words, and more.',
    ),
    _Feature(
      icon: Icons.auto_stories_outlined,
      title: 'AI Monthly Stories',
      description:
          'Every month, AI writes a personalised narrative story from your photos and notes — a keepsake to treasure forever.',
    ),
    _Feature(
      icon: Icons.show_chart_outlined,
      title: 'Growth Journal',
      description:
          'Track height and weight over time with beautiful growth curves. See how far your little one has come.',
    ),
    _Feature(
      icon: Icons.mail_outlined,
      title: 'Letters to the Future',
      description:
          'Write encrypted letters to your child, sealed with a date lock. Share them when they\'re ready — on a birthday, graduation, or any milestone.',
    ),
    _Feature(
      icon: Icons.people_outline,
      title: 'Family Circle',
      description:
          'Invite partners, grandparents, and loved ones. Everyone shares the same memory book in real time.',
    ),
    _Feature(
      icon: Icons.picture_as_pdf_outlined,
      title: 'PDF Export',
      description:
          'Export your memories as a beautiful photo album PDF in 9 hand-crafted styles — from soft pastels to bold modern layouts.',
    ),
    _Feature(
      icon: Icons.slideshow_outlined,
      title: 'Photo Reel',
      description:
          'Watch your memories come alive as an animated slideshow with captions, dates, and smooth transitions.',
    ),
    _Feature(
      icon: Icons.child_care_outlined,
      title: 'Child Access',
      description:
          'When your child turns 7, unlock their personal access code so they can view and add to their own memory book.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About LittleSteps')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FeatureTile(feature: _features[i]),
                childCount: _features.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.child_care,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'LittleSteps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A beautiful memory book for the most important journey of your life.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon,
              color: AppColors.primary, size: 22),
        ),
        title:
            Text(feature.title, style: AppTextStyles.body),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(feature.description,
              style: AppTextStyles.bodySecondary),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature(
      {required this.icon,
      required this.title,
      required this.description});
  final IconData icon;
  final String title;
  final String description;
}
