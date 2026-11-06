import 'dart:convert';
import 'dart:typed_data';

import '../crc32/crc32.dart';

/// Packet types of the QRBeam optical protocol.
enum PacketType { start, metadata, data, end, ack, error }

/// One frame of the optical protocol, as carried inside a QR code.
///
/// Wire format:
/// `QRB1|1|<sessionId>|<type>|<packetId>|<totalPackets>|<checksumHex>|<base64Payload>`
class QrPacket {
  const QrPacket({
    required this.sessionId,
    required this.packetId,
    required this.totalPackets,
    required this.type,
    required this.payload,
    required this.checksum,
  });

  /// Factory constructor that automatically computes the CRC32 checksum.
  factory QrPacket.create({
    required String sessionId,
    required int packetId,
    required int totalPackets,
    required PacketType type,
    required Uint8List payload,
  }) {
    final crc = Crc32.compute(payload);
    return QrPacket(
      sessionId: sessionId,
      packetId: packetId,
      totalPackets: totalPackets,
      type: type,
      payload: payload,
      checksum: crc,
    );
  }

  final String sessionId;
  final int packetId;
  final int totalPackets;
  final PacketType type;
  final Uint8List payload;

  /// CRC32 of the payload.
  final int checksum;

  /// Serializes this packet into a high-density, error-detectable QR string.
  String encode() {
    final b64Payload = base64Encode(payload);
    final crcHex = checksum.toRadixString(16).padLeft(8, '0');
    return 'QRB1|1|$sessionId|${type.name}|$packetId|$totalPackets|$crcHex|$b64Payload';
  }

  /// Deserializes a scanned QR string into a [QrPacket].
  ///
  /// Returns null if the format is invalid or if the CRC32 checksum fails.
  static QrPacket? decode(String raw) {
    if (!raw.startsWith('QRB1|')) return null;

    final parts = raw.split('|');
    if (parts.length != 8) return null;

    // parts[0] == 'QRB1'
    final version = parts[1];
    if (version != '1') return null;

    final sessionId = parts[2];
    final typeName = parts[3];
    final type = PacketType.values.where((t) => t.name == typeName).firstOrNull;
    if (type == null) return null;

    final packetId = int.tryParse(parts[4]);
    final totalPackets = int.tryParse(parts[5]);
    final expectedCrc = int.tryParse(parts[6], radix: 16);

    if (packetId == null || totalPackets == null || expectedCrc == null) {
      return null;
    }

    try {
      final payload = base64Decode(parts[7]);
      final actualCrc = Crc32.compute(payload);
      if (actualCrc != expectedCrc) {
        // Corrupted packet detected by CRC32
        return null;
      }

      return QrPacket(
        sessionId: sessionId,
        packetId: packetId,
        totalPackets: totalPackets,
        type: type,
        payload: payload,
        checksum: actualCrc,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'QrPacket(session: $sessionId, id: $packetId/$totalPackets, '
      'type: ${type.name}, bytes: ${payload.length}, crc: 0x${checksum.toRadixString(16)})';
}
