// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _generating = false;
  String? _selectedMonth;
  PdfTemplate _selectedTemplate = PdfTemplate.softPastel;

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final baby = ref.watch(currentBabyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Share'),
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
          final months = _groupByMonth(memories);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── PDF Collage ──────────────────────────────────────
              _SectionHeader(title: 'PDF Collage', icon: Icons.picture_as_pdf),
              const SizedBox(height: 12),

              // Month picker
              Text('1. Choose a month', style: AppTextStyles.label),
              const SizedBox(height: 8),
              ...months.entries.map((e) => _MonthTile(
                    monthLabel: e.key,
                    count: e.value.length,
                    selected: _selectedMonth == e.key,
                    onTap: () => setState(() => _selectedMonth = e.key),
                  )),
              const SizedBox(height: 20),

              // Template picker
              Text('2. Choose a style', style: AppTextStyles.label),
              const SizedBox(height: 8),
              ...PdfTemplate.values.map((t) => _TemplateTile(
                    template: t,
                    selected: _selectedTemplate == t,
                    onTap: () => setState(() => _selectedTemplate = t),
                  )),
              const SizedBox(height: 24),

              // Export button
              FilledButton.icon(
                onPressed: _selectedMonth == null || _generating
                    ? null
                    : () => _exportPdf(
                          months[_selectedMonth!]!,
                          baby?.displayName ?? 'Baby',
                        ),
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: Text(_generating ? 'Generating…' : 'Export PDF'),
              ),
              const SizedBox(height: 32),

              // ── Photo Reel ───────────────────────────────────────
              _SectionHeader(title: 'Photo Reel', icon: Icons.play_circle_outline),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.slideshow, color: AppColors.primary),
                  title: const Text('Play slideshow'),
                  subtitle: Text('${memories.length} photos',
                      style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reel'),
                ),
              ),
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

  Future<void> _exportPdf(List<Memory> memories, String babyName) async {
    setState(() => _generating = true);
    try {
      final repo = ref.read(_exportRepoProvider);
      final file = await repo.buildMemoryPdf(
          memories, babyName, _selectedMonth!, _selectedTemplate);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('PDF Ready'),
          content: Text(
              'Your ${_selectedMonth!} ${_selectedTemplate.label} album is ready.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.layoutPdf(
                    onLayout: (_) async => file.readAsBytesSync());
              },
              child: const Text('Print / Preview'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    subject: 'LittleSteps — ${_selectedMonth!}',
                  ),
                );
              },
              child: const Text('Share'),
            ),
          ],
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

// ── Widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.title),
      ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.photo_library_outlined,
            color: selected ? AppColors.primary : AppColors.textSecondary),
        title: Text(monthLabel, style: AppTextStyles.body),
        subtitle: Text('$count photos', style: AppTextStyles.caption),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });
  final PdfTemplate template;
  final bool selected;
  final VoidCallback onTap;

  static const _swatches = {
    PdfTemplate.softPastel: [Color(0xFFFDF6F0), Color(0xFFC9A7D0), Color(0xFF6B4C72)],
    PdfTemplate.boldModern: [Color(0xFF1A1A2E), Color(0xFFE94560), Color(0xFF16213E)],
    PdfTemplate.classicScrapbook: [Color(0xFFFAF0DC), Color(0xFFB5924C), Color(0xFF5C3D1E)],
    PdfTemplate.minimalClean: [Color(0xFFFFFFFF), Color(0xFF4A90D9), Color(0xFFE8F0FA)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _swatches[template]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color swatches preview
              Row(
                children: colors
                    .map((c) => Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black12, width: 0.5),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.label, style: AppTextStyles.body),
                    Text(template.description,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
