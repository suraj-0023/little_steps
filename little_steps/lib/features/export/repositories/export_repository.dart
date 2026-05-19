import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../memory/models/memory.dart';

enum PdfTemplate {
  softPastel,
  boldModern,
  classicScrapbook,
  minimalClean,
}

extension PdfTemplateLabel on PdfTemplate {
  String get label {
    switch (this) {
      case PdfTemplate.softPastel: return 'Soft & Pastel';
      case PdfTemplate.boldModern: return 'Bold & Modern';
      case PdfTemplate.classicScrapbook: return 'Classic Scrapbook';
      case PdfTemplate.minimalClean: return 'Minimal Clean';
    }
  }

  String get description {
    switch (this) {
      case PdfTemplate.softPastel:
        return 'Warm pinks & lavender, rounded frames, gentle typography';
      case PdfTemplate.boldModern:
        return 'Dark cover, white text, strong geometric layout';
      case PdfTemplate.classicScrapbook:
        return 'Warm cream tones, decorative borders, journal-style captions';
      case PdfTemplate.minimalClean:
        return 'Airy white space, light grid, small elegant captions';
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

    // Cover
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 80,
                height: 4,
                color: accent,
                margin: const pw.EdgeInsets.only(bottom: 24),
              ),
              pw.Text(babyName,
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  )),
              pw.SizedBox(height: 12),
              pw.Text(monthLabel,
                  style: pw.TextStyle(fontSize: 22, color: accent)),
              pw.SizedBox(height: 8),
              pw.Text('${memories.length} beautiful memories',
                  style: pw.TextStyle(fontSize: 13, color: textColor)),
              pw.Container(
                width: 80,
                height: 4,
                color: accent,
                margin: const pw.EdgeInsets.only(top: 24),
              ),
            ],
          ),
        ),
      ),
    ));

    // 2-column photo pages with rounded frames
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
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: accent, width: 3),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 10,
                      verticalRadius: 10,
                      child: pw.Expanded(
                        child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(date,
                      style: pw.TextStyle(fontSize: 8, color: accent)),
                  if (caption.isNotEmpty)
                    pw.Text(caption,
                        style: pw.TextStyle(
                            fontSize: 8, color: textColor,
                            fontStyle: pw.FontStyle.italic),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip),
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

    // Full-bleed cover
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
                  style: pw.TextStyle(
                      fontSize: 52,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
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

    // Full-width single photo pages
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
                child: pw.Image(img, fit: pw.BoxFit.cover,
                    width: double.infinity),
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
                        style: pw.TextStyle(
                            color: accent, fontSize: 10)),
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

    // Cover with decorative border frame
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Container(
        color: bg,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border, width: 4),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('✦ ✦ ✦',
                      style: pw.TextStyle(fontSize: 20, color: border)),
                  pw.SizedBox(height: 24),
                  pw.Text(babyName,
                      style: pw.TextStyle(
                          fontSize: 42,
                          fontWeight: pw.FontWeight.bold,
                          color: textColor)),
                  pw.SizedBox(height: 8),
                  pw.Text('Memory Album',
                      style: pw.TextStyle(fontSize: 16, color: border)),
                  pw.SizedBox(height: 4),
                  pw.Text(monthLabel,
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: textColor)),
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

    // 3-column grid
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
                        border: pw.Border.all(color: border, width: 2),
                      ),
                      child: pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      DateFormat('d MMM yyyy').format(pageMems[j].takenAt),
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: border,
                          fontStyle: pw.FontStyle.italic),
                    ),
                    if ((pageMems[j].caption ?? '').isNotEmpty)
                      pw.Text(
                        pageMems[j].caption!,
                        style: pw.TextStyle(
                            fontSize: 7, color: textColor),
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

    // Clean cover
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Padding(
        padding: const pw.EdgeInsets.all(60),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Spacer(flex: 2),
            pw.Text(babyName,
                style: pw.TextStyle(
                    fontSize: 44,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900)),
            pw.Container(
              width: 48,
              height: 3,
              color: accent,
              margin: const pw.EdgeInsets.symmetric(vertical: 12),
            ),
            pw.Text(monthLabel,
                style: pw.TextStyle(fontSize: 18, color: accent)),
            pw.SizedBox(height: 4),
            pw.Text('${memories.length} memories',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey500)),
            pw.Spacer(flex: 3),
          ],
        ),
      ),
    ));

    // 2x2 minimal grid
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
            final date =
                DateFormat('d MMM').format(pageMems[j].takenAt);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: light,
                    ),
                    child:
                        pw.Image(pageImgs[j], fit: pw.BoxFit.cover),
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
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip),
                      ),
                    pw.Text(date,
                        style:
                            pw.TextStyle(fontSize: 7, color: accent)),
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

  // ── Helpers ───────────────────────────────────────────────────────

  Future<File> _save(
      pw.Document pdf, String babyName, String monthLabel) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/littlesteps_${monthLabel.replaceAll(' ', '_')}.pdf');
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
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }
}
