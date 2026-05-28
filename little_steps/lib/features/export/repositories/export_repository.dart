import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../memory/models/memory.dart';

enum PdfTemplate {
  softPastel,
  boldModern,
  classicScrapbook,
  minimalClean,
  lullabyBlue,
  sunflowerDays,
  vintagePolaroid,
  forestWalk,
  celebration,
}

extension PdfTemplateLabel on PdfTemplate {
  String get label {
    switch (this) {
      case PdfTemplate.softPastel: return 'Soft & Pastel';
      case PdfTemplate.boldModern: return 'Bold & Modern';
      case PdfTemplate.classicScrapbook: return 'Classic Scrapbook';
      case PdfTemplate.minimalClean: return 'Minimal Clean';
      case PdfTemplate.lullabyBlue: return 'Lullaby Blue';
      case PdfTemplate.sunflowerDays: return 'Sunflower Days';
      case PdfTemplate.vintagePolaroid: return 'Vintage Polaroid';
      case PdfTemplate.forestWalk: return 'Forest Walk';
      case PdfTemplate.celebration: return 'Celebration';
    }
  }

  String get description {
    switch (this) {
      case PdfTemplate.softPastel: return 'Warm pinks & lavender, rounded frames';
      case PdfTemplate.boldModern: return 'Dark cover, geometric layout, bold text';
      case PdfTemplate.classicScrapbook: return 'Warm cream tones, decorative gold borders';
      case PdfTemplate.minimalClean: return 'Airy white space, light grid, clean captions';
      case PdfTemplate.lullabyBlue: return 'Soft blues, dreamy and peaceful mood';
      case PdfTemplate.sunflowerDays: return 'Warm yellows and oranges, sunny feel';
      case PdfTemplate.vintagePolaroid: return 'Polaroid-style frames with handwritten feel';
      case PdfTemplate.forestWalk: return 'Natural greens and earthy tones';
      case PdfTemplate.celebration: return 'Bright, joyful colors for every milestone';
    }
  }

  List<int> get swatchColors {
    switch (this) {
      case PdfTemplate.softPastel: return [0xFFFDF6F0, 0xFFC9A7D0, 0xFF6B4C72];
      case PdfTemplate.boldModern: return [0xFF1A1A2E, 0xFFE94560, 0xFF16213E];
      case PdfTemplate.classicScrapbook: return [0xFFFAF0DC, 0xFFB5924C, 0xFF5C3D1E];
      case PdfTemplate.minimalClean: return [0xFFFFFFFF, 0xFF4A90D9, 0xFFE8F0FA];
      case PdfTemplate.lullabyBlue: return [0xFFEFF6FF, 0xFF3B82F6, 0xFF1E3A5F];
      case PdfTemplate.sunflowerDays: return [0xFFFFFBEB, 0xFFF59E0B, 0xFF78350F];
      case PdfTemplate.vintagePolaroid: return [0xFFFAFAFA, 0xFF374151, 0xFFD1D5DB];
      case PdfTemplate.forestWalk: return [0xFFF0FDF4, 0xFF16A34A, 0xFF14532D];
      case PdfTemplate.celebration: return [0xFFFFF7F7, 0xFFEF4444, 0xFF7C3AED];
    }
  }
}

class ExportRepository {
  Future<File> buildMemoryPdf(
    List<Memory> memories,
    String babyName,
    String monthLabel,
    PdfTemplate template,
  ) async {
    switch (template) {
      case PdfTemplate.softPastel:
        return _buildSoftPastel(memories, babyName, monthLabel);
      case PdfTemplate.boldModern:
        return _buildBoldModern(memories, babyName, monthLabel);
      case PdfTemplate.classicScrapbook:
        return _buildClassicScrapbook(memories, babyName, monthLabel);
      case PdfTemplate.minimalClean:
        return _buildMinimalClean(memories, babyName, monthLabel);
      case PdfTemplate.lullabyBlue:
        return _buildLullabyBlue(memories, babyName, monthLabel);
      case PdfTemplate.sunflowerDays:
        return _buildSunflowerDays(memories, babyName, monthLabel);
      case PdfTemplate.vintagePolaroid:
        return _buildVintagePolaroid(memories, babyName, monthLabel);
      case PdfTemplate.forestWalk:
        return _buildForestWalk(memories, babyName, monthLabel);
      case PdfTemplate.celebration:
        return _buildCelebration(memories, babyName, monthLabel);
    }
  }

  // ── Soft & Pastel ─────────────────────────────────────────────────

