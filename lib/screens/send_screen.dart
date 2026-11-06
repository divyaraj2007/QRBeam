import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/protocol/packet.dart';
import '../core/utils/format.dart';
import '../services/chunker_service.dart';
import '../services/file_picker_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _picker = const FilePickerService();
  final _chunker = const ChunkerService();

  PickedFile? _file;
  bool _isProcessing = false;
  bool _isStreaming = false;
  bool _isPaused = false;

  List<QrPacket> _packets = [];
  int _currentFrameIndex = 0;
  int _passCount = 1;
  Timer? _streamTimer;
  DateTime? _streamStartTime;

  int _frameDurationMs = SettingsService.instance.frameDurationMs;
  int _packetSizeBytes = SettingsService.instance.packetSizeBytes;
  String _ecc = SettingsService.instance.eccLevel;

  @override
  void initState() {
    super.initState();
    _frameDurationMs = SettingsService.instance.frameDurationMs;
    _packetSizeBytes = SettingsService.instance.packetSizeBytes;
    _ecc = SettingsService.instance.eccLevel;
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await _picker.pickFile();
    if (picked != null && mounted) {
      setState(() {
        _file = picked;
        _isStreaming = false;
        _packets.clear();
        _currentFrameIndex = 0;
        _passCount = 1;
      });
      _streamTimer?.cancel();
    }
  }

  Future<void> _prepareAndStartStream() async {
    final file = _file;
    if (file == null) return;

    setState(() => _isProcessing = true);

    try {
      final chunkResult = await _chunker.chunkFile(
        filePath: file.path,
        fileName: file.name,
        chunkSize: _packetSizeBytes,
      );

      if (!mounted) return;

      setState(() {
        _packets = chunkResult.packets;
        _currentFrameIndex = 0;
        _passCount = 1;
        _isProcessing = false;
        _isStreaming = true;
        _isPaused = false;
        _streamStartTime = DateTime.now();
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read and chunk file: $e')),
      );
    }
  }

  void _startTimer() {
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(Duration(milliseconds: _frameDurationMs), (timer) {
      if (_isPaused || _packets.isEmpty) return;

      setState(() {
        if (_currentFrameIndex + 1 >= _packets.length) {
          _currentFrameIndex = 0;
          _passCount++;
        } else {
          _currentFrameIndex++;
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stepFrame(int delta) {
    if (_packets.isEmpty) return;
    setState(() {
      _isPaused = true;
      final newIndex = _currentFrameIndex + delta;
      if (newIndex >= 0 && newIndex < _packets.length) {
        _currentFrameIndex = newIndex;
      }
    });
  }

  void _updateSpeed(double ms) {
    setState(() {
      _frameDurationMs = ms.round();
    });
    if (_isStreaming && !_isPaused) {
      _startTimer();
    }
  }

  Future<void> _stopStream() async {
    _streamTimer?.cancel();

    final file = _file;
    if (file != null && _streamStartTime != null) {
      final duration = DateTime.now().difference(_streamStartTime!);
      final durSec = duration.inSeconds > 0 ? duration.inSeconds : 1;
      final speed = file.sizeBytes / durSec;

      await HistoryService.instance.addRecord(
        TransferRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: file.name,
          fileSizeBytes: file.sizeBytes,
          direction: 'sent',
          timestamp: DateTime.now(),
          durationSeconds: durSec,
          averageBytesPerSecond: speed,
          sha256Verified: true,
          localPath: file.path,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isStreaming = false;
        _isPaused = false;
      });
    }
  }

  int _getQrEccLevel(String ecc) {
    switch (ecc.toUpperCase()) {
      case 'L':
        return QrErrorCorrectLevel.L;
      case 'Q':
        return QrErrorCorrectLevel.Q;
      case 'H':
        return QrErrorCorrectLevel.H;
      case 'M':
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = _file;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send File'),
        actions: [
          if (_isStreaming)
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded),
              tooltip: 'Stop Stream',
              onPressed: _stopStream,
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_isStreaming) ...[
                // File selection card
                AppCard(
                  onTap: _pickFile,
                  child: Column(
                    children: [
                      Icon(Icons.insert_drive_file_rounded,
                          size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        file == null ? 'Choose a file to send' : file.name,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file == null
                            ? 'Tap to select any file from your device'
                            : formatBytes(file.sizeBytes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (file != null) ...[
                  // Transmission details summary
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transmission Estimate',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 12),
                        _infoRow('Packet Size', '$_packetSizeBytes bytes'),
                        _infoRow(
                          'Estimated Packets',
                          '${((file.sizeBytes + _packetSizeBytes - 1) ~/ _packetSizeBytes) + 1}',
                        ),
                        _infoRow(
                          'Duration / Pass',
                          '${(((file.sizeBytes + _packetSizeBytes - 1) ~/ _packetSizeBytes) + 1) * _frameDurationMs / 1000.0} s',
                        ),
                        _infoRow('QR Error Correction', _ecc),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _prepareAndStartStream,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_2_rounded),
                    label: Text(_isProcessing
                        ? 'Preparing packets...'
                        : 'Start Live QR Stream'),
                  ),
                ],
              ] else ...[
                // Live Stream View
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _packets.isNotEmpty
                        ? QrImageView(
                            data: _packets[_currentFrameIndex].encode(),
                            version: QrVersions.auto,
                            size: 260.0,
                            errorCorrectionLevel: _getQrEccLevel(_ecc),
                            padding: const EdgeInsets.all(4),
                          )
                        : const SizedBox(
                            width: 260,
                            height: 260,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Packet Progress Bar & Stats
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _packets.isNotEmpty && _currentFrameIndex == 0
                                ? 'Packet 0 (Metadata)'
                                : 'Packet $_currentFrameIndex / ${_packets.length - 1}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pass $_passCount',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _packets.isNotEmpty
                            ? (_currentFrameIndex + 1) / _packets.length
                            : 0.0,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.skip_previous_rounded),
                            tooltip: 'Previous Frame',
                            onPressed: () => _stepFrame(-1),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            icon: Icon(_isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded),
                            tooltip: _isPaused ? 'Resume Stream' : 'Pause Stream',
                            onPressed: _togglePause,
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.skip_next_rounded),
                            tooltip: 'Next Frame',
                            onPressed: () => _stepFrame(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Speed Slider
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Frame duration: ${_frameDurationMs} ms',
                              style: theme.textTheme.bodyMedium),
                          Text(
                            '~${(1000 / _frameDurationMs).toStringAsFixed(1)} fps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 50,
                        max: 800,
                        divisions: 15,
                        value: _frameDurationMs.toDouble(),
                        onChanged: _updateSpeed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _stopStream,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Finish Transmission'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
