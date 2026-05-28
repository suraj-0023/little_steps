import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' show ImageFilter;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../memory/providers/memory_providers.dart';
import '../../memory/models/memory.dart'; // import Memory model
import '../models/music_track.dart';
import '../providers/music_providers.dart';
import '../repositories/reel_compiler_service.dart';

class ReelScreen extends ConsumerStatefulWidget {
  const ReelScreen({super.key});

  @override
  ConsumerState<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends ConsumerState<ReelScreen> {
  int _step = 0; // 0: Select Photos, 1: Select Music, 2: Configure & Render, 3: Video Preview
  
  // Selections
  final List<Memory> _selectedMemories = [];
  double _slideDuration = 3.0; // Seconds per photo
  
  // Audio Player for previews
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingTrackId;
  
  // Compilation State
  bool _isCompiling = false;
  double _compileProgress = 0.0;
  String _compileStage = '';
  String _compiledVideoPath = '';

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Previews background audio
  Future<void> _toggleAudioPreview(MusicTrack track) async {
    if (_playingTrackId == track.id) {
      await _audioPlayer.pause();
      setState(() => _playingTrackId = null);
    } else {
      await _audioPlayer.stop();
      try {
        await _audioPlayer.play(UrlSource(track.previewUrl));
        setState(() => _playingTrackId = track.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to play audio preview.')),
          );
        }
      }
    }
  }

