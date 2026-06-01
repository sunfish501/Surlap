import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 전역 key — MainShell의 RepaintBoundary에 연결
final screenshotKey = GlobalKey();

Future<void> captureAndShare() async {
  final boundary = screenshotKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;
  try {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fname = '달력_${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}.png';
    final file = File('${dir.path}/$fname');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)], text: 'spaceHour 달력');
  } catch (_) {}
}
