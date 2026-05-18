import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/models/app_user.dart';
import '../models/family_member.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.member, this.isCurrentUser = false});

  final FamilyMember member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundImage: member.hasPhoto
            ? CachedNetworkImageProvider(member.photoUrl)
            : null,
        child: !member.hasPhoto
            ? Text(member.initials, style: AppTextStyles.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600))
            : null,
      ),
      title: Text(
        isCurrentUser ? '${member.displayName} (you)' : member.displayName,
        style: AppTextStyles.body,
      ),
      subtitle: Text(member.joinedAt.toString().substring(0, 10),
          style: AppTextStyles.caption),
      trailing: _RoleChip(role: member.role),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.admin => ('Admin', AppColors.primary),
      UserRole.editor => ('Editor', Colors.green.shade600),
      UserRole.contributor => ('Contributor', Colors.orange.shade600),
      UserRole.viewer => ('Viewer', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w600)),
    );
  }
}
