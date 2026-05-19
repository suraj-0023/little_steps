import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/growth_entry.dart';

class GrowthChart extends StatefulWidget {
  const GrowthChart({super.key, required this.entries});
  final List<GrowthEntry> entries;

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          labelStyle: AppTextStyles.label
              .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'HEIGHT (cm)'), Tab(text: 'WEIGHT (kg)')],
        ),
        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _tab,
            children: [
              _LineChart(
                entries: widget.entries,
                getValue: (e) => e.heightCm,
                color: AppColors.primary,
                unit: 'cm',
              ),
              _LineChart(
                entries: widget.entries,
                getValue: (e) => e.weightKg,
                color: AppColors.secondary,
                unit: 'kg',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.entries,
    required this.getValue,
    required this.color,
    required this.unit,
  });

  final List<GrowthEntry> entries;
  final double? Function(GrowthEntry) getValue;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final points = entries
        .where((e) => getValue(e) != null)
        .toList();

    if (points.isEmpty) {
      return Center(
        child: Text('No data yet — add your first entry below',
            style: AppTextStyles.bodySecondary),
      );
    }

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value)!);
    }).toList();

    final minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final padding = range < 5 ? (5 - range) / 2 + 1 : 2.0;
    final minY = minVal - padding;
    final maxY = maxVal + padding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final dt = points[idx].date;
                  return Text(
                    '${dt.day}/${dt.month}',
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, spot, barData, barIndex) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} $unit',
                  AppTextStyles.caption.copyWith(color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
