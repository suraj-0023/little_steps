import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_providers.dart';
import '../../../core/utils/app_logger.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    var lastDayOfThisMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));
    return lastDayOfThisMonth.day;
  }

  int _firstWeekdayOffset(DateTime date) {
    // Sunday-start offset: Sunday=0, Monday=1, ..., Saturday=6
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vaccination':
        return AppColors.success;
      case 'health':
        return AppColors.error;
      case 'expenditure':
        return AppColors.primary;
      case 'activity':
        return AppColors.secondary;
      case 'target':
        return const Color(0xFF8F7EAB);
      case 'birthday':
        return const Color(0xFFE08B8B);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vaccination':
        return Icons.medical_services_outlined;
      case 'health':
        return Icons.favorite_border;
      case 'expenditure':
        return Icons.shopping_bag_outlined;
      case 'activity':
        return Icons.child_care;
      case 'target':
        return Icons.flag_outlined;
      case 'birthday':
        return Icons.cake_outlined;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];

    final offset = _firstWeekdayOffset(_currentMonth);
    final days = _daysInMonth(_currentMonth);
    final totalCells = offset + days;

    final selectedDayEvents = events.where((e) => _isSameDay(e.date, _selectedDate)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Calendar & Occasions', style: AppTextStyles.title),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Calendar Grid Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider, width: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month/Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.primaryDark),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        '${_months[_currentMonth.month]} ${_currentMonth.year}',
                        style: AppTextStyles.headline.copyWith(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.primaryDark),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Weekdays header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 8),
                  // Grid View of Month Days
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      if (index < offset) {
                        return const SizedBox.shrink();
                      }

                      final day = index - offset + 1;
                      final cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                      final isSelected = _isSameDay(cellDate, _selectedDate);
                      final isToday = _isSameDay(cellDate, DateTime.now());

                      // Find events for this cell
                      final cellEvents = events.where((e) => _isSameDay(e.date, cellDate)).toList();

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = cellDate;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.primary, width: 0.8)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.toString(),
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (cellEvents.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: cellEvents.take(3).map((e) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : _getCategoryColor(e.category),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Selected Date Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Agenda for ${_selectedDate.day} ${_months[_selectedDate.month]} ${_selectedDate.year}',
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          // Events / Agenda List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: selectedDayEvents.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 0.6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 40,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No events or logs today',
                            style: AppTextStyles.title.copyWith(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Log activities, purchases, vaccinations, or birthdays using the + button.',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = selectedDayEvents[index];
                        final catColor = _getCategoryColor(event.category);
                        final catIcon = _getCategoryIcon(event.category);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.divider, width: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Category Icon Indicator
                              Container(
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  catIcon,
                                  color: catColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: AppTextStyles.title.copyWith(fontSize: 14),
                                    ),
                                    if (event.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        event.description,
                                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                                      ),
                                    ],
                                    if (event.category == 'expenditure' && event.amount != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text(
                                          'Cost: \$${event.amount!.toStringAsFixed(2)}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Delete Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                onPressed: () => _confirmDelete(event),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: selectedDayEvents.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Event'.toUpperCase(),
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AddEventSheet(
          selectedDate: _selectedDate,
          onSave: (event) async {
            final user = ref.read(currentUserProvider);
            if (user?.familyId == null) return;
            try {
              await ref.read(calendarRepositoryProvider).saveEvent(user!.familyId!, event);
            } catch (e) {
              AppLogger.e('Failed to save calendar event: $e');
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      if (user?.familyId == null) return;
      try {
        await ref.read(calendarRepositoryProvider).deleteEvent(user!.familyId!, event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
        }
      } catch (e) {
        AppLogger.e('Failed to delete event: $e');
      }
    }
  }
}

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.selectedDate, required this.onSave});

  final DateTime selectedDate;
  final ValueChanged<CalendarEvent> onSave;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _eventDate;
  late String _category;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  static const _categories = [
    {'value': 'activity', 'label': 'Baby Activity'},
    {'value': 'health', 'label': 'Health Record'},
    {'value': 'vaccination', 'label': 'Vaccination Log'},
    {'value': 'expenditure', 'label': 'Expenditure / Purchase'},
    {'value': 'target', 'label': 'Future Target Date'},
    {'value': 'birthday', 'label': 'Parent\'s Birthday'},
    {'value': 'other', 'label': 'Other Occasion'},
  ];

  @override
  void initState() {
    super.initState();
    _eventDate = widget.selectedDate;
    _category = 'activity';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());

    final event = CalendarEvent(
      id: const Uuid().v4(),
      familyId: '', // Filled in repository
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: _eventDate,
      category: _category,
      amount: _category == 'expenditure' ? amount : null,
      createdAt: DateTime.now(),
    );

    widget.onSave(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + bottomPadding,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Log Event / Occasion',
                    style: AppTextStyles.headline.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                  hintText: 'e.g. Vaccinate Polio, Buy diapers, School joining',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Details',
                  labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                  hintText: 'Add additional details or notes',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Event Category',
                  labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat['value'],
                        child: Text(cat['label']!, style: AppTextStyles.body),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Amount Field (for expenditures)
              if (_category == 'expenditure') ...[
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Cost is required';
                    if (double.tryParse(val.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Total Cost (\$)',
                    labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                    hintText: 'e.g. 45.50',
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),
              ],

              // Date Picker Button
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Event Date: ${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Event'.toUpperCase(),
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
