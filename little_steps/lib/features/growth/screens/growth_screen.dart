import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/app_shell.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../models/growth_entry.dart';
import '../providers/growth_providers.dart';
import '../widgets/growth_chart.dart';

class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(growthEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.growth),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add entry',
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppStrings.genericError, style: AppTextStyles.body)),
        data: (entries) => _GrowthBody(entries: entries),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEntrySheet(ref: ref),
    );
  }
}

class _GrowthBody extends StatelessWidget {
  const _GrowthBody({required this.entries});
  final List<GrowthEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No growth data yet', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text('Tap + to log height and weight', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GrowthChart(entries: entries),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('All Entries', style: AppTextStyles.title),
        ),
        ...entries.reversed.map((e) => _EntryTile(entry: e)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});
  final GrowthEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.child_care, color: AppColors.primary),
      ),
      title: Text(DateFormat('d MMM yyyy').format(entry.date), style: AppTextStyles.body),
      subtitle: Text([
        if (entry.heightCm != null) '${entry.heightCm!.toStringAsFixed(1)} cm',
        if (entry.weightKg != null) '${entry.weightKg!.toStringAsFixed(2)} kg',
        if (entry.note != null) entry.note!,
      ].join(' · '), style: AppTextStyles.bodySecondary),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
        onPressed: () async {
          if (user?.familyId == null) return;
          try {
            await ref
                .read(growthRepositoryProvider)
                .deleteEntry(user!.familyId!, entry.id);
          } catch (e) {
            AppLogger.e('Delete growth entry failed', e);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.genericError)),
              );
            }
          }
        },
      ),
    );
  }
}

class _AddEntrySheet extends ConsumerStatefulWidget {
  const _AddEntrySheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    final height = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    if (height == null && weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least height or weight')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = GrowthEntry(
        id: const Uuid().v4(),
        familyId: user!.familyId!,
        babyId: baby.id,
        date: _selectedDate,
        createdAt: DateTime.now(),
        heightCm: height,
        weightKg: weight,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      await ref
          .read(growthRepositoryProvider)
          .addEntry(user.familyId!, entry);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      AppLogger.e('Add growth entry failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Growth', style: AppTextStyles.headline),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(DateFormat('d MMM yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
