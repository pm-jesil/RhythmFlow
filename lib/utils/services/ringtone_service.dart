import 'package:flutter/services.dart';
import 'dart:io';
import '../logger/logger.dart';

/// Service for managing ringtone operations using native Android APIs
class RingtoneService {
  static final AppLogger _logger = AppLogger('RingtoneService');
  static const MethodChannel _channel = MethodChannel('com.pmj.musicplayer/ringtone');

  /// Check if WRITE_SETTINGS permission is granted
  static Future<bool> hasWriteSettingsPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('hasWriteSettingsPermission');
      _logger.d('WRITE_SETTINGS permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      _logger.e('Error checking WRITE_SETTINGS permission: $e');
      return false;
    }
  }

  /// Request WRITE_SETTINGS permission (opens Android settings)
  static Future<bool> requestWriteSettingsPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      _logger.i('Requesting WRITE_SETTINGS permission...');
      await _channel.invokeMethod('requestWriteSettingsPermission');
      
      // Wait a bit for user to grant permission and return
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if permission was granted
      return await hasWriteSettingsPermission();
    } catch (e) {
      _logger.e('Error requesting WRITE_SETTINGS permission: $e');
      return false;
    }
  }

  /// Set a song as ringtone
  static Future<bool> setAsRingtone({
    required String filePath,
    required String songTitle,
  }) async {
    if (!Platform.isAndroid) {
      _logger.w('Ringtone setting is only supported on Android');
      return false;
    }
    
    try {
      _logger.i('Setting ringtone: $songTitle at path: $filePath');
      
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.e('File does not exist: $filePath');
        return false;
      }
      
      // Check permission first
      final hasPermission = await hasWriteSettingsPermission();
      if (!hasPermission) {
        _logger.w('WRITE_SETTINGS permission not granted');
        return false;
      }
      
      // Call native method to set ringtone
      final bool success = await _channel.invokeMethod('setRingtone', {
        'filePath': filePath,
        'title': songTitle,
      });
      
      if (success) {
        _logger.i('Successfully set ringtone: $songTitle');
      } else {
        _logger.e('Failed to set ringtone: $songTitle');
      }
      
      return success;
    } catch (e) {
      _logger.e('Error setting ringtone: $e');
      return false;
    }
  }

  /// Set a song as notification sound
  static Future<bool> setAsNotification({
    required String filePath,
    required String songTitle,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      _logger.i('Setting notification sound: $songTitle');
      
      final hasPermission = await hasWriteSettingsPermission();
      if (!hasPermission) return false;
      
      final bool success = await _channel.invokeMethod('setNotification', {
        'filePath': filePath,
        'title': songTitle,
      });
      
      return success;
    } catch (e) {
      _logger.e('Error setting notification sound: $e');
      return false;
    }
  }

  /// Set a song as alarm sound
  static Future<bool> setAsAlarm({
    required String filePath,
    required String songTitle,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      _logger.i('Setting alarm sound: $songTitle');
      
      final hasPermission = await hasWriteSettingsPermission();
      if (!hasPermission) return false;
      
      final bool success = await _channel.invokeMethod('setAlarm', {
        'filePath': filePath,
        'title': songTitle,
      });
      
      return success;
    } catch (e) {
      _logger.e('Error setting alarm sound: $e');
      return false;
    }
  }

  /// Get current ringtone title
  static Future<String?> getCurrentRingtone() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final String? title = await _channel.invokeMethod('getCurrentRingtone');
      return title;
    } catch (e) {
      _logger.e('Error getting current ringtone: $e');
      return null;
    }
  }
}
