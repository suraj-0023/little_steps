import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '👣',
      title: 'Every Little Step',
      subtitle:
          'Capture your baby\'s most precious moments — photos, milestones, and growth — all in one beautiful place.',
      color: Color(0xFF6C3FC5),
    ),
    _OnboardingPage(
      emoji: '📸',
      title: 'Auto-Tagged Memories',
      subtitle:
          'Our on-device AI reads each photo and adds smart tags instantly — no internet needed.',
      color: Color(0xFF4A90D9),
    ),
    _OnboardingPage(
      emoji: '✨',
      title: 'AI Monthly Stories',
      subtitle:
          'Every month, a heartfelt narrative is woven from your memories — a story you\'ll treasure forever.',
      color: Color(0xFFF5A623),
    ),
    _OnboardingPage(
      emoji: '👨‍👩‍👧',
      title: 'Family Circle',
      subtitle:
          'Invite grandparents, partners, and family to share and contribute to the memory book together.',
      color: Color(0xFF4CAF50),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _PageView(page: _pages[i]),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: _page == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Get started
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_page].color,
                    ),
                    onPressed: () {
                      if (_page < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(
                      _page == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: AppTextStyles.button,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: _finish,
              child: Text('Skip',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.8))),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.color,
            page.color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(page.emoji,
                  style: const TextStyle(fontSize: 80),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Text(
                page.title,
                style: AppTextStyles.display
                    .copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                page.subtitle,
                style: AppTextStyles.body
                    .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
}
