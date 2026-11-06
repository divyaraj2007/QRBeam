import 'dart:typed_data';

/// Standard IEEE 802.3 32-bit Cyclic Redundancy Check (CRC-32).
///
/// Uses the reversed polynomial 0xEDB88320 with a 256-entry lookup table.
class Crc32 {
  const Crc32._();

  static final Uint32List _table = _generateTable();

  static Uint32List _generateTable() {
    final table = Uint32List(256);
    for (int i = 0; i < 256; i++) {
      int c = i;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[i] = c;
    }
    return table;
  }

  /// Computes the CRC-32 checksum of [bytes].
  static int compute(List<int> bytes) {
    int crc = 0xFFFFFFFF;
    for (int i = 0; i < bytes.length; i++) {
      final index = (crc ^ bytes[i]) & 0xFF;
      crc = (crc >>> 8) ^ _table[index];
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
