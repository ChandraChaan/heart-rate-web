import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_saver.dart';

FileSaver createFileSaver() => const _BrowserFileSaver();

/// Downloads the file through a temporary object URL. Nothing is uploaded.
final class _BrowserFileSaver implements FileSaver {
  const _BrowserFileSaver();

  @override
  Future<void> save({
    required String fileName,
    required String mimeType,
    required String contents,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
