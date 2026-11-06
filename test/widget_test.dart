import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qrbeam/app.dart';
import 'package:qrbeam/core/crc32/crc32.dart';
import 'package:qrbeam/core/protocol/metadata.dart';
import 'package:qrbeam/core/protocol/packet.dart';
import 'package:qrbeam/core/utils/format.dart';
import 'package:qrbeam/services/chunker_service.dart';
import 'package:qrbeam/services/reassembly_service.dart';

void main() {
  testWidgets('Home screen shows the app title and menu', (tester) async {
    await tester.pumpWidget(const QrBeamApp());

    expect(find.text('QRBeam'), findsOneWidget);
    expect(find.text('Send File'), findsOneWidget);
    expect(find.text('Receive File'), findsOneWidget);
  });

  group('Formatting utilities', () {
    test('formatBytes formats sizes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    });

    test('formatDuration formats duration correctly', () {
      expect(formatDuration(const Duration(seconds: 45)), '45s');
      expect(formatDuration(const Duration(seconds: 125)), '2m 5s');
    });

    test('formatSpeed formats bytes per second', () {
      expect(formatSpeed(0), '0 B/s');
      expect(formatSpeed(1024), '1.0 KB/s');
    });
  });

  group('CRC32 checksum', () {
    test('computes standard IEEE 802.3 test vectors', () {
      // Standard vector "123456789" => 0xCBF43926 = 3421760294
      final bytes = utf8.encode('123456789');
      final crc = Crc32.compute(bytes);
      expect(crc, 0xCBF43926);
    });
  });

  group('Packet encoding & decoding', () {
    test('round-trips a data packet correctly', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5, 42, 99]);
      final packet = QrPacket.create(
        sessionId: 'test1234',
        packetId: 5,
        totalPackets: 20,
        type: PacketType.data,
        payload: payload,
      );

      final encoded = packet.encode();
      expect(encoded.startsWith('QRB1|1|test1234|data|5|20|'), isTrue);

      final decoded = QrPacket.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.sessionId, 'test1234');
      expect(decoded.packetId, 5);
      expect(decoded.totalPackets, 20);
      expect(decoded.type, PacketType.data);
      expect(decoded.payload, equals(payload));
      expect(decoded.checksum, packet.checksum);
    });

    test('rejects corrupted packets', () {
      final payload = Uint8List.fromList([10, 20, 30, 40]);
      final packet = QrPacket.create(
        sessionId: 'sess01',
        packetId: 1,
        totalPackets: 2,
        type: PacketType.data,
        payload: payload,
      );

      final encoded = packet.encode();
      // Corrupt the base64 payload part
      final corrupted = encoded.substring(0, encoded.length - 2) + 'AA';

      final decoded = QrPacket.decode(corrupted);
      expect(decoded, isNull);
    });
  });

  group('End-to-end chunking and reassembly', () {
    test('chunks and successfully reconstructs file with SHA-256 verification', () {
      const chunker = ChunkerService();
      final reassembly = ReassemblyService();

      // Create synthetic test data (1.5 KB to force multiple chunks with 512B size)
      final originalData = Uint8List.fromList(
        List.generate(1536, (i) => (i * 7) % 256),
      );

      final chunkResult = chunker.chunkBytes(
        bytes: originalData,
        fileName: 'sample.dat',
        chunkSize: 512,
      );

      expect(chunkResult.packets.length, 4); // 1 metadata + 3 data chunks
      expect(chunkResult.metadata.name, 'sample.dat');
      expect(chunkResult.metadata.sizeBytes, 1536);

      // Ingest packets in random order to test out-of-order reassembly
      final packetsToIngest = [
        chunkResult.packets[2], // Data chunk 2
        chunkResult.packets[0], // Metadata
        chunkResult.packets[3], // Data chunk 3
        chunkResult.packets[1], // Data chunk 1
      ];

      for (final packet in packetsToIngest) {
        final accepted = reassembly.ingestPacket(packet);
        expect(accepted, isTrue);
      }

      expect(reassembly.isComplete, isTrue);
      expect(reassembly.progress, 1.0);
      expect(reassembly.missingPacketIds, isEmpty);

      final assembled = reassembly.assemble();
      expect(assembled.verified, isTrue);
      expect(assembled.bytes, equals(originalData));
      expect(assembled.metadata.name, 'sample.dat');
    });
  });
}
