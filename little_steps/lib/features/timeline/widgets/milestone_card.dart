import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/milestone.dart';

class MilestoneCard extends StatelessWidget {
  const MilestoneCard({super.key, required this.milestone, this.onDelete});
  final Milestone milestone;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: milestone.type.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: milestone.type.color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: milestone.type.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(milestone.type.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_formatDate(milestone.achievedAt),
                    style: AppTextStyles.caption),
                if (milestone.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(milestone.note!,
                      style: AppTextStyles.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