  Future<File> _buildSoftPastel(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFFDF6F0);
    const accent = PdfColor.fromInt(0xFFC9A7D0);
    const textColor = PdfColor.fromInt(0xFF6B4C72);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(width: 80, height: 4, color: accent,
                  margin: const pw.EdgeInsets.only(bottom: 24)),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 48,
                      fontWeight: pw.FontWeight.bold, color: textColor)),
              pw.SizedBox(height: 12),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 22, color: accent)),
              pw.SizedBox(height: 8),
              pw.Text('${memories.length} beautiful memories',
                  style: pw.TextStyle(fontSize: 13, color: textColor)),
              pw.Container(width: 80, height: 4, color: accent,
                  margin: const pw.EdgeInsets.only(top: 24)),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Container(
          color: bg,
          child: pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: List.generate(pageImgs.length, (j) {
              final caption = pageMems[j].caption ?? '';
              final date = DateFormat('d MMM yyyy').format(pageMems[j].takenAt);
              return pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accent, width: 3),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(date,
                      style: pw.TextStyle(fontSize: 8, color: accent)),
                  if (caption.isNotEmpty)
                    pw.Text(caption,
                        style: pw.TextStyle(fontSize: 8, color: textColor,
                            fontStyle: pw.FontStyle.italic),
                        maxLines: 2, overflow: pw.TextOverflow.clip),
                ],
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Bold & Modern ─────────────────────────────────────────────────

  Future<File> _buildBoldModern(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFF1A1A2E);
    const accent = PdfColor.fromInt(0xFFE94560);
    const cardBg = PdfColor.fromInt(0xFF16213E);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(48),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Spacer(),
              pw.Container(width: 60, height: 5, color: accent),
              pw.SizedBox(height: 16),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 52,
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 8),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 24, color: accent)),
              pw.SizedBox(height: 4),
              pw.Text('${memories.length} memories',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey400)),
              pw.Spacer(flex: 2),
            ],
          ),
        ),
      ),
    ));

    for (final entry in images.asMap().entries) {
      final i = entry.key;
      final img = entry.value;
      final caption = memories[i].caption ?? '';
      final date = DateFormat('d MMM yyyy').format(memories[i].takenAt);
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: bg,
          child: pw.Column(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Image(img, fit: pw.BoxFit.cover),
              ),
              pw.Container(
                color: cardBg,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (caption.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(caption,
                            style: const pw.TextStyle(
                                color: PdfColors.white, fontSize: 11),
                            maxLines: 2),
                      ),
                    pw.Text(date,
                        style: pw.TextStyle(color: accent, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Classic Scrapbook ─────────────────────────────────────────────

  Future<File> _buildClassicScrapbook(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFFAF0DC);
    const border = PdfColor.fromInt(0xFFB5924C);
    const textColor = PdfColor.fromInt(0xFF5C3D1E);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: border, width: 4)),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('✦ ✦ ✦',
                      style: pw.TextStyle(fontSize: 20, color: border)),
                  pw.SizedBox(height: 24),
                  pw.Text(babyName,
                      style: pw.TextStyle(fontSize: 42,
                          fontWeight: pw.FontWeight.bold, color: textColor)),
                  pw.SizedBox(height: 8),
                  pw.Text('Memory Album',
                      style: pw.TextStyle(fontSize: 16, color: border)),
                  pw.SizedBox(height: 4),
                  pw.Text(monthLabel,
                      style: pw.TextStyle(fontSize: 20,
                          fontWeight: pw.FontWeight.bold, color: textColor)),
                  pw.SizedBox(height: 24),
                  pw.Text('✦ ✦ ✦',
                      style: pw.TextStyle(fontSize: 20, color: border)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 3) {
      final pageImgs = images.skip(i).take(3).toList();
      final pageMems = memories.skip(i).take(3).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Container(
          color: bg,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: List.generate(pageImgs.length, (j) => pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  children: [
                    pw.Container(
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: border, width: 2)),
                      child: pw.SizedBox(
                        height: 160,
                        child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      DateFormat('d MMM yyyy').format(pageMems[j].takenAt),
                      style: pw.TextStyle(fontSize: 7, color: border,
                          fontStyle: pw.FontStyle.italic),
                    ),
                    if ((pageMems[j].caption ?? '').isNotEmpty)
                      pw.Text(
                        pageMems[j].caption!,
                        style: pw.TextStyle(fontSize: 7, color: textColor),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
            )),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Minimal Clean ──────────────────────────────────────────────────

  Future<File> _buildMinimalClean(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const accent = PdfColor.fromInt(0xFF4A90D9);
    const light = PdfColor.fromInt(0xFFE8F0FA);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Padding(
        padding: const pw.EdgeInsets.all(60),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Spacer(flex: 2),
            pw.Text(babyName,
                style: pw.TextStyle(fontSize: 44,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.Container(width: 48, height: 3, color: accent,
                margin: const pw.EdgeInsets.symmetric(vertical: 12)),
            pw.Text(monthLabel,
                style: pw.TextStyle(fontSize: 18, color: accent)),
            pw.SizedBox(height: 4),
            pw.Text('${memories.length} memories',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500)),
            pw.Spacer(flex: 3),
          ],
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.GridView(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: List.generate(pageImgs.length, (j) {
            final caption = pageMems[j].caption ?? '';
            final date = DateFormat('d MMM').format(pageMems[j].takenAt);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(color: light),
                    child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (caption.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(caption,
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey700),
                            maxLines: 1, overflow: pw.TextOverflow.clip),
                      ),
                    pw.Text(date,
                        style: pw.TextStyle(fontSize: 7, color: accent)),
                  ],
                ),
              ],
            );
          }),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Lullaby Blue ──────────────────────────────────────────────────

  Future<File> _buildLullabyBlue(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFEFF6FF);
    const accent = PdfColor.fromInt(0xFF3B82F6);
    const dark = PdfColor.fromInt(0xFF1E3A5F);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(width: 40, height: 40,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle, color: accent)),
              pw.SizedBox(height: 20),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 44,
                      fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 8),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 20, color: accent)),
              pw.SizedBox(height: 4),
              pw.Text('${memories.length} memories',
                  style: pw.TextStyle(fontSize: 12, color: dark)),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Container(
          color: bg,
          child: pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: List.generate(pageImgs.length, (j) {
              final caption = pageMems[j].caption ?? '';
              final date = DateFormat('d MMM').format(pageMems[j].takenAt);
              return pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accent, width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(date, style: pw.TextStyle(fontSize: 8, color: accent)),
                  if (caption.isNotEmpty)
                    pw.Text(caption,
                        style: pw.TextStyle(fontSize: 8, color: dark),
                        maxLines: 1, overflow: pw.TextOverflow.clip),
                ],
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Sunflower Days ────────────────────────────────────────────────

  Future<File> _buildSunflowerDays(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFFFFBEB);
    const accent = PdfColor.fromInt(0xFFF59E0B);
    const dark = PdfColor.fromInt(0xFF78350F);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(48),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Row(children: [
                pw.Container(width: 12, height: 12,
                    decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle, color: accent)),
                pw.SizedBox(width: 8),
                pw.Container(width: 8, height: 8,
                    decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle, color: accent)),
              ]),
              pw.SizedBox(height: 16),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 46,
                      fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 6),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 22, color: accent)),
              pw.SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 3) {
      final pageImgs = images.skip(i).take(3).toList();
      final pageMems = memories.skip(i).take(3).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Container(
          color: bg,
          child: pw.Column(
            children: List.generate(pageImgs.length, (j) {
              final caption = pageMems[j].caption ?? '';
              final date = DateFormat('d MMM yyyy').format(pageMems[j].takenAt);
              return pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 180,
                        height: 140,
                        child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(date,
                                style: pw.TextStyle(fontSize: 10, color: accent,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 6),
                            if (caption.isNotEmpty)
                              pw.Text(caption,
                                  style: pw.TextStyle(fontSize: 11, color: dark),
                                  maxLines: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Vintage Polaroid ──────────────────────────────────────────────

  Future<File> _buildVintagePolaroid(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFFAFAFA);
    const dark = PdfColor.fromInt(0xFF374151);
    const caption = PdfColor.fromInt(0xFF6B7280);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 40,
                      fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 8),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 18, color: caption)),
              pw.SizedBox(height: 4),
              pw.Text('${memories.length} memories',
                  style: pw.TextStyle(fontSize: 11, color: caption)),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Container(
          color: bg,
          child: pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(pageImgs.length, (j) {
              final label = pageMems[j].caption?.isNotEmpty == true
                  ? pageMems[j].caption!
                  : DateFormat('d MMM yyyy').format(pageMems[j].takenAt);
              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  boxShadow: [
                    pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4,
                        offset: const PdfPoint(2, 2)),
                  ],
                ),
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(label,
                          style: pw.TextStyle(fontSize: 9, color: caption,
                              fontStyle: pw.FontStyle.italic),
                          maxLines: 2, textAlign: pw.TextAlign.center,
                          overflow: pw.TextOverflow.clip),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Forest Walk ───────────────────────────────────────────────────

  Future<File> _buildForestWalk(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFF0FDF4);
    const accent = PdfColor.fromInt(0xFF16A34A);
    const dark = PdfColor.fromInt(0xFF14532D);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(48),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(width: 4, height: 60, color: accent),
              pw.SizedBox(height: 16),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 44,
                      fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 8),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 20, color: accent)),
              pw.SizedBox(height: 4),
              pw.Text('${memories.length} memories',
                  style: pw.TextStyle(fontSize: 12, color: dark)),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Container(
          color: bg,
          child: pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.88,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: List.generate(pageImgs.length, (j) {
              final cap = pageMems[j].caption ?? '';
              final date = DateFormat('d MMM').format(pageMems[j].takenAt);
              return pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accent, width: 2),
                      ),
                      child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(date,
                          style: pw.TextStyle(fontSize: 7, color: accent)),
                      if (cap.isNotEmpty)
                        pw.Expanded(
                          child: pw.Text(cap,
                              style: pw.TextStyle(fontSize: 7, color: dark),
                              maxLines: 1, overflow: pw.TextOverflow.clip,
                              textAlign: pw.TextAlign.right),
                        ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Celebration ───────────────────────────────────────────────────

  Future<File> _buildCelebration(
      List<Memory> memories, String babyName, String monthLabel) async {
    final pdf = pw.Document();
    final images = await _loadImages(memories, max: 20);
    const bg = PdfColor.fromInt(0xFFFFF7F7);
    const red = PdfColor.fromInt(0xFFEF4444);
    const purple = PdfColor.fromInt(0xFF7C3AED);
    const dark = PdfColor.fromInt(0xFF1F2937);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(width: 20, height: 20,
                      decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle, color: red)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 14, height: 14,
                      decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle, color: purple)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 20, height: 20,
                      decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle, color: red)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(babyName,
                  style: pw.TextStyle(fontSize: 46,
                      fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 8),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 22, color: purple)),
              pw.SizedBox(height: 4),
              pw.Text('${memories.length} memories to celebrate!',
                  style: pw.TextStyle(fontSize: 13, color: red)),
            ],
          ),
        ),
      ),
    ));

    for (var i = 0; i < images.length; i += 4) {
      final pageImgs = images.skip(i).take(4).toList();
      final pageMems = memories.skip(i).take(4).toList();
      final colors = [red, purple, red, purple];
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Container(
          color: bg,
          child: pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 0.88,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: List.generate(pageImgs.length, (j) {
              final cap = pageMems[j].caption ?? '';
              final date = DateFormat('d MMM').format(pageMems[j].takenAt);
              final col = colors[j % colors.length];
              return pw.Column(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: col, width: 3),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(date, style: pw.TextStyle(fontSize: 8, color: col,
                      fontWeight: pw.FontWeight.bold)),
                  if (cap.isNotEmpty)
                    pw.Text(cap, style: pw.TextStyle(fontSize: 7, color: dark),
                        maxLines: 1, overflow: pw.TextOverflow.clip),
                ],
              );
            }),
          ),
        ),
      ));
    }
    return _save(pdf, babyName, monthLabel);
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<File> _save(
      pw.Document pdf, String babyName, String monthLabel) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File(
        '${exportDir.path}/littlesteps_${monthLabel.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<List<pw.MemoryImage>> _loadImages(List<Memory> memories,
      {int max = 20}) async {
    final capped = memories.take(max).toList();
    final bytesList = await Future.wait(
      capped.map((m) => _fetchBytes(m.thumbnailUrl)),
    );
    final result = <pw.MemoryImage>[];
    for (final bytes in bytesList) {
      if (bytes != null) result.add(pw.MemoryImage(bytes));
    }
    return result;
  }

  Future<Uint8List?> _fetchBytes(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  Future<File> saveHtmlPdf(
      Uint8List pdfBytes, String babyName, String monthLabel) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final cleanLabel = monthLabel.replaceAll(' ', '_').replaceAll('/', '_');
    final file = File('${exportDir.path}/littlesteps_$cleanLabel.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  Future<File> compileHtmlToPdf({
    required String htmlContent,
    required List<Uint8List> compressedImageBytes,
    required String babyName,
    required String monthLabel,
  }) async {
    var finalHtml = htmlContent;
    for (var i = 0; i < compressedImageBytes.length; i++) {
      final base64Image = base64Encode(compressedImageBytes[i]);
      final dataUri = 'data:image/jpeg;base64,$base64Image';
      finalHtml = finalHtml.replaceAll('IMAGE_PLACEHOLDER_$i', dataUri);
    }

    final pdfBytes = await Printing.convertHtml(
      html: finalHtml,
      format: PdfPageFormat.a4,
    );

    return saveHtmlPdf(pdfBytes, babyName, monthLabel);
  }
}
