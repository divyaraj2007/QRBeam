import 'dart:convert';
import 'dart:typed_data';

/// Metadata describing a file being transmitted over QRBeam.
class FileMetadata {
  const FileMetadata({
    required this.name,
    required this.sizeBytes,
    required this.sha256,
    required this.totalChunks,
    required this.chunkSize,
    this.extension,
  });

  final String name;
  final int sizeBytes;
  final String sha256;
  final int totalChunks;
  final int chunkSize;
  final String? extension;

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': sizeBytes,
        'sha256': sha256,
        'chunks': totalChunks,
        'chunkSize': chunkSize,
        if (extension != null) 'ext': extension,
      };

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      name: json['name'] as String,
      sizeBytes: json['size'] as int,
      sha256: json['sha256'] as String,
      totalChunks: json['chunks'] as int,
      chunkSize: json['chunkSize'] as int,
      extension: json['ext'] as String?,
    );
  }

  Uint8List toPayload() {
    final jsonStr = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  factory FileMetadata.fromPayload(Uint8List payload) {
    final jsonStr = utf8.decode(payload);
    final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
    return FileMetadata.fromJson(jsonMap);
  }
}
