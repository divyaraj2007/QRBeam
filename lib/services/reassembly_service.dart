import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../core/protocol/metadata.dart';
import '../core/protocol/packet.dart';

/// Result of assembling all received chunks of a file.
class AssembledFileResult {
  const AssembledFileResult({
    required this.bytes,
    required this.metadata,
    required this.verified,
    this.errorMessage,
  });

  final Uint8List bytes;
  final FileMetadata metadata;
  final bool verified;
  final String? errorMessage;
}

/// Service that accumulates incoming packets from camera scans and reassembles
/// the complete file with cryptographic SHA-256 validation.
class ReassemblyService {
  String? _activeSessionId;
  FileMetadata? _metadata;
  final Map<int, Uint8List> _chunks = {};
  final Set<int> _receivedPackets = {};

  String? get activeSessionId => _activeSessionId;
  FileMetadata? get metadata => _metadata;
  bool get hasMetadata => _metadata != null;

  int get totalDataChunks => _metadata?.totalChunks ?? 0;
  int get receivedDataChunksCount => _chunks.length;

  /// Progress from 0.0 to 1.0.
  double get progress {
    if (_metadata == null || _metadata!.totalChunks == 0) return 0.0;
    return (_chunks.length / _metadata!.totalChunks).clamp(0.0, 1.0);
  }

  /// List of data packet IDs (1-based) that haven't been received yet.
  List<int> get missingPacketIds {
    if (_metadata == null) return const [];
    final missing = <int>[];
    for (int i = 1; i <= _metadata!.totalChunks; i++) {
      if (!_chunks.containsKey(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Whether all metadata and data packets have been received.
  bool get isComplete {
    if (_metadata == null) return false;
    return _chunks.length >= _metadata!.totalChunks;
  }

  /// Resets the receiver state for a new transfer.
  void reset() {
    _activeSessionId = null;
    _metadata = null;
    _chunks.clear();
    _receivedPackets.clear();
  }

  /// Ingests a scanned [packet]. Returns true if this packet was new and accepted.
  bool ingestPacket(QrPacket packet) {
    // If incoming packet belongs to a different session, reset if no active transfer or user confirms.
    if (_activeSessionId != null && _activeSessionId != packet.sessionId) {
      if (_chunks.isEmpty && _metadata == null) {
        _activeSessionId = packet.sessionId;
      } else {
        // Discard packet from conflicting session
        return false;
      }
    }

    _activeSessionId ??= packet.sessionId;

    if (_receivedPackets.contains(packet.packetId)) {
      return false; // Duplicate frame
    }

    _receivedPackets.add(packet.packetId);

    if (packet.type == PacketType.metadata && packet.packetId == 0) {
      try {
        _metadata = FileMetadata.fromPayload(packet.payload);
        return true;
      } catch (_) {
        return false;
      }
    }

    if (packet.type == PacketType.data && packet.packetId > 0) {
      _chunks[packet.packetId] = packet.payload;
      return true;
    }

    return false;
  }

  /// Assembles the complete file from chunks and verifies the SHA-256 hash.
  AssembledFileResult assemble() {
    if (!isComplete || _metadata == null) {
      throw StateError('Cannot assemble file before all packets are received.');
    }

    // Allocate continuous buffer
    final totalBytes = _metadata!.sizeBytes;
    final buffer = Uint8List(totalBytes);
    int offset = 0;

    for (int i = 1; i <= _metadata!.totalChunks; i++) {
      final chunk = _chunks[i] ?? Uint8List(0);
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // Verify SHA-256
    final computedSha = sha256.convert(buffer).toString();
    final verified = (computedSha.toLowerCase() == _metadata!.sha256.toLowerCase());

    return AssembledFileResult(
      bytes: buffer,
      metadata: _metadata!,
      verified: verified,
      errorMessage: verified ? null : 'SHA-256 integrity check failed. Data may be corrupt.',
    );
  }
}
