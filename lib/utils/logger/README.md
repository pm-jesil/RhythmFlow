# AppLogger - Rhythm Flow Logging System

## Overview
The AppLogger provides a clean, simple logging system for the Rhythm Flow app with context-aware logging and essential logging methods.

## Features
- ✅ **Context-aware logging** with component identification
- ✅ **Configurable log levels** (trace, debug, info, warning, error, fatal)
- ✅ **API request/response logging**
- ✅ **Simple and clean interface**

## Quick Start

### 1. Create Logger Instance
```dart
import 'utils/logger/logger.dart';

class MyWidget extends StatefulWidget {
  final AppLogger _logger = AppLogger('MyWidget');
  
  // ... rest of your widget
}
```

### 2. Use Logging Methods
```dart
final logger = AppLogger('MyComponent');

// Basic logging
logger.t('Trace information');
logger.d('Debug information');
logger.i('General information');
logger.w('Warning message');
logger.e('Error occurred', error: exception);
logger.f('Critical error', error: exception);

// API logging
logger.apiRequest('/api/songs', params: {'page': 1});
logger.apiResponse('/api/songs', statusCode: 200);
```

## Log Levels

### Basic Logging Methods
```dart
final logger = AppLogger('MyComponent');

// Trace logs - 🔍 (detailed debugging)
logger.t('Detailed trace information');

// Debug logs - 🐛 (development debugging)
logger.d('Debug information');

// Info logs - ℹ️ (general information)
logger.i('General information');

// Warning logs - ⚠️ (potential issues)
logger.w('Warning message');

// Error logs - ❌ (actual errors)
logger.e('Error occurred', error: exception);

// Fatal logs - 💥 (critical errors)
logger.f('Critical error', error: exception);
```

### API Logging
```dart
logger.apiRequest('/api/songs', params: {'page': 1});
logger.apiResponse('/api/songs', statusCode: 200);
```

## Configuration

### Enable/Disable Log Levels
```dart
// Enable specific log levels
AppLogger.enableTraceLogs(false);   // Disabled by default for performance
AppLogger.enableDebugLogs(true);
AppLogger.enableInfoLogs(true);
AppLogger.enableWarningLogs(true);
AppLogger.enableErrorLogs(true);
AppLogger.enableFatalLogs(true);
```

## Usage Examples by Component

### Main App
```dart
final logger = AppLogger('Main');
logger.i('🎵 Rhythm Flow starting...');
```

### Navigation
```dart
final logger = AppLogger('Navigation');
logger.d('Navigate to play song: song123');
```

### Music Player
```dart
final logger = AppLogger('MusicPlayer');
logger.d('Play button pressed');
logger.d('Seek to position: 30 seconds');
```

### Cache Operations
```dart
final logger = AppLogger('Cache');
logger.d('Add song to cache: Song Name');
logger.d('Cache size calculated: 1024 bytes');
```

### Error Handling
```dart
final logger = AppLogger('ErrorHandler');
try {
  // Some operation
} catch (e, stackTrace) {
  logger.e('Operation failed', error: e, stackTrace: stackTrace);
}
```

## Best Practices

### 1. Use Descriptive Context Names
```dart
// Good
final logger = AppLogger('MusicPlayerService');
final logger = AppLogger('SongListScreen');
final logger = AppLogger('CacheManager');

// Avoid
final logger = AppLogger('Widget');
final logger = AppLogger('Service');
```

### 2. Use Appropriate Log Levels
```dart
// Use trace for detailed debugging
logger.t('Function called with params: $params');

// Use debug for development information
logger.d('Component initialized');

// Use info for general information
logger.i('User logged in successfully');

// Use warning for potential issues
logger.w('Network request taking longer than expected');

// Use error for actual errors
logger.e('Failed to load data', error: exception);
```

### 3. Include Relevant Data
```dart
// Good - includes relevant context
logger.d('Song played: ${song.title} (ID: ${song.id})');

// Avoid - too generic
logger.d('Button pressed');
```

## Integration with Existing Code

### Replace Standard Logger
```dart
// Before
import 'package:logger/logger.dart';
final logger = Logger();
logger.d('Message');

// After
import 'utils/logger/logger.dart';
final logger = AppLogger('ComponentName');
logger.d('Message');
```

### Add to New Components
```dart
class MyNewService {
  final AppLogger _logger = AppLogger('MyNewService');
  
  Future<void> doSomething() async {
    _logger.i('Starting operation');
    try {
      // ... operation
      _logger.i('Operation completed successfully');
    } catch (e) {
      _logger.e('Operation failed', error: e);
    }
  }
}
```

## Performance Considerations

- **Trace logs are disabled by default** for performance
- **Use appropriate log levels** to avoid performance impact
- **Include relevant data** but avoid logging large objects

## Troubleshooting

### Logs Not Appearing
1. Check if the log level is enabled
2. Verify the logger context is correct

### Performance Issues
1. Disable trace logs in production
2. Use appropriate log levels
3. Avoid logging in tight loops

## Migration Guide

### From Standard Logger
1. Replace `import 'package:logger/logger.dart'` with `import 'utils/logger/logger.dart'`
2. Replace `Logger()` with `AppLogger('ComponentName')`
3. Update logging calls to use appropriate methods
4. Add context-specific logging for better debugging
