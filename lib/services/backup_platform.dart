// Platform-specific backup helpers — routes to the correct implementation
// at compile time so neither dart:io nor dart:html leaks into the wrong target.
export 'backup_platform_stub.dart'
    if (dart.library.html) 'backup_platform_web.dart'
    if (dart.library.io) 'backup_platform_io.dart';

// Shared API surface (implemented by the above conditional exports).
//
// - saveBackupFile(...): export backup to user-visible storage.
// - readPickedBackupFile(...): restore backup by reading picked file.
// - openBackupLocation(...): open the containing folder/location in the OS.
