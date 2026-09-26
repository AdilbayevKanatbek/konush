// Asset generator, executed by the headless Flutter runner:
// flutter test tool/generate_brand_assets.dart
// Optional: --dart-define=BRAND_FONT=/path/to/Onest.ttf
//          --dart-define=BRAND_OUTPUT=/path/to/previews
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/core/ui/konush_brand.dart';
import 'package:konush/src/core/ui/konush_ui.dart';

const _output = String.fromEnvironment(
  'BRAND_OUTPUT',
  defaultValue: '../output/konush-brand-20260927',
);
const _font = String.fromEnvironment('BRAND_FONT');

// App Store icons must be RGB PNGs without an alpha channel, even when opaque.
Uint8List _rgbPng(int width, int height, Uint8List rgba) {
  final rows = Uint8List(height * (width * 3 + 1));
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final source = (y * width + x) * 4;
      if (rgba[source + 3] != 255) {
        throw StateError('iOS icon has a transparent pixel at $x, $y');
      }
      final target = y * (width * 3 + 1) + 1 + x * 3;
      rows.setRange(target, target + 3, rgba, source);
    }
  }
  final output = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final payload = [...ascii.encode(type), ...data];
    var crc = 0xffffffff;
    for (final byte in payload) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
      }
    }
    output
      ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
      ..add(payload)
      ..add((ByteData(4)..setUint32(0, crc ^ 0xffffffff)).buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibEncoder().convert(rows));
  chunk('IEND', const []);
  return output.takeBytes();
}

Future<void> _png(ui.Image image, String path, {bool opaque = false}) async {
  final bytes = await image.toByteData(
    format: opaque ? ui.ImageByteFormat.rawRgba : ui.ImageByteFormat.png,
  );
  final rgba = bytes!.buffer.asUint8List();
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    opaque ? _rgbPng(image.width, image.height, rgba) : rgba,
  );
  image.dispose();
}

class _LauncherPainter extends CustomPainter {
  const _LauncherPainter({
    this.foregroundOnly = false,
    this.monochrome = false,
    this.square = false,
  });

  final bool foregroundOnly, monochrome, square;

  @override
  void paint(Canvas canvas, Size size) {
    if (!foregroundOnly) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(square ? 0 : size.width * .24),
        ),
        Paint()..color = konushBrandColor,
      );
    }
    // Adaptive foreground includes the OS motion/cropping margin (108 dp).
    final side = size.width * (foregroundOnly ? .50 : .72);
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    paintKonushSymbol(
      canvas,
      Size.square(side),
      color: Colors.white,
      accent: monochrome ? Colors.white : konushBrandAccent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LauncherPainter oldDelegate) => false;
}

Future<void> _icon(String path, int pixels, _LauncherPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(pixels.toDouble()));
  final picture = recorder.endRecording();
  await _png(
    await picture.toImage(pixels, pixels),
    path,
    opaque: painter.square,
  );
  picture.dispose();
}

Widget _sampleIcon(double size) =>
    CustomPaint(size: Size.square(size), painter: const _LauncherPainter());

void main() {
  testWidgets('Generate mobile brand assets and visual preview', (
    tester,
  ) async {
    await tester.runAsync(() async {
      if (_font.isNotEmpty) {
        final bytes = await File(_font).readAsBytes();
        await (FontLoader(
          'Onest',
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
      const densities = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final density in densities.entries) {
        await _icon(
          'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png',
          density.value,
          const _LauncherPainter(),
        );
      }
      await _icon(
        'android/app/src/main/res/drawable-nodpi/konush_icon_foreground.png',
        432,
        const _LauncherPainter(foregroundOnly: true),
      );
      await _icon(
        'android/app/src/main/res/drawable-nodpi/konush_icon_monochrome.png',
        432,
        const _LauncherPainter(foregroundOnly: true, monochrome: true),
      );
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final manifest =
          jsonDecode(await File('$ios/Contents.json').readAsString())
              as Map<String, dynamic>;
      final rendered = <String>{};
      for (final item in manifest['images'] as List<dynamic>) {
        final name = item['filename'] as String;
        if (!rendered.add(name)) continue;
        final size = double.parse((item['size'] as String).split('x').first);
        final scale = double.parse(
          (item['scale'] as String).replaceAll('x', ''),
        );
        await _icon(
          '$ios/$name',
          (size * scale).round(),
          const _LauncherPainter(square: true),
        );
      }
      await _icon('$_output/app-icon.png', 512, const _LauncherPainter());
    });

    tester.view.physicalSize = const Size(800, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frame = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Onest', color: ink, fontSize: 14),
          child: RepaintBoundary(
            key: frame,
            child: ColoredBox(
              color: const Color(0xFFF5F7F5),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KONUSH / ОБНОВЛЁННЫЙ ЗНАК',
                      style: TextStyle(
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: TransformScaleWordmark(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 230,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(child: _sampleIcon(120)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Логотип в приложении',
                            style: TextStyle(color: muted),
                          ),
                        ),
                        SizedBox(
                          width: 230,
                          child: Row(
                            children: [
                              _sampleIcon(40),
                              const SizedBox(width: 12),
                              _sampleIcon(28),
                              const SizedBox(width: 12),
                              _sampleIcon(20),
                              const SizedBox(width: 12),
                              const Text(
                                'Иконка',
                                style: TextStyle(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      await _png(
        await boundary.toImage(pixelRatio: 2),
        '$_output/brand-preview.png',
      );
    });
  });
}

class TransformScaleWordmark extends StatelessWidget {
  const TransformScaleWordmark({super.key});

  @override
  Widget build(BuildContext context) =>
      Transform.scale(scale: 2, child: const KonushWordmark());
}
