import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_background.dart';

/// Settings UI backed by [SettingsService] and persisted in SharedPreferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;

  late double _frameMs;
  late double _packetBytes;
  late String _ecc;
  late String _camera;
  late bool _encrypt;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _loadFromService();
  }

  void _loadFromService() {
    _frameMs = _settings.frameDurationMs.toDouble();
    _packetBytes = _settings.packetSizeBytes.toDouble();
    _ecc = _settings.eccLevel;
    _camera = _settings.cameraResolution;
    _encrypt = _settings.encryptionEnabled;
    _darkMode = _settings.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              await _settings.resetToDefaults();
              setState(_loadFromService);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR frame duration: ${_frameMs.round()} ms',
                        style: theme.textTheme.titleSmall),
                    Slider(
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      value: _frameMs,
                      onChanged: (v) {
                        setState(() => _frameMs = v);
                        _settings.setFrameDurationMs(v.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Packet size: ${_packetBytes.round()} bytes',
                        style: theme.textTheme.titleSmall),
                    Slider(
                      min: 128,
                      max: 2048,
                      divisions: 15,
                      value: _packetBytes,
                      onChanged: (v) {
                        setState(() => _packetBytes = v);
                        _settings.setPacketSizeBytes(v.round());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR error correction',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'L', label: Text('L')),
                        ButtonSegment(value: 'M', label: Text('M')),
                        ButtonSegment(value: 'Q', label: Text('Q')),
                        ButtonSegment(value: 'H', label: Text('H')),
                      ],
                      selected: {_ecc},
                      onSelectionChanged: (s) {
                        setState(() => _ecc = s.first);
                        _settings.setEccLevel(s.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Camera resolution',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'low', label: Text('Low')),
                        ButtonSegment(value: 'medium', label: Text('Medium')),
                        ButtonSegment(value: 'high', label: Text('High')),
                      ],
                      selected: {_camera},
                      onSelectionChanged: (s) {
                        setState(() => _camera = s.first);
                        _settings.setCameraResolution(s.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Encrypt payloads (AES-256-GCM)'),
                      value: _encrypt,
                      onChanged: (v) {
                        setState(() => _encrypt = v);
                        _settings.setEncryptionEnabled(v);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark mode'),
                      value: _darkMode,
                      onChanged: (v) {
                        setState(() => _darkMode = v);
                        _settings.setDarkMode(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
