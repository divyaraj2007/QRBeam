import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../core/protocol/metadata.dart';
import '../core/protocol/packet.dart';

/// Result of chunking a file into a sequence of [QrPacket]s.
class ChunkResult {
  const ChunkResult({
    required this.metadata,
    required this.packets,
    required this.sessionId,
  });

  final FileMetadata metadata;
  final List<QrPacket> packets;
  final String sessionId;

  int get totalPackets => packets.length;
}

/// Service that slices files into standard QRBeam packets ready for optical broadcast.
class ChunkerService {
  const ChunkerService();

  /// Slices the file at [filePath] into a sequence of [QrPacket]s.
  Future<ChunkResult> chunkFile({
    required String filePath,
    required String fileName,
    int chunkSize = 512,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return chunkBytes(
      bytes: bytes,
      fileName: fileName,
      chunkSize: chunkSize,
    );
  }

  /// Slices [bytes] into a sequence of [QrPacket]s.
  ChunkResult chunkBytes({
    required Uint8List bytes,
    required String fileName,
    int chunkSize = 512,
  }) {
    final sha256Digest = sha256.convert(bytes).toString();
    final totalDataChunks = (bytes.isEmpty) ? 1 : (bytes.length + chunkSize - 1) ~/ chunkSize;
    final totalPackets = totalDataChunks + 1; // 1 metadata packet + N data packets

    final random = Random();
    final sessionId = (random.nextInt(0xFFFFFF) + 0x100000).toRadixString(16);

    final ext = fileName.contains('.') ? fileName.split('.').last : null;

    final metadata = FileMetadata(
      name: fileName,
      sizeBytes: bytes.length,
      sha256: sha256Digest,
      totalChunks: totalDataChunks,
      chunkSize: chunkSize,
      extension: ext,
    );

    final packets = <QrPacket>[];

    // Packet 0: Metadata packet
    packets.add(
      QrPacket.create(
        sessionId: sessionId,
        packetId: 0,
        totalPackets: totalPackets,
        type: PacketType.metadata,
        payload: metadata.toPayload(),
      ),
    );

    // Packets 1..N: Data packets
    if (bytes.isEmpty) {
      packets.add(
        QrPacket.create(
          sessionId: sessionId,
          packetId: 1,
          totalPackets: totalPackets,
          type: PacketType.data,
          payload: Uint8List(0),
        ),
      );
    } else {
      for (int i = 0; i < totalDataChunks; i++) {
        final start = i * chunkSize;
        final end = min(start + chunkSize, bytes.length);
        final chunk = bytes.sublist(start, end);

        packets.add(
          QrPacket.create(
            sessionId: sessionId,
            packetId: i + 1,
            totalPackets: totalPackets,
            type: PacketType.data,
            payload: chunk,
          ),
        );
      }
    }

    return ChunkResult(
      metadata: metadata,
      packets: packets,
      sessionId: sessionId,
    );
  }
}
