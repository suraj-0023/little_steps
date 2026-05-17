import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get monthYear => DateFormat('MMMM yyyy').format(this);
  String get dayMonthYear => DateFormat('d MMMM yyyy').format(this);
  String get shortDate => DateFormat('d MMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String get ageFromNow {
    final now = DateTime.now();
    final months = (now.year - year) * 12 + (now.month - month);
    if (months < 1) return 'Newborn';
    if (months < 12) return '$months month${months == 1 ? '' : 's'} old';
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (remMonths == 0) return '$years year${years == 1 ? '' : 's'} old';
    return '$years year${years == 1 ? '' : 's'} $remMonths month${remMonths == 1 ? '' : 's'} old';
  }
}
