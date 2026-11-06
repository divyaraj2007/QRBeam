import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';

/// Result of a finished transfer. Only shown after SHA-256 verification passes.
class TransferSummary {
  const TransferSummary({
    required this.fileName,
    required this.fileSizeBytes,
    required this.duration,
    required this.averageBytesPerSecond,
    required this.packetLossPercent,
    required this.sha256Verified,
    this.localPath,
  });

  final String fileName;
  final int fileSizeBytes;
  final Duration duration;
  final double averageBytesPerSecond;
  final double packetLossPercent;
  final bool sha256Verified;
  final String? localPath;
}

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key, required this.summary});

  final TransferSummary summary;

  Future<void> _openFile(BuildContext context) async {
    final path = summary.localPath;
    if (path == null) return;

    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Complete'),
        automaticallyImplyLeading: false,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.fileName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _row('File size', formatBytes(s.fileSizeBytes)),
              _row('Duration', '${s.duration.inSeconds} s'),
              _row('Average speed',
                  '${formatBytes(s.averageBytesPerSecond.round())}/s'),
              _row('Duplicates / overhead',
                  '${s.packetLossPercent.toStringAsFixed(1)} %'),
              _row('SHA-256', s.sha256Verified ? 'Verified ✓' : 'Failed ✗'),
              if (s.localPath != null) _row('Saved to', s.localPath!),
              const SizedBox(height: 24),
              if (s.localPath != null) ...[
                FilledButton.icon(
                  onPressed: () => _openFile(context),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Open File'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
