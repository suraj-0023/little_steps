import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/baby.dart';

class BabyAvatar extends StatelessWidget {
  const BabyAvatar({
    super.key,
    required this.baby,
    this.radius = 20,
  });

  final Baby baby;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = baby.coverPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        baby.firstName[0].toUpperCase(),
        style: AppTextStyles.title.copyWith(
          color: AppColors.primary,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
