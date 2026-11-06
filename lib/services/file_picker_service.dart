import 'package:file_picker/file_picker.dart';

/// Metadata about a file chosen by the user.
class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String? extension;
}

class FilePickerService {
  const FilePickerService();

  /// Opens the system file picker. Returns null if the user cancels
  /// or the selected file has no local path.
  Future<PickedFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return null;

    return PickedFile(
      path: path,
      name: file.name,
      sizeBytes: file.size,
      extension: file.extension,
    );
  }
}
