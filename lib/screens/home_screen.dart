import 'package:flutter/material.dart';

import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';
import 'history_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'QRBeam',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline file transfer with live QR codes',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _MenuTile(
                  icon: Icons.upload_rounded,
                  title: 'Send File',
                  subtitle: 'Show a live QR stream to another phone',
                  onTap: () => _open(context, const SendScreen()),
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.download_rounded,
                  title: 'Receive File',
                  subtitle: 'Scan the sender\'s QR stream with the camera',
                  onTap: () => _open(context, const ReceiveScreen()),
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.history_rounded,
                  title: 'Transfer History',
                  subtitle: 'Previously completed transfers',
                  onTap: () => _open(context, const HistoryScreen()),
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.tune_rounded,
                  title: 'Settings',
                  subtitle: 'QR timing, packet size, encryption',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'No network. No cloud. Only light.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
