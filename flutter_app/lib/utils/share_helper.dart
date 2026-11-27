import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<Uint8List?> captureBoundaryPng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final renderObj = context.findRenderObject();
    if (renderObj is! RenderRepaintBoundary) return null;
    final image = await renderObj.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<void> sharePngBytes({
    required Uint8List bytes,
    required String filename,
    required String title,
    required String text,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: safeName)],
        title: title,
        text: text,
      ),
    );
  }

  static Future<void> shareText({
    required String text,
    String? title,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: title,
      ),
    );
  }

  static Future<void> shareJsonBackup({
    required String jsonContent,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonContent, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: filename)],
        title: 'Atomic Habits Backup',
        text: 'Atomic Habits JSON backup',
      ),
    );
  }
}
