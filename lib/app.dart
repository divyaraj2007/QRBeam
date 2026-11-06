import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

class QrBeamApp extends StatelessWidget {
  const QrBeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'QRBeam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: SettingsService.instance.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
