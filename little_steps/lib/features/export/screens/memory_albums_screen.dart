// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';
import '../repositories/export_repository.dart';

final _exportRepoProvider =
    Provider<ExportRepository>((_) => ExportRepository());

enum ScrapbookTheme {
  vintageScrapbook,
  dreamyPastel,
  modernMinimalist,
  earthyForest,
}

extension ScrapbookThemeExtension on ScrapbookTheme {
  String get label {
    switch (this) {
      case ScrapbookTheme.vintageScrapbook: return 'Vintage Scrapbook';
      case ScrapbookTheme.dreamyPastel: return 'Dreamy Pastel';
      case ScrapbookTheme.modernMinimalist: return 'Modern Minimalist';
      case ScrapbookTheme.earthyForest: return 'Earthy Forest';
    }
  }

  String get description {
    switch (this) {
      case ScrapbookTheme.vintageScrapbook: return 'Warm cream tones, polaroid frames & cursive text';
      case ScrapbookTheme.dreamyPastel: return 'Soft pink/lavender gradients & rounded frames';
      case ScrapbookTheme.modernMinimalist: return 'Crisp white, tracked uppercase titles & clean grid';
      case ScrapbookTheme.earthyForest: return 'Sage green & taupe tones, thin leaf borders';
    }
  }

  List<int> get swatchColors {
    switch (this) {
      case ScrapbookTheme.vintageScrapbook: return [0xFFFAF0DC, 0xFFB5924C, 0xFF5C3D1E];
      case ScrapbookTheme.dreamyPastel: return [0xFFFFF0F5, 0xFFE6E6FA, 0xFFC9A7D0];
      case ScrapbookTheme.modernMinimalist: return [0xFFFFFFFF, 0xFF1A1A2E, 0xFF757069];
      case ScrapbookTheme.earthyForest: return [0xFFF2F4F2, 0xFF16A34A, 0xFF8C7A6B];
    }
  }
}

class MemoryAlbumsScreen extends ConsumerStatefulWidget {
  const MemoryAlbumsScreen({super.key});

  @override
  ConsumerState<MemoryAlbumsScreen> createState() => _MemoryAlbumsScreenState();
}