  // Triggers FFmpeg compilation
  Future<void> _compileReel() async {
    final selectedTrack = ref.read(selectedMusicTrackProvider);
    if (_selectedMemories.isEmpty || selectedTrack == null) return;

    setState(() {
      _isCompiling = true;
      _compileProgress = 0.0;
      _compileStage = 'Initializing engine...';
    });

    final imageUrls = _selectedMemories.map((m) => m.photoUrl).toList();
    final compiler = ref.read(reelCompilerServiceProvider);

    try {
      final videoPath = await compiler.generateReel(
        imageUrls: imageUrls,
        // Always use the permanent download URL, not the streaming previewUrl
        audioUrl: selectedTrack.audioUrl,
        slideDuration: _slideDuration,
        onProgress: (progress, stage) {
          if (mounted) {
            setState(() {
              _compileProgress = progress;
              _compileStage = stage;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isCompiling = false;
          _compiledVideoPath = videoPath;
          _step = 3; // Go to Preview
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompiling = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Compilation Error'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Text(e.toString(), style: const TextStyle(fontSize: 12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }


  void _resetBuilder() {
    _audioPlayer.stop();
    setState(() {
      _step = 0;
      _selectedMemories.clear();
      _compiledVideoPath = '';
      _playingTrackId = null;
    });
    ref.read(selectedMusicTrackProvider.notifier).state = null;
    ref.read(musicQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 3 ? const Color(0xFF121212) : AppColors.surface,
      appBar: AppBar(
        title: Text(
          _step == 3 ? 'Cinema Preview' : 'Photo Reel Builder',
          style: AppTextStyles.title.copyWith(
            color: _step == 3 ? Colors.white : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: _step == 3 ? Colors.black : Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _step == 3 ? Colors.white : AppColors.textPrimary,
        ),
        actions: [
          if (_step > 0 && _step < 3)
            TextButton(
              onPressed: _resetBuilder,
              child: Text(
                'Reset',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_step < 3) _buildStepIndicator(),
              Expanded(
                child: _buildCurrentStepView(),
              ),
            ],
          ),
          if (_isCompiling) _buildCompilingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- Step Indicator Header ---
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          _buildStepDot(0, 'Photos'),
          _buildStepLine(0),
          _buildStepDot(1, 'Soundtrack'),
          _buildStepLine(1),
          _buildStepDot(2, 'Customize'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, String label) {
    final active = _step == stepIndex;
    final completed = _step > stepIndex;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed 
                ? AppColors.success 
                : (active ? AppColors.primary : AppColors.divider),
          ),
          child: Center(
            child: completed 
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: active || completed ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final completed = _step > afterStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: completed ? AppColors.success : AppColors.divider,
      ),
    );
  }

  // --- Wizard Route Manager ---
  Widget _buildCurrentStepView() {
    switch (_step) {
      case 0:
        return _buildPhotoSelectionView();
      case 1:
        return _buildMusicSelectionView();
      case 2:
        return _buildConfigureView();
      case 3:
        return _buildVideoPreviewView();
      default:
        return const SizedBox();
    }
  }

  // --- Step 0: Photo Selector UI ---
  Widget _buildPhotoSelectionView() {
    final memoriesAsync = ref.watch(memoriesProvider);

    return memoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Failed to load photos: $e', style: AppTextStyles.body)),
      data: (memories) {
        final photosOnly = memories.where((m) => m.photoUrl.isNotEmpty).toList();

        if (photosOnly.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No photos available to compile a reel. Please upload memories first!',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select photos in order of playback',
                    style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedMemories.clear();
                            _selectedMemories.addAll(photosOnly);
                          });
                        },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedMemories.clear());
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photosOnly.length,
                itemBuilder: (context, i) {
                  final m = photosOnly[i];
                  final selectedIdx = _selectedMemories.indexOf(m);
                  final isSelected = selectedIdx != -1;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMemories.remove(m);
                        } else {
                          _selectedMemories.add(m);
                        }
                      });
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: AppColors.shimmerBase,
                              child: CachedNetworkImage(
                                imageUrl: m.photoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        // Dim layer if not selected
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected 
                                  ? Colors.black.withValues(alpha: 0.2) 
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                        // Number circle overlay for ordering
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : Colors.black54,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: isSelected 
                                  ? Text(
                                      '${selectedIdx + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    )
                                  : const Icon(Icons.add, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        // Date label at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              DateFormat('MMM d').format(m.takenAt),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Step 1: Music Browser UI ---
  Widget _buildMusicSelectionView() {
    final selectedTrack = ref.watch(selectedMusicTrackProvider);
    final activeApi = ref.watch(musicApiProvider);
    final activeTag = ref.watch(musicTagProvider);
    final tracksAsync = ref.watch(musicTracksProvider);

    return Column(
      children: [
        // Source Selector and Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Column(
            children: [
              // Segmented API selector
              Row(
                children: [
                  Expanded(
                    child: _buildApiTab('ccmixter', 'ccMixter (Open Source)', activeApi),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildApiTab('jamendo', 'Jamendo API (Indie)', activeApi),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search Input
              TextField(
                onChanged: (val) {
                  ref.read(musicQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search songs/instrumentals...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Filter Tag Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Lullaby', 'Calm', 'Playful', 'Happy', 'Acoustic'].map((tag) {
                    final isSelected = activeTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                        ),
                        onSelected: (_) {
                          ref.read(musicTagProvider.notifier).state = tag;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // List of songs
        Expanded(
          child: tracksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('API fetch failed. Try again or change provider.\nDetails: $err', textAlign: TextAlign.center),
              ),
            ),
            data: (tracks) {
              if (tracks.isEmpty) {
                return Center(
                  child: Text('No tracks found.', style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: tracks.length,
                itemBuilder: (context, i) {
                  final t = tracks[i];
                  final isSelected = selectedTrack?.id == t.id;
                  final isPlaying = _playingTrackId == t.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPlaying ? AppColors.primary.withValues(alpha: 0.15) : AppColors.divider.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                        onPressed: () => _toggleAudioPreview(t),
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            t.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.divider.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.licenseName,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${t.durationSeconds}s',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Radio<String?>(
                        value: t.id,
                        groupValue: selectedTrack?.id,
                        activeColor: AppColors.primary,
                        onChanged: (_) {
                          ref.read(selectedMusicTrackProvider.notifier).state = t;
                        },
                      ),
                      onTap: () {
                        ref.read(selectedMusicTrackProvider.notifier).state = t;
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApiTab(String apiCode, String label, String currentApi) {
    final active = currentApi == apiCode;
    return GestureDetector(
      onTap: () {
        ref.read(musicApiProvider.notifier).state = apiCode;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textPrimary,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- Step 2: Configure & Customize ---
  Widget _buildConfigureView() {
    final selectedTrack = ref.watch(selectedMusicTrackProvider);
    final totalDuration = _selectedMemories.length * _slideDuration;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Selected Images Preview Row
              Text('Timeline Preview', style: AppTextStyles.title),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMemories.length,
                  itemBuilder: (context, i) {
                    final m = _selectedMemories[i];
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(m.photoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Selected Music summary card
              if (selectedTrack != null) ...[
                Text('Soundtrack', style: AppTextStyles.title),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selectedTrack.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(selectedTrack.artist, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                        label: Text(
                          selectedTrack.sourceApi.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Customizations
              Text('Reel Settings', style: AppTextStyles.title),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration per photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${_slideDuration.toStringAsFixed(1)}s', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _slideDuration,
                      min: 1.5,
                      max: 6.0,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.divider,
                      onChanged: (val) {
                        setState(() => _slideDuration = val);
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total video length', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('${totalDuration.toStringAsFixed(1)} seconds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 3: Video Preview UI (Cinema Mode) ---
  Widget _buildVideoPreviewView() {
    return Container(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 3),
                    ],
                  ),
                  child: _VideoPreviewWidget(videoPath: _compiledVideoPath),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Export & Share Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          Share.shareXFiles(
                            [XFile(_compiledVideoPath)],
                            text: "Look at this video reel of our baby's memories! ❤️ Compiled with LittleSteps.",
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text('Create New Reel', style: TextStyle(color: Colors.white70)),
                      onPressed: _resetBuilder,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Manager ---
  Widget? _buildBottomNavigationBar() {
    if (_step == 0) {
      return _buildNavigationBottomBar(
        onNext: () => setState(() => _step = 1),
        nextLabel: 'Continue (${_selectedMemories.length} Selected)',
        nextEnabled: _selectedMemories.isNotEmpty,
      );
    } else if (_step == 1) {
      final selectedTrack = ref.watch(selectedMusicTrackProvider);
      return _buildNavigationBottomBar(
        onBack: () {
          _audioPlayer.stop();
          setState(() {
            _playingTrackId = null;
            _step = 0;
          });
        },
        onNext: () {
          _audioPlayer.stop();
          setState(() {
            _playingTrackId = null;
            _step = 2;
          });
        },
        nextLabel: 'Configure',
        nextEnabled: selectedTrack != null,
      );
    } else if (_step == 2) {
      return _buildNavigationBottomBar(
        onBack: () => setState(() => _step = 1),
        onNext: _compileReel,
        nextLabel: 'Compile & Stitch Video',
        nextEnabled: true,
      );
    }
    return null;
  }

  // --- Navigation footer utility ---
  Widget _buildNavigationBottomBar({
    VoidCallback? onBack,
    required VoidCallback onNext,
    required String nextLabel,
    required bool nextEnabled,
  }) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: onBack,
                  child: Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled ? AppColors.primary : AppColors.divider,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: nextEnabled ? onNext : null,
                child: Text(
                  nextLabel,
                  style: TextStyle(
                    color: nextEnabled ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Glassmorphic FFmpeg Rendering Overlay ---
  Widget _buildCompilingOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: AppColors.card.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 4.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating Reel...',
                    style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _compileStage,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _compileProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_compileProgress * 100).toInt()}% Completed',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Keep the app open. This may take up to a minute depending on network speed and selected images count.',
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Inner Class: Video Player Container ---
class _VideoPreviewWidget extends StatefulWidget {
  final String videoPath;
  const _VideoPreviewWidget({required this.videoPath});

  @override
  State<_VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<_VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showPlayOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return GestureDetector(
      onTap: () {
        setState(() => _showPlayOverlay = !_showPlayOverlay);
        if (_showPlayOverlay) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _showPlayOverlay) {
              setState(() => _showPlayOverlay = false);
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white12,
            ),
          ),
          if (_showPlayOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
