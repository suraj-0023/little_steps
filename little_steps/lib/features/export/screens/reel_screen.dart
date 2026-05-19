import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/providers/memory_providers.dart';

class ReelScreen extends ConsumerStatefulWidget {
  const ReelScreen({super.key});

  @override
  ConsumerState<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends ConsumerState<ReelScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentIndex = 0;
  bool _playing = true;
  Timer? _autoPlayTimer;

  late final AnimationController _textAnim;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  static const _slideDuration = Duration(milliseconds: 600);
  static const _holdDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _textAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = CurvedAnimation(parent: _textAnim, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textAnim, curve: Curves.easeOut));

    _textAnim.forward();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _textAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(_holdDuration, () {
      if (!mounted || !_playing) return;
      final memories = ref.read(memoriesProvider).valueOrNull ?? [];
      if (memories.isEmpty) return;
      final next = (_currentIndex + 1) % memories.length;
      _controller.animateToPage(next,
          duration: _slideDuration, curve: Curves.easeInOut);
      _startAutoPlay();
    });
  }

  void _onPageChanged(int i) {
    setState(() => _currentIndex = i);
    _textAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final baby = ref.watch(currentBabyProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            onPressed: () {
              setState(() => _playing = !_playing);
              if (_playing) _startAutoPlay();
            },
          ),
        ],
      ),
      body: memoriesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => const Center(
            child: Text('Failed to load photos',
                style: TextStyle(color: Colors.white))),
        data: (memories) {
          if (memories.isEmpty) {
            return const Center(
              child: Text('No photos yet',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          return Stack(
            children: [
              // Photos
              PageView.builder(
                controller: _controller,
                itemCount: memories.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) {
                  final m = memories[i];
                  return AnimatedOpacity(
                    opacity: _currentIndex == i ? 1.0 : 0.6,
                    duration: _slideDuration,
                    child: CachedNetworkImage(
                      imageUrl: m.photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 48),
                    ),
                  );
                },
              ),

              // Gradient overlay — bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Top gradient — for baby name / date area
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 130,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Baby name — top center (animated)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Center(
                    child: Text(
                      baby?.displayName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom overlays — caption, date, tags, progress
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Caption / note
                      if (memories[_currentIndex].caption?.isNotEmpty ==
                          true)
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: Text(
                              memories[_currentIndex].caption!,
                              style: AppTextStyles.body
                                  .copyWith(color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Date
                      FadeTransition(
                        opacity: _textFade,
                        child: Text(
                          DateFormat('d MMMM yyyy')
                              .format(memories[_currentIndex].takenAt),
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                      ),
                      // Tags
                      if (memories[_currentIndex].tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _textFade,
                          child: Wrap(
                            spacing: 6,
                            children: memories[_currentIndex]
                                .tags
                                .take(3)
                                .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.white30,
                                            width: 0.5),
                                      ),
                                      child: Text(
                                        tag,
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                color: Colors.white,
                                                fontSize: 10),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Progress bar
                      _ProgressBar(
                        total: memories.length,
                        current: _currentIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.total, required this.current});
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total > 30 ? 30 : total, (i) {
        final active = i == current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: active ? 3 : 2,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
