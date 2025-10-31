import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../logger/logger.dart';

@singleton
class RemoteControlService {
  static final AppLogger _logger = AppLogger('RemoteControlService');
  
  // Stream controllers for remote control events
  final StreamController<RemoteControlAction> _actionController = 
      StreamController<RemoteControlAction>.broadcast();
  
  // Callback for handling actions
  Function(RemoteControlAction)? onActionReceived;
  
  // Stream for listening to remote control actions
  Stream<RemoteControlAction> get actionStream => _actionController.stream;
  
  RemoteControlService() {
    _initializeRemoteControls();
  }
  
  /// Initialize remote control listeners
  void _initializeRemoteControls() {
    _logger.i('🎧 Initializing remote control service...');
    
    // Set up method channel for handling remote control events
    const MethodChannel('com.technexa.rhythmflow/remote_control')
        .setMethodCallHandler(_handleMethodCall);
    
    _logger.i('✅ Remote control service initialized');
  }
  
  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    _logger.i('📱 Remote control method call: ${call.method}');
    
    switch (call.method) {
      case 'onPlay':
        _handleAction(RemoteControlAction.play);
        break;
      case 'onPause':
        _handleAction(RemoteControlAction.pause);
        break;
      case 'onStop':
        _handleAction(RemoteControlAction.stop);
        break;
      case 'onNext':
        _handleAction(RemoteControlAction.next);
        break;
      case 'onPrevious':
        _handleAction(RemoteControlAction.previous);
        break;
      case 'onSeekForward':
        _handleAction(RemoteControlAction.seekForward);
        break;
      case 'onSeekBackward':
        _handleAction(RemoteControlAction.seekBackward);
        break;
      case 'onTogglePlayPause':
        _handleAction(RemoteControlAction.togglePlayPause);
        break;
      default:
        _logger.w('⚠️ Unknown remote control action: ${call.method}');
    }
  }
  
  /// Handle remote control action
  void _handleAction(RemoteControlAction action) {
    _logger.i('🎧 Remote control action: $action');
    
    // Add to stream
    _actionController.add(action);
    
    // Call callback if set
    onActionReceived?.call(action);
  }

  /// Public method for testing remote control actions
  void simulateAction(RemoteControlAction action) {
    _handleAction(action);
  }
  
  /// Set callback for handling remote control actions
  void setActionCallback(Function(RemoteControlAction) callback) {
    onActionReceived = callback;
    _logger.i('✅ Remote control action callback set');
  }
  
  /// Handle headphone button press
  void handleHeadphoneButtonPress() {
    _logger.i('🎧 Headphone button pressed');
    _handleAction(RemoteControlAction.togglePlayPause);
  }
  
  /// Handle double headphone button press
  void handleHeadphoneDoublePress() {
    _logger.i('🎧 Headphone double press - next song');
    _handleAction(RemoteControlAction.next);
  }
  
  /// Handle triple headphone button press
  void handleHeadphoneTriplePress() {
    _logger.i('🎧 Headphone triple press - previous song');
    _handleAction(RemoteControlAction.previous);
  }
  
  /// Handle long headphone button press
  void handleHeadphoneLongPress() {
    _logger.i('🎧 Headphone long press - stop');
    _handleAction(RemoteControlAction.stop);
  }
  
  /// Handle smart watch controls
  void handleSmartWatchAction(String action) {
    _logger.i('⌚ Smart watch action: $action');
    
    switch (action.toLowerCase()) {
      case 'play':
        _handleAction(RemoteControlAction.play);
        break;
      case 'pause':
        _handleAction(RemoteControlAction.pause);
        break;
      case 'next':
        _handleAction(RemoteControlAction.next);
        break;
      case 'previous':
        _handleAction(RemoteControlAction.previous);
        break;
      case 'toggle':
        _handleAction(RemoteControlAction.togglePlayPause);
        break;
      default:
        _logger.w('⚠️ Unknown smart watch action: $action');
    }
  }
  
  /// Handle Bluetooth device controls
  void handleBluetoothAction(String action) {
    _logger.i('🔵 Bluetooth action: $action');
    
    switch (action.toLowerCase()) {
      case 'play':
        _handleAction(RemoteControlAction.play);
        break;
      case 'pause':
        _handleAction(RemoteControlAction.pause);
        break;
      case 'next':
        _handleAction(RemoteControlAction.next);
        break;
      case 'previous':
        _handleAction(RemoteControlAction.previous);
        break;
      case 'stop':
        _handleAction(RemoteControlAction.stop);
        break;
      case 'toggle':
        _handleAction(RemoteControlAction.togglePlayPause);
        break;
      default:
        _logger.w('⚠️ Unknown Bluetooth action: $action');
    }
  }
  
  /// Handle Android Auto / CarPlay controls
  void handleCarPlayAction(String action) {
    _logger.i('🚗 CarPlay/Android Auto action: $action');
    
    switch (action.toLowerCase()) {
      case 'play':
        _handleAction(RemoteControlAction.play);
        break;
      case 'pause':
        _handleAction(RemoteControlAction.pause);
        break;
      case 'next':
        _handleAction(RemoteControlAction.next);
        break;
      case 'previous':
        _handleAction(RemoteControlAction.previous);
        break;
      case 'stop':
        _handleAction(RemoteControlAction.stop);
        break;
      case 'toggle':
        _handleAction(RemoteControlAction.togglePlayPause);
        break;
      default:
        _logger.w('⚠️ Unknown CarPlay action: $action');
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _logger.i('🎧 Disposing remote control service...');
    
    await _actionController.close();
    
    _logger.i('✅ Remote control service disposed');
  }
}

/// Remote control actions enum
enum RemoteControlAction {
  play,
  pause,
  stop,
  next,
  previous,
  seekForward,
  seekBackward,
  togglePlayPause,
}

/// Extension to get action description
extension RemoteControlActionExtension on RemoteControlAction {
  String get description {
    switch (this) {
      case RemoteControlAction.play:
        return 'Play';
      case RemoteControlAction.pause:
        return 'Pause';
      case RemoteControlAction.stop:
        return 'Stop';
      case RemoteControlAction.next:
        return 'Next Song';
      case RemoteControlAction.previous:
        return 'Previous Song';
      case RemoteControlAction.seekForward:
        return 'Seek Forward';
      case RemoteControlAction.seekBackward:
        return 'Seek Backward';
      case RemoteControlAction.togglePlayPause:
        return 'Toggle Play/Pause';
    }
  }
}
