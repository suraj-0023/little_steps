import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';

class MemoryAlbumsScreen extends ConsumerStatefulWidget {
  const MemoryAlbumsScreen({super.key});

  @override
  ConsumerState<MemoryAlbumsScreen> createState() => _MemoryAlbumsScreenState();
}

class _MemoryAlbumsScreenState extends ConsumerState<MemoryAlbumsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedMonth;
  final Set<String> _selectedPhotoIds = {};
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Books'),
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
          
          final hasOverlimit = toExport.length > 50;
          final finalCount = hasOverlimit ? 50 : toExport.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Step 1: Photo Selection ───────────────────────────
              Text('Select photos for your Memory Book', style: AppTextStyles.label),
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
                                if (_selectedPhotoIds.length >= 50) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maximum of 50 photos allowed per album.'),
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
                          'You selected ${toExport.length} photos. Only the first 50 will be included to keep the scrapbook page gorgeous.',
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
                          '$finalCount photo(s) selected for your bespoke memory book.',
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
                    ? () {
                        final albumName = _tabController.index == 0
                            ? (_selectedMonth ?? '')
                            : 'Custom Selection';
                        context.push('/export/keepsake', extra: {
                          'memories': toExport.take(50).toList(),
                          'albumName': albumName,
                        });
                      }
                    : null,
                icon: const Icon(Icons.photo_album),
                label: const Text('View Memory Book'),
              ),
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
