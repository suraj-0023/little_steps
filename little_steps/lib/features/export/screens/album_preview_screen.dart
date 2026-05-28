import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class AlbumPreviewScreen extends StatelessWidget {
  const AlbumPreviewScreen({
    super.key,
    required this.pdfFile,
    required this.albumName,
  });

  final File pdfFile;
  final String albumName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) => pdfFile.readAsBytesSync(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: 700,
        pdfFileName: pdfFile.path.split('/').last,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
