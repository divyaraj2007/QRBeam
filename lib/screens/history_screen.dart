import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/utils/format.dart';
import '../services/history_service.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService.instance;

  @override
  void initState() {
    super.initState();
    _historyService.addListener(_onHistoryChange);
  }

  @override
  void dispose() {
    _historyService.removeListener(_onHistoryChange);
    super.dispose();
  }

  void _onHistoryChange() {
    if (mounted) setState(() {});
  }

  Future<void> _openFile(String? path) async {
    if (path == null) return;
    try {
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${res.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all transfer logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = _historyService.records;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          if (records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear History',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: records.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          const Text('No transfers yet',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Files you send or receive will appear here.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return AppCard(
                      onTap: record.localPath != null
                          ? () => _openFile(record.localPath)
                          : null,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: record.isSent
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            child: Icon(
                              record.isSent
                                  ? Icons.upload_rounded
                                  : Icons.download_rounded,
                              color:
                                  record.isSent ? Colors.blue : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.fileName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatBytes(record.fileSizeBytes)} • ${record.direction.toUpperCase()} • ${formatSpeed(record.averageBytesPerSecond)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (record.localPath != null)
                            Icon(Icons.open_in_new_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
