import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Manages and persists app configuration and user preferences.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyFrameMs = 'settings_frame_duration_ms';
  static const _keyPacketBytes = 'settings_packet_size_bytes';
  static const _keyEcc = 'settings_ecc_level';
  static const _keyCamera = 'settings_camera_resolution';
  static const _keyEncrypt = 'settings_encryption_enabled';
  static const _keyDarkMode = 'settings_dark_mode';

  int _frameDurationMs = AppConfig.defaultFrameDurationMs;
  int _packetSizeBytes = AppConfig.defaultPacketSizeBytes;
  String _eccLevel = AppConfig.defaultEccLevel;
  String _cameraResolution = AppConfig.defaultCameraResolution;
  bool _encryptionEnabled = AppConfig.defaultEncryptionEnabled;
  bool _isDarkMode = true;

  int get frameDurationMs => _frameDurationMs;
  int get packetSizeBytes => _packetSizeBytes;
  String get eccLevel => _eccLevel;
  String get cameraResolution => _cameraResolution;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _frameDurationMs = prefs.getInt(_keyFrameMs) ?? AppConfig.defaultFrameDurationMs;
    _packetSizeBytes = prefs.getInt(_keyPacketBytes) ?? AppConfig.defaultPacketSizeBytes;
    _eccLevel = prefs.getString(_keyEcc) ?? AppConfig.defaultEccLevel;
    _cameraResolution = prefs.getString(_keyCamera) ?? AppConfig.defaultCameraResolution;
    _encryptionEnabled = prefs.getBool(_keyEncrypt) ?? AppConfig.defaultEncryptionEnabled;
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
    notifyListeners();
  }

  Future<void> setFrameDurationMs(int value) async {
    _frameDurationMs = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFrameMs, value);
  }

  Future<void> setPacketSizeBytes(int value) async {
    _packetSizeBytes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPacketBytes, value);
  }

  Future<void> setEccLevel(String value) async {
    _eccLevel = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEcc, value);
  }

  Future<void> setCameraResolution(String value) async {
    _cameraResolution = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCamera, value);
  }

  Future<void> setEncryptionEnabled(bool value) async {
    _encryptionEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEncrypt, value);
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> resetToDefaults() async {
    _frameDurationMs = AppConfig.defaultFrameDurationMs;
    _packetSizeBytes = AppConfig.defaultPacketSizeBytes;
    _eccLevel = AppConfig.defaultEccLevel;
    _cameraResolution = AppConfig.defaultCameraResolution;
    _encryptionEnabled = AppConfig.defaultEncryptionEnabled;
    _isDarkMode = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFrameMs);
    await prefs.remove(_keyPacketBytes);
    await prefs.remove(_keyEcc);
    await prefs.remove(_keyCamera);
    await prefs.remove(_keyEncrypt);
    await prefs.remove(_keyDarkMode);
  }
}
