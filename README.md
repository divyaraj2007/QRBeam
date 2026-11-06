# QRBeam

Offline file transfer between two phones using live, continuously changing QR codes.
The sender shows a live QR stream; the receiver's camera scans it and rebuilds the file.
Optical mode uses no Wi-Fi, Bluetooth, mobile data, internet, or cloud services.

## Status

| Phase | Scope                                    | Status      |
|-------|------------------------------------------|-------------|
| 1     | Project setup, UI, navigation, file pick | Done        |
| 2     | Packet builder, QR generation, animation | Done        |
| 3     | Camera scanning, packet decoding         | Done        |
| 4     | Reassembly, CRC32, SHA-256 verification  | Done        |
| 5     | Transfer history, settings persistence   | Done        |
| 6     | Android & iOS native configurations      | Done        |

## Project Structure

```
lib/
  main.dart                    Entry point, initializes services
  app.dart                     MaterialApp with live theme mode binding
  config/
    app_config.dart            Default transfer settings
  core/
    crc32/crc32.dart           Standard IEEE 802.3 CRC-32 checksum calculation
    protocol/
      metadata.dart            File metadata serialization and validation
      packet.dart              Packet wire protocol (encode, decode, verification)
    utils/
      format.dart              Format helpers for bytes, duration, and speed
  services/
    chunker_service.dart       Slices files into metadata + numbered data packets
    reassembly_service.dart    Collects frames, verifies CRC32 & SHA-256 integrity
    file_picker_service.dart   System file selection
    storage_service.dart       Saves received files to device storage
    settings_service.dart      Persisted user preferences (speed, packet size, dark mode)
    history_service.dart       Persisted sent/received transfer history
  theme/
    app_theme.dart             Material 3 dark/light themes
  widgets/                     Shared UI components (AppCard, GradientBackground)
  screens/
    home_screen.dart           Main navigation hub
    send_screen.dart           Animated QR broadcaster with playback & speed controls
    receive_screen.dart        Camera scanner with live progress, stats, and viewfinder
    complete_screen.dart       Transfer summary with SHA-256 badge & direct file opener
    history_screen.dart        Log of past transfers with quick open
    settings_screen.dart       Frame duration, packet size, ECC, and appearance options
android/                       Complete Android project with camera & storage permissions
ios/                           iOS project configuration with NSCameraUsageDescription
test/
  widget_test.dart             Unit and integration tests for CRC32, packets, and reassembly
```

## How It Works

1. **Sender (`SendScreen`)**:
   - The user selects any file using the system file picker.
   - `ChunkerService` reads the file bytes, computes its SHA-256 checksum, and divides the payload into numbered chunks according to the configured packet size (default: 512 bytes).
   - Packet 0 carries the `FileMetadata` (file name, size, total chunks, SHA-256).
   - Packets 1..N carry the sequential binary payloads, each protected with an IEEE 802.3 CRC-32 checksum.
   - The screen animates the stream of QR codes in an infinite loop (Pass 1, Pass 2...) so that the receiver can begin scanning at any point and reliably capture any missed frames.

2. **Receiver (`ReceiveScreen`)**:
   - `MobileScanner` activates the camera preview with viewfinder reticle, flashlight control, and camera flip.
   - Scanned QR frames are parsed by `QrPacket.decode()`. Corrupted frames are instantly detected and rejected by their CRC-32 checksum.
   - `ReassemblyService` ingests chunks out-of-order, deduplicating frames and updating transfer statistics in real time.
   - Once all chunks arrive, the file is reassembled and verified against the target SHA-256 hash.
   - On verification, `StorageService` writes the file to device storage and `CompleteScreen` opens with an "Open File" action.

## Dependencies

- `qr_flutter`: High-density QR code rendering
- `mobile_scanner`: High-speed camera QR code scanner
- `file_picker`: Native system file picker
- `crypto`: SHA-256 integrity verification
- `path_provider`: Device storage directory resolution
- `shared_preferences`: Persistence for settings and transfer history
- `open_filex`: Direct file viewing from transfer screens
- `path`: File path manipulation utilities

## Running the App

1. Ensure Flutter 3.22+ is installed.
2. Inside `qrbeam/`:
   ```bash
   flutter pub get
   flutter test
   flutter run
   ```
