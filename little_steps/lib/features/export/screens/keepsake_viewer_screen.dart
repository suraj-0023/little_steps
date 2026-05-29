import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../baby/providers/baby_providers.dart';
import '../../memory/models/memory.dart';

class KeepsakeViewerScreen extends ConsumerWidget {
  final List<Memory> memories;
  final String albumName;

  const KeepsakeViewerScreen({
    super.key,
    required this.memories,
    required this.albumName,
  });

  // Premium Color Palette - Nordic Sky & Oatmeal
  static const Color surface = Color(0xFFFAF9F6); // Warm Premium Cream
  static const Color primaryAccent = Color(0xFFD4AF37); // Warm ochre
  static const Color primaryDark = Color(0xFF2C3E50); // Deep charcoal
  static const Color secondaryTone = Color(0xFFE5CEB8); // Soft Warm Peach-Beige
  static const Color textPrimary = Color(0xFF2E2D2B); // Soft Charcoal-Brown
  static const Color textSecondary = Color(0xFF8C8A84); // Warm Grey-Bronze
  static const Color dividerColor = Color(0xFFEFECE6); // Soft Warm Ivory-Grey

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    final babyName = baby?.displayName ?? 'Baby';

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryDark),
        title: Text(
          albumName, // Swapped: Album name is now in the app bar
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: primaryDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AlbumBackgroundPainter(
                seed: albumName.hashCode,
                surfaceColor: surface,
                accentColor: primaryAccent,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome, color: primaryAccent, size: 28),
                      const SizedBox(height: 16),
                      Text(
                        "$babyName's Album", // Swapped: Baby's Album is now the big header
                        style: GoogleFonts.sacramento(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: secondaryTone,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${memories.length} Memories',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Divider(color: dividerColor, thickness: 1.5, indent: 40, endIndent: 40),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList.builder(
                  itemCount: memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    final isEven = index % 2 == 0;
                    
                    // Determine which organic shape to use
                    final shapeType = index % 3;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: _OrganicKeepsakeCard(
                        memory: memory, 
                        shapeType: shapeType,
                        isEven: isEven,
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
            ],
          ),
        ],
      ),
    );
  }
}

class _OrganicKeepsakeCard extends StatelessWidget {
  final Memory memory;
  final int shapeType; // 0, 1, 2 for different organic shapes
  final bool isEven;

