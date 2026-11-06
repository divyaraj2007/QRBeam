/// Default transfer and UI settings. Values here are only defaults;
/// persistence and live editing are added in a later phase.
class AppConfig {
  const AppConfig._();

  /// How long each QR frame stays on screen.
  static const int defaultFrameDurationMs = 200;

  /// Payload bytes carried by one DATA packet (before encoding overhead).
  static const int defaultPacketSizeBytes = 512;

  /// QR error correction level: L, M, Q or H.
  static const String defaultEccLevel = 'M';

  /// Camera resolution preset: low, medium or high.
  static const String defaultCameraResolution = 'medium';

  /// Whether AES-256-GCM encryption is applied to payloads.
  static const bool defaultEncryptionEnabled = true;
}
