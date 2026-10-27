import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

/// Hands a file to the user, as a browser download on the web.
abstract interface class FileSaver {
  Future<void> save({
    required String fileName,
    required String mimeType,
    required String contents,
  });
}

final fileSaverProvider = Provider<FileSaver>((ref) => createFileSaver());
