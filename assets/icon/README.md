# App Icon (Source)

Put your source app icon image in this folder.

## Recommended filename

- `assets/icon/app_icon.png`

Supported source formats: `.png`, `.jpg`, `.jpeg` (the converter auto-detects).

Use a square image if possible. If it isn’t square, the converter will center-crop.

## Generate launcher icons

1) Convert JPEG to a 1024×1024 PNG (what the generator consumes):

```bash
dart run tool/icon/convert_app_icon.dart
```

This writes:
- `assets/icon/app_icon_1024.png`

2) Generate platform icons (Android / iOS / Web / macOS / Windows):

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

This repo currently generates icons for Android, iOS, Web, and macOS. (There is no `windows/` folder yet.)

## Notes

- If your JPEG isn’t square, the converter will center-crop to a square.
- For App Store submission, iOS icons must not contain transparency (alpha). If your source has transparency, use a non-transparent background before publishing.
