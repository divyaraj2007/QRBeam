/// Utility functions for formatting values in the UI.

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = duration.inMinutes;
  final remainingSec = seconds % 60;
  return '${minutes}m ${remainingSec}s';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 B/s';
  return '${formatBytes(bytesPerSecond.round())}/s';
}
