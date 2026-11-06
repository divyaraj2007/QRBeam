import 'package:flutter/material.dart';

import 'app.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();
  await HistoryService.instance.init();
  runApp(const QrBeamApp());
}
