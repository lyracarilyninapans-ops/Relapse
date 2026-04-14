import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerIconUtils {
  MapMarkerIconUtils._();

  static Future<BitmapDescriptor> materialIconMarker({
    required IconData icon,
    required Color iconColor,
    double size = 56,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.84,
          color: iconColor,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          shadows: const [
            Shadow(
              blurRadius: 2,
              color: Color(0x66000000),
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    )..layout();

    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarker;
    }
    return BitmapDescriptor.bytes(Uint8List.view(bytes.buffer));
  }
}
