import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final inputPath = _argValue(args, 'input') ?? _defaultInputPath();
  final outputPath =
      _argValue(args, 'output') ?? 'assets/icon/app_icon_1024.png';
  final size = int.tryParse(_argValue(args, 'size') ?? '') ?? 1024;

  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_helpText());
    return;
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Icon input not found: $inputPath');
    stderr.writeln('Put your icon at assets/icon/app_icon.png (recommended),');
    stderr.writeln('or re-run with: --input=path/to/your.png|.jpg|.jpeg');
    exitCode = 2;
    return;
  }

  final decoded = img.decodeImage(inputFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode image: $inputPath');
    exitCode = 3;
    return;
  }

  final cropped = _centerCropSquare(decoded);
  final resized = img.copyResize(
    cropped,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsBytesSync(img.encodePng(resized, level: 6));

  stdout.writeln('Wrote: $outputPath');
  stdout.writeln(
    'Next: dart run flutter_launcher_icons -f flutter_launcher_icons.yaml',
  );
}

String? _argValue(List<String> args, String name) {
  final prefix = '--$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

img.Image _centerCropSquare(img.Image source) {
  final side = source.width < source.height ? source.width : source.height;
  final x = ((source.width - side) / 2).round();
  final y = ((source.height - side) / 2).round();
  return img.copyCrop(source, x: x, y: y, width: side, height: side);
}

String _helpText() => '''
Converts a source image into a square PNG suitable for app icon generation.

Defaults:
  --input=assets/icon/app_icon.png (falls back to .jpeg if present)
  --output=assets/icon/app_icon_1024.png
  --size=1024

Examples:
  dart run tool/icon/convert_app_icon.dart
  dart run tool/icon/convert_app_icon.dart --input=assets/icon/my_icon.jpg
  dart run tool/icon/convert_app_icon.dart --input=assets/icon/my_icon.jpeg --output=assets/icon/app_icon_1024.png
''';

String _defaultInputPath() {
  const preferred = 'assets/icon/app_icon.png';
  const jpegFallback = 'assets/icon/app_icon.jpeg';

  if (File(preferred).existsSync()) return preferred;
  if (File(jpegFallback).existsSync()) return jpegFallback;
  return preferred;
}
