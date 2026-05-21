// ignore_for_file: use_build_context_synchronously
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/app_shell.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';
import '../repositories/export_repository.dart';

final _exportRepoProvider =
    Provider<ExportRepository>((_) => ExportRepository());

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen>
    with SingleTickerProviderStateMixin {
  bool _generating = false;
  String? _selectedMonth;
  PdfTemplate _selectedTemplate = PdfTemplate.softPastel;
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
        title: const Text('Export PDF'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
      ),
      body: memoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(AppStrings.genericError, style: AppTextStyles.body)),
        data: (memories) {
          final grouped = _groupByMonth(memories);
          final toExport = _memoriesToExport(memories, grouped);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Step 1: Photo Selection ───────────────────────────
              Text('1. Select photos', style: AppTextStyles.label),
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
                    SizedBox(
                      height: _tabController.index == 0 ? null : 280,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Month picker
                          Padding(
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
                          ),
                          // Custom photo picker
                          _PhotoGrid(
                            memories: memories,
                            selectedIds: _selectedPhotoIds,
                            onToggle: (id) => setState(() {
                              if (_selectedPhotoIds.contains(id)) {
                                _selectedPhotoIds.remove(id);
                              } else {
                                _selectedPhotoIds.add(id);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Step 2: Theme Selection ───────────────────────────
              Text('2. Choose a style', style: AppTextStyles.label),
              const SizedBox(height: 8),
              _ThemeDropdownButton(
                selected: _selectedTemplate,
                onChanged: (t) => setState(() => _selectedTemplate = t),
              ),

              const SizedBox(height: 20),

              // ── Summary + time estimate ───────────────────────────
              if (_canGenerate || toExport.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${toExport.length} photos selected · '
                          'Est. ~${_estimateSeconds(toExport.length)}s to generate. '
                          'You\'ll get a notification when ready.',
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
                    ? () => _exportPdf(
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
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_generating ? 'Generating…' : 'Generate PDF'),
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

  int _estimateSeconds(int photoCount) {
    // ~1.5 seconds per photo for download + processing
    return (photoCount * 1.5 + 3).ceil().clamp(5, 120);
  }

  Future<void> _exportPdf(
      List<Memory> memories, String babyName, String label) async {
    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos selected.')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final repo = ref.read(_exportRepoProvider);
      final file = await repo.buildMemoryPdf(
          memories, babyName, label, _selectedTemplate);

      await NotificationService.showPdfReady(label);

      if (!mounted) return;
      setState(() => _selectedPhotoIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF ready — ${_selectedTemplate.label}'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => SharePlus.instance.share(ShareParams(
              files: [XFile(file.path)],
              subject: 'LittleSteps — $label',
            )),
          ),
        ),
      );
    } catch (e) {
      AppLogger.e('PDF export failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

// ── Theme dropdown button ──────────────────────────────────────────

class _ThemeDropdownButton extends StatelessWidget {
  const _ThemeDropdownButton(
      {required this.selected, required this.onChanged});
  final PdfTemplate selected;
  final ValueChanged<PdfTemplate> onChanged;

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
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
            const Text('Choose a Style',
                style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  ...PdfTemplate.values.map((t) => _ThemePickerTile(
                        template: t,
                        selected: selected == t,
                        onTap: () {
                          onChanged(t);
                          Navigator.of(context).pop();
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE7F6),
                      child: Icon(Icons.auto_awesome,
                          color: Color(0xFF6C3FC5), size: 20),
                    ),
                    title: const Text('AI Layout (Beta)',
                        style: AppTextStyles.body),
                    subtitle: const Text(
                        'Requires Cloud Functions to be deployed',
                        style: AppTextStyles.caption),
                    trailing: const Icon(Icons.lock_outline,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ],
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
      {required this.template, required this.selected, required this.onTap});
  final PdfTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: template.swatchColors
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
      title: Text(template.label, style: AppTextStyles.body),
      subtitle: Text(template.description,
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}

// ── Month tile ────────────────────────────────────────────────────

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

// ── Custom photo grid ─────────────────────────────────────────────

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