  const _OrganicKeepsakeCard({
    required this.memory, 
    required this.shapeType,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    // Alternate aspect ratios to create the organic physical feel
    double aspectRatio = 1.0;
    if (shapeType == 0) {
      aspectRatio = 0.85; // Taller
    } else if (shapeType == 1) {
      aspectRatio = 1.1; // Wider
    } else {
      aspectRatio = 1.0; // Square-ish
    }

    CustomClipper<Path> clipper;
    switch (shapeType) {
      case 0:
        clipper = _BlobClipperA();
        break;
      case 1:
        clipper = _BlobClipperB();
        break;
      default:
        clipper = _SquircleClipper();
    }

    final imageWidget = AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ShadowPainter(clipper: clipper, shadowColor: KeepsakeViewerScreen.primaryDark.withValues(alpha: 0.15)),
            ),
          ),
          ClipPath(
            clipper: clipper,
            child: Container(
              color: KeepsakeViewerScreen.dividerColor,
              child: CachedNetworkImage(
                imageUrl: memory.thumbnailUrl.isNotEmpty ? memory.thumbnailUrl : memory.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: KeepsakeViewerScreen.secondaryTone.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(Icons.photo_library_outlined, color: KeepsakeViewerScreen.primaryAccent),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: KeepsakeViewerScreen.secondaryTone,
                  child: const Icon(Icons.error_outline, color: KeepsakeViewerScreen.primaryDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final textWidget = Padding(
      padding: EdgeInsets.only(
        left: isEven ? 16.0 : 0.0,
        right: isEven ? 0.0 : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(memory.takenAt),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KeepsakeViewerScreen.primaryAccent,
              letterSpacing: 0.5,
            ),
          ),
          if (memory.caption?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              memory.caption!,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: KeepsakeViewerScreen.textPrimary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isEven) ...[
          Expanded(flex: 5, child: imageWidget),
          Expanded(flex: 4, child: textWidget),
        ] else ...[
          Expanded(flex: 4, child: textWidget),
          Expanded(flex: 5, child: imageWidget),
        ]
      ],
    );
  }
}

// Custom Clippers for Organic Shapes

class _BlobClipperA extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    
    // Organic blob shape A (top left wide, bottom right tight)
    path.moveTo(w * 0.2, 0);
    path.quadraticBezierTo(w * 0.8, h * 0.05, w, h * 0.3);
    path.quadraticBezierTo(w * 0.95, h * 0.8, w * 0.7, h);
    path.quadraticBezierTo(w * 0.2, h * 0.95, 0, h * 0.7);
    path.quadraticBezierTo(w * 0.05, h * 0.2, w * 0.2, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BlobClipperB extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    
    // Organic blob shape B (asymmetric waves)
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.9, 0, w, h * 0.2, w, h * 0.5);
    path.cubicTo(w, h * 0.9, w * 0.7, h, w * 0.4, h);
    path.cubicTo(w * 0.1, h, 0, h * 0.8, 0, h * 0.4);
    path.cubicTo(0, h * 0.1, w * 0.2, 0, w * 0.5, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SquircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    
    // Smooth squircle (continuous curve)
    final r = w * 0.3; // Corner radius approximation
    
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w, 0, w, 0, w, h * 0.5);
    path.cubicTo(w, h, w, h, w * 0.5, h);
    path.cubicTo(0, h, 0, h, 0, h * 0.5);
    path.cubicTo(0, 0, 0, 0, w * 0.5, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ShadowPainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final Color shadowColor;

  _ShadowPainter({required this.clipper, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    canvas.drawShadow(path, shadowColor, 8, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlbumBackgroundPainter extends CustomPainter {
  final int seed;
  final Color surfaceColor;
  final Color accentColor;

  _AlbumBackgroundPainter({
    required this.seed,
    required this.surfaceColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the background
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);

    // Use a simple pseudo-random generator based on seed to pick a design
    final designType = seed % 3;

    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (designType == 0) {
      // Design 0: Large soft overlapping waves
      final path = Path();
      path.moveTo(0, size.height * 0.2);
      path.quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, size.height * 0.4);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
      canvas.drawPath(path, paint);

      final path2 = Path();
      path2.moveTo(0, size.height * 0.7);
      path2.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.6);
      path2.lineTo(size.width, size.height);
      path2.lineTo(0, size.height);
      path2.close();
      canvas.drawPath(path2, paint);
    } else if (designType == 1) {
      // Design 1: Abstract shapes (circles and lines)
      canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), size.width * 0.3, paint);
      canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), size.width * 0.4, paint);
      
      canvas.drawLine(Offset(size.width * 0.8, size.height * 0.1), Offset(size.width * 0.95, size.height * 0.3), strokePaint);
      canvas.drawLine(Offset(size.width * 0.1, size.height * 0.7), Offset(size.width * 0.3, size.height * 0.95), strokePaint);
    } else {
      // Design 2: Confetti/Dots scattered
      for (int i = 0; i < 40; i++) {
        // pseudo-random generation based on seed
        final x = (seed * i * 31 % 100) / 100.0 * size.width;
        final y = (seed * i * 17 % 100) / 100.0 * size.height;
        final r = (seed * i * 7 % 15) + 5.0;
        
        if (i % 2 == 0) {
          canvas.drawCircle(Offset(x, y), r, paint);
        } else {
          canvas.drawCircle(Offset(x, y), r / 2, strokePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
