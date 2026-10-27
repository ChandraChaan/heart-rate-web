import 'file_saver.dart';

FileSaver createFileSaver() => const _UnsupportedFileSaver();

final class _UnsupportedFileSaver implements FileSaver {
  const _UnsupportedFileSaver();

  @override
  Future<void> save({
    required String fileName,
    required String mimeType,
    required String contents,
  }) => throw UnsupportedError('Saving files needs a browser');
}
