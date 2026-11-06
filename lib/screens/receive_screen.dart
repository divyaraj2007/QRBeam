import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/protocol/packet.dart';
import '../core/utils/format.dart';
import '../services/history_service.dart';
import '../services/reassembly_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';
import 'complete_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    returnImage: false,
  );

  final _reassembly = ReassemblyService();
  final _storage = const StorageService();

  DateTime? _transferStartTime;
  bool _isSaving = false;
  bool _isTorchOn = false;
  int _duplicateFramesCount = 0;
  int _totalScansCount = 0;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isSaving || _reassembly.isComplete) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || !rawValue.startsWith('QRB1|')) continue;

      _totalScansCount++;
      final packet = QrPacket.decode(rawValue);
      if (packet == null) continue; // Checksum or parsing failure

      _transferStartTime ??= DateTime.now();

      final accepted = _reassembly.ingestPacket(packet);
      if (accepted) {
        setState(() {}); // Update progress UI
        if (_reassembly.isComplete) {
          _finalizeTransfer();
          break;
        }
      } else {
        _duplicateFramesCount++;
      }
    }
  }

  Future<void> _finalizeTransfer() async {
    setState(() => _isSaving = true);
    _scannerController.stop();

    try {
      final result = _reassembly.assemble();
      final duration = DateTime.now().difference(_transferStartTime ?? DateTime.now());
      final durationSec = duration.inSeconds > 0 ? duration.inSeconds : 1;
      final speed = result.bytes.length / durationSec;

      String? savedPath;
      if (result.verified) {
        savedPath = await _storage.saveFile(
          fileName: result.metadata.name,
          bytes: result.bytes,
        );
      }

      final summary = TransferSummary(
        fileName: result.metadata.name,
        fileSizeBytes: result.bytes.length,
        duration: duration,
        averageBytesPerSecond: speed,
        packetLossPercent: _totalScansCount > 0
            ? (_duplicateFramesCount / _totalScansCount) * 100
            : 0.0,
        sha256Verified: result.verified,
        localPath: savedPath,
      );

      // Record to history
      await HistoryService.instance.addRecord(
        TransferRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: result.metadata.name,
          fileSizeBytes: result.bytes.length,
          direction: 'received',
          timestamp: DateTime.now(),
          durationSeconds: durationSec,
          averageBytesPerSecond: speed,
          sha256Verified: result.verified,
          localPath: savedPath,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompleteScreen(summary: summary),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finalizing transfer: $e')),
      );
    }
  }

  void _resetTransfer() {
    setState(() {
      _reassembly.reset();
      _transferStartTime = null;
      _isSaving = false;
      _duplicateFramesCount = 0;
      _totalScansCount = 0;
    });
    _scannerController.start();
  }

  void _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _switchCamera() async {
    await _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _reassembly.metadata;
    final totalChunks = _reassembly.totalDataChunks;
    final receivedChunks = _reassembly.receivedDataChunksCount;
    final progress = _reassembly.progress;
    final missingCount = _reassembly.missingPacketIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive File'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            tooltip: 'Toggle Flashlight',
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch Camera',
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Scanner',
            onPressed: _resetTransfer,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Camera Preview with Scanner Viewfinder
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      // Viewfinder border box
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      if (_isSaving)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Verifying SHA-256 & Saving...',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Metadata Card (if discovered)
              if (metadata != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metadata.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${formatBytes(metadata.sizeBytes)} • Chunks: $totalChunks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '$receivedChunks of $totalChunks chunks',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Point camera at the sender\'s QR code stream to begin...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Detailed Transfer Stats
              _StatsRow(
                label: 'Received packets',
                value: metadata == null ? 'Waiting...' : '$receivedChunks / $totalChunks',
              ),
              _StatsRow(
                label: 'Missing packets',
                value: metadata == null
                    ? '—'
                    : missingCount == 0
                        ? 'None (Complete)'
                        : '$missingCount left',
              ),
              _StatsRow(
                label: 'Transfer Speed',
                value: _transferStartTime == null || metadata == null
                    ? '—'
                    : formatSpeed(
                        (receivedChunks * metadata.chunkSize) /
                            (DateTime.now().difference(_transferStartTime!).inSeconds > 0
                                ? DateTime.now().difference(_transferStartTime!).inSeconds
                                : 1),
                      ),
              ),
              _StatsRow(
                label: 'Integrity Check',
                value: metadata == null ? 'Pending' : 'SHA-256 + CRC-32 active',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
