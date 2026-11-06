import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for persisting transferred files to the device filesystem.
class StorageService {
  const StorageService();

  /// Saves [bytes] with [fileName] into the device's documents or downloads folder.
  ///
  /// Automatically resolves naming collisions by appending a counter.
  Future<String> saveFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    Directory? targetDir;
    try {
      targetDir = await getDownloadsDirectory();
    } catch (_) {}

    targetDir ??= await getApplicationDocumentsDirectory();

    final cleanName = p.basename(fileName);
    final ext = p.extension(cleanName);
    final baseWithoutExt = p.basenameWithoutExtension(cleanName);

    String candidatePath = p.join(targetDir.path, cleanName);
    int counter = 1;

    while (await File(candidatePath).exists()) {
      candidatePath = p.join(targetDir.path, '$baseWithoutExt ($counter)$ext');
      counter++;
    }

    final file = File(candidatePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