class _MemoryAlbumsScreenState extends ConsumerState<MemoryAlbumsScreen>
    with SingleTickerProviderStateMixin {
  bool _generating = false;
  String _generatingStatus = '';
  String? _selectedMonth;
  ScrapbookTheme _selectedTheme = ScrapbookTheme.vintageScrapbook;
  final Set<String> _selectedPhotoIds = {};
  late final TabController _tabController;
  List<File> _savedPdfs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadSavedPdfs();
  }

  Future<void> _loadSavedPdfs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (await exportDir.exists()) {
        final files = exportDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.pdf'))
            .toList();
        
        // Sort by last modified descending
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        if (mounted) {
          setState(() {
            _savedPdfs = files;
          });
        }
      }
    } catch (e) {
      AppLogger.e('Error loading saved PDFs', e);
    }
  }

  Future<void> _deletePdf(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _loadSavedPdfs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Album deleted.')),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error deleting PDF', e);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    if (_generating) return false;
    if (_tabController.index == 0) return _selectedMonth != null;
    return _selectedPhotoIds.isNotEmpty;
  }

  List<Memory> _memoriesToExport(List<Memory> all,
      Map<String, List<Memory>> grouped) {
    if (_tabController.index == 0 && _selectedMonth != null) {
      return grouped[_selectedMonth!] ?? [];
    }
    return all.where((m) => _selectedPhotoIds.contains(m.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final baby = ref.watch(currentBabyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Albums'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: memoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(AppStrings.genericError, style: AppTextStyles.body)),
        data: (memories) {
          final grouped = _groupByMonth(memories);
          final toExport = _memoriesToExport(memories, grouped);
          
          // Warn if more than 10 photos are selected
          final hasOverlimit = toExport.length > 10;
          final finalCount = hasOverlimit ? 10 : toExport.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Step 1: Photo Selection ───────────────────────────
              Text('1. Select photos (Max 10)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelStyle: AppTextStyles.body,
                      unselectedLabelStyle: AppTextStyles.bodySecondary,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: 'By Month'),
                        Tab(text: 'Custom'),
                      ],
                    ),
                    const Divider(height: 1),
                    _tabController.index == 0
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: grouped.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No memories yet.'),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: grouped.entries
                                        .map((e) => _MonthTile(
                                              monthLabel: e.key,
                                              count: e.value.length,
                                              selected: _selectedMonth == e.key,
                                              onTap: () => setState(
                                                  () => _selectedMonth = e.key),
                                            ))
                                        .toList(),
                                  ),
                          )
                        : _PhotoGrid(
                            memories: memories,
                            selectedIds: _selectedPhotoIds,
                            onToggle: (id) => setState(() {
                              if (_selectedPhotoIds.contains(id)) {
                                _selectedPhotoIds.remove(id);
                              } else {
                                if (_selectedPhotoIds.length >= 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maximum of 10 photos allowed per album page.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                _selectedPhotoIds.add(id);
                              }
                            }),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Step 2: Theme Selection ───────────────────────────
              Text('2. Choose a style theme', style: AppTextStyles.label),
              const SizedBox(height: 8),
              _ThemeDropdownButton(
                selected: _selectedTheme,
                onChanged: (t) => setState(() => _selectedTheme = t),
              ),

              const SizedBox(height: 20),

              // ── Warnings and Summaries ────────────────────────────
              if (hasOverlimit) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You selected ${toExport.length} photos. Only the first 10 will be included to keep the scrapbook page gorgeous.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_canGenerate || toExport.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$finalCount photo(s) selected · '
                          'AI is designing style: ${_selectedTheme.label}. '
                          'Est. ~${_estimateSeconds(finalCount)}s to download, compress, & layout.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Generate button ───────────────────────────────────
              FilledButton.icon(
                onPressed: _canGenerate
                    ? () => _exportScrapbook(
                          toExport,
                          baby?.displayName ?? 'Baby',
                          _tabController.index == 0
                              ? (_selectedMonth ?? '')
                              : 'Custom Selection',
                        )
                    : null,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_generating ? _generatingStatus : 'Generate AI Scrapbook'),
              ),
              if (_savedPdfs.isNotEmpty) ...[
                const Divider(height: 32),
                Text('My Scrapbook Albums', style: AppTextStyles.label),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedPdfs.length,
                  itemBuilder: (context, index) {
                    final file = _savedPdfs[index];
                    final fileName = file.path.split('/').last;
                    final cleanName = fileName
                        .replaceAll('littlesteps_', '')
                        .replaceAll('.pdf', '')
                        .replaceAll('_', ' ');

                    String sizeString = '';
                    try {
                      final bytes = file.lengthSync();
                      final kb = bytes / 1024;
                      if (kb > 1024) {
                        sizeString = '${(kb / 1024).toStringAsFixed(1)} MB';
                      } else {
                        sizeString = '${kb.toStringAsFixed(0)} KB';
                      }
                    } catch (_) {}

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFBF9F6),
                          child: Icon(Icons.picture_as_pdf, color: AppColors.primary),
                        ),
                        title: Text(cleanName, style: AppTextStyles.body),
                        subtitle: Text(
                          sizeString.isNotEmpty ? sizeString : 'PDF Scrapbook',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
                              onPressed: () => context.push('/export/preview', extra: {
                                'pdfFile': file,
                                'albumName': cleanName,
                              }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                              onPressed: () => SharePlus.instance.share(ShareParams(
                                files: [XFile(file.path)],
                                subject: cleanName,
                              )),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _showDeleteConfirm(file, cleanName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<Memory>> _groupByMonth(List<Memory> memories) {
    final grouped = <String, List<Memory>>{};
    for (final m in memories) {
      final key = DateFormat('MMMM yyyy').format(m.takenAt);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    return grouped;
  }

  int _estimateSeconds(int photoCount) {
    return (photoCount * 2.5 + 5).ceil().clamp(5, 120);
  }

  Future<void> _exportScrapbook(
      List<Memory> memories, String babyName, String label) async {
    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos selected.')),
      );
      return;
    }

    final selectedMemories = memories.take(10).toList();

    setState(() {
      _generating = true;
      _generatingStatus = 'Downloading photos…';
    });
    try {
      // 1. Download all images in parallel (major speedup over sequential)
      final downloadFutures = selectedMemories.map((memory) async {
        final url = memory.thumbnailUrl.isNotEmpty
            ? memory.thumbnailUrl
            : memory.photoUrl;
        AppLogger.i('Downloading image for scrapbook: ${memory.id}');
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${memory.id}');
        }
        return response.bodyBytes;
      }).toList();

      final rawBytesList = await Future.wait(downloadFutures);

      // 2. Compress all images in parallel
      if (mounted) {
        setState(() => _generatingStatus = 'Compressing images…');
      }
      final compressFutures = rawBytesList.map((rawBytes) {
        return FlutterImageCompress.compressWithList(
          rawBytes,
          minWidth: 600,
          minHeight: 600,
          quality: 60,
        );
      }).toList();

      final compressedBytesList = await Future.wait(compressFutures);

      // 3. Call Gemini to design the HTML scrapbook layout
      if (mounted) {
        setState(
            () => _generatingStatus = 'AI designing layout…');
      }
      final geminiService = ref.read(geminiVisionServiceProvider);
      final htmlContent = await geminiService.generateScrapbookHtml(
        memories: selectedMemories,
        babyName: babyName,
        themeName: _selectedTheme.label,
        compressedImageBytes: compressedBytesList,
      );

      // 4. Compile HTML to PDF on-device
      if (mounted) {
        setState(() => _generatingStatus = 'Building PDF…');
      }
      final repo = ref.read(_exportRepoProvider);
      final pdfFile = await repo.compileHtmlToPdf(
        htmlContent: htmlContent,
        compressedImageBytes: compressedBytesList,
        babyName: babyName,
        monthLabel: label,
      );

      // 5. Send success notification
      await NotificationService.showPdfReady(label);

      if (!mounted) return;
      setState(() {
        _selectedPhotoIds.clear();
        _selectedMonth = null;
      });
      await _loadSavedPdfs();

      // 6. Navigate to preview screen
      context.push('/export/preview', extra: {
        'pdfFile': pdfFile,
        'albumName': label,
      });
    } catch (e) {
      AppLogger.e('Scrapbook generation failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate scrapbook: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _generatingStatus = '';
        });
      }
    }
  }

  void _showDeleteConfirm(File file, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scrapbook?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _deletePdf(file);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ThemeDropdownButton extends StatelessWidget {
  const _ThemeDropdownButton(
      {required this.selected, required this.onChanged});
  final ScrapbookTheme selected;
  final ValueChanged<ScrapbookTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Row(
              children: selected.swatchColors
                  .map((c) => Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.label, style: AppTextStyles.body),
                  Text(selected.description,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Choose an AI Album Style',
                style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: ScrapbookTheme.values.map((t) => _ThemePickerTile(
                      theme: t,
                      selected: selected == t,
                      onTap: () {
                        onChanged(t);
                        Navigator.of(context).pop();
                      },
                    )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePickerTile extends StatelessWidget {
  const _ThemePickerTile(
      {required this.theme, required this.selected, required this.onTap});
  final ScrapbookTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: theme.swatchColors
            .map((c) => Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ))
            .toList(),
      ),
      title: Text(theme.label, style: AppTextStyles.body),
      subtitle: Text(theme.description,
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.monthLabel,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String monthLabel;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.photo_library_outlined,
          color: selected ? AppColors.primary : AppColors.textSecondary,
          size: 20),
      title: Text(monthLabel, style: AppTextStyles.body),
      subtitle: Text('$count photos', style: AppTextStyles.caption),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor:
          selected ? AppColors.primary.withValues(alpha: 0.06) : null,
      onTap: onTap,
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.memories,
    required this.selectedIds,
    required this.onToggle,
  });
  final List<Memory> memories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No photos yet.'),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: memories.length,
      itemBuilder: (_, i) {
        final m = memories[i];
        final sel = selectedIds.contains(m.id);
        return GestureDetector(
          onTap: () => onToggle(m.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: m.thumbnailUrl,
                fit: BoxFit.cover,
              ),
              if (sel)
                Container(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white, size: 22),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
