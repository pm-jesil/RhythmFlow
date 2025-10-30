# 🎵 Rhythm Flow

A modern, feature-rich Flutter music player application with AI-powered music analysis, intelligent playlist management, and comprehensive local music library support.

## 📱 Overview

Rhythm Flow is a sophisticated music player built with Flutter that offers advanced features like AI-powered music analysis, intelligent shuffle, comprehensive metadata extraction, and a beautiful modern UI. The app supports local music files and provides a personalized music experience.

## ✨ Key Features

### 🎯 Core Music Features
- **Local Music Library Management**: Scan and organize your local music files
- **Advanced Audio Playback**: High-quality audio playback with just_audio
- **Background Playback**: Continue playing music when the app is in the background
- **Lock Screen Controls**: Full media controls on lock screen and notification panel
- **Queue Management**: Play, pause, next, previous, and queue management
- **Seek Controls**: Precise seeking through tracks
- **Volume Control**: Adjustable volume with system integration

### 🤖 AI-Powered Features
- **Music Feature Analysis**: Comprehensive analysis of musical characteristics
- **AI Shuffle**: Intelligent playlist reordering based on musical similarity
- **Mood-Based Playlists**: Create playlists based on emotional characteristics
- **Genre Classification**: Automatic genre detection using YAMNet
- **Instrument Detection**: Identify instruments in songs
- **Energy Analysis**: Analyze energy levels and danceability
- **Tempo Detection**: Automatic BPM detection and classification

### 📊 Smart Analytics
- **Play Count Tracking**: Track how often songs are played
- **Listening Statistics**: Detailed analytics on your music consumption
- **Top Artists & Albums**: Automatically generated based on play counts
- **Recently Added**: Smart categorization of new music
- **For You Recommendations**: Personalized music suggestions

### 🎨 User Interface
- **Modern Material Design**: Beautiful, responsive UI with smooth animations
- **Dark/Light Theme**: Automatic theme switching with system preference
- **Glass Morphism**: Modern glassmorphism effects throughout the app
- **Custom Animations**: Smooth transitions and micro-interactions
- **Responsive Design**: Optimized for different screen sizes
- **Accessibility**: Full accessibility support

### 🎵 Music Organization
- **Smart Sorting**: Multiple sorting options (alphabetical, duration, play count, etc.)
- **Advanced Filtering**: Search and filter by artist, album, genre, year
- **Playlist Management**: Create, edit, and manage custom playlists
- **Album & Artist Views**: Dedicated views for albums and artists
- **Metadata Management**: Comprehensive metadata extraction and editing

### 🔧 Advanced Features
- **Comprehensive Metadata Extraction**: Support for ID3v1, ID3v2, APE, Vorbis, iTunes/MP4, FLAC
- **Album Art Handling**: Automatic album art extraction and management
- **File Format Support**: MP3, M4A, AAC, WAV, FLAC, OGG, WMA, OPUS, AIFF, ALAC, and more
- **Permission Management**: Smart permission handling for file access
- **Background Processing**: Feature extraction runs in the background
- **Data Persistence**: All data is persisted locally using Hive

## 🏗️ Architecture

### State Management
- **BLoC Pattern**: Clean architecture with BLoC for state management
- **Hydrated BLoC**: Persistent state across app restarts
- **Dependency Injection**: GetIt for service locator pattern
- **Event-Driven**: Reactive programming with events and states

### Core Services
- **AudioService**: Handles all audio playback functionality
- **MusicService**: Manages music library and metadata
- **MetadataExtractor**: Extracts metadata from audio files
- **FeatureExtractionService**: AI-powered music analysis
- **AiShuffleService**: Intelligent playlist reordering
- **PlayCountTrackingService**: Tracks listening statistics
- **EnhancedNotificationService**: Rich media notifications

### Data Models
- **Song**: Core music file representation with metadata
- **Album**: Album information and song collections
- **Artist**: Artist information and discography
- **MyPlaylist**: User-created playlists
- **SongFeatures**: AI-analyzed musical characteristics
- **PlaylistSource**: Source tracking for playlists

## 📱 Screens & Navigation

### Main Navigation
- **Bottom Tab Navigation**: 5-tab navigation with smooth animations
- **For You**: Personalized recommendations and statistics
- **Songs**: Complete music library with advanced filtering
- **Albums**: Album-centric view with artwork
- **Artists**: Artist-centric view with discography
- **Playlists**: Custom playlist management

### Key Screens
- **Music Player**: Full-screen player with album art and controls
- **Settings**: Comprehensive app configuration
- **Profile Edit**: User profile management
- **Music Library Settings**: Library management options
- **Comprehensive Features Settings**: AI feature configuration

## 🎵 Music Features

### Audio Processing
- **Multiple Format Support**: 13+ audio formats supported
- **High-Quality Playback**: Professional audio processing
- **Crossfade Support**: Smooth transitions between tracks
- **Equalizer**: Audio enhancement options
- **Speed Control**: Variable playback speed

### Metadata & Organization
- **Comprehensive Metadata**: Title, artist, album, genre, year, track number, etc.
- **Album Art Extraction**: Automatic album art detection and storage
- **Smart Grouping**: Automatic artist and album grouping
- **File Information**: File size, bitrate, duration tracking
- **Search & Filter**: Advanced search across all metadata

### Playlist Management
- **Custom Playlists**: Create unlimited custom playlists
- **Smart Playlists**: AI-generated playlists based on mood/genre
- **Playlist Sources**: Track playlist sources (album, artist, custom)
- **Queue Management**: Current playing queue with reordering
- **Playlist Statistics**: Track playlist performance

## 🤖 AI & Machine Learning

### Music Analysis
- **YAMNet Integration**: Google's YAMNet for audio classification
- **Feature Extraction**: Comprehensive musical feature analysis
- **Background Processing**: Non-blocking feature extraction
- **Progress Tracking**: Real-time extraction progress
- **Error Handling**: Robust error recovery and retry logic

### Intelligent Features
- **AI Shuffle**: Similarity-based playlist reordering
  - Cycle behavior in UI: AI → Normal Shuffle → None → AI
  - Only one shuffle mode is active at a time
- **Mood Detection**: Emotional analysis of music
- **Genre Classification**: Automatic genre identification
- **Instrument Recognition**: Musical instrument detection
- **Energy Analysis**: Tempo and energy level analysis

### Analytics
- **Listening Patterns**: Track user listening habits
- **Recommendation Engine**: Personalized music suggestions
- **Play Count Analytics**: Detailed play statistics
- **Trend Analysis**: Music consumption trends

## 🎨 User Experience

### Design System
- **Material Design 3**: Latest Material Design guidelines
- **Custom Themes**: Light and dark theme support
- **Typography**: Multiple font families (Poppins, Urbanist, Edu NSW ACT Cursive)
- **Color System**: Comprehensive color palette with gradients
- **Iconography**: Consistent icon usage throughout

### Animations
- **Smooth Transitions**: Page transitions and navigation
- **Micro-interactions**: Button presses and state changes
- **Loading States**: Skeleton loading and progress indicators
- **Gesture Support**: Swipe gestures and touch interactions

### Accessibility
- **Screen Reader Support**: Full TalkBack/VoiceOver support
- **High Contrast**: Support for high contrast themes
- **Font Scaling**: Dynamic font size support
- **Keyboard Navigation**: Full keyboard navigation support

## 🔧 Technical Implementation

### Dependencies
- **Flutter**: Cross-platform UI framework
- **just_audio**: Audio playback engine
- **audio_service**: Background audio service
- **flutter_bloc**: State management
- **hydrated_bloc**: Persistent state
- **get_it**: Dependency injection
- **go_router**: Navigation
- **hive**: Local database
- **music_feature_analyzer**: AI music analysis
- **audiotags**: Metadata extraction
 - **in_app_update**: Silent, background app updates on Android

### Performance
- **Lazy Loading**: Screens and data loaded on demand
- **Caching**: Intelligent caching for better performance
- **Background Processing**: Non-blocking operations
- **Memory Management**: Efficient memory usage
- **Battery Optimization**: Optimized for battery life

### Testing
If tests are added to the project, use the commands below to run them.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.x or higher
- Dart SDK 3.5 or higher
- Android Studio / VS Code
- Git

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run code generation: `flutter packages pub run build_runner build`
   - Dev loop (optional): `flutter packages pub run build_runner watch --delete-conflicting-outputs`
4. Run the app: `flutter run`

### Configuration
- Configure audio permissions in platform-specific files (Android: READ/WRITE/NOTIFICATION, foreground service)
- Set up background processing for feature extraction
- Configure notification channels for media controls
- Google Play in-app updates (Android): Ensure the app is distributed via Play Store for updates to work

## 📊 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants and enums
│   ├── di/                 # Dependency injection
│   ├── router/             # Navigation routing
│   └── theme/              # Theme management
├── screens/                # UI screens
│   ├── app_settings/       # Settings screens
│   ├── bottom_tab/         # Main navigation
│   ├── music_player/       # Music player
│   └── widgets/            # Reusable widgets
├── utils/                   # Utilities and services
│   ├── models/             # Data models
│   ├── services/           # Business logic services
│   └── logger/             # Logging system
└── main.dart               # App entry point
```

## 🧪 Testing

### Test Coverage
- **Unit Tests**: 90%+ coverage for core functionality
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end user flows
- **Feature Tests**: AI feature extraction testing
- **Package Tests**: Third-party integration testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/feature_extraction_comprehensive_test.dart
flutter test test/package_integration_test.dart

# Run with coverage
flutter test --coverage
```

## 🔮 Future Enhancements

### Planned Features
- **Cloud Sync**: Sync playlists and preferences across devices
- **Social Features**: Share playlists and discover music
- **Advanced Analytics**: More detailed listening insights
- **Custom Themes**: User-customizable themes
- **Voice Commands**: Voice control for playback
- **Smart Home Integration**: Connect with smart speakers

### Technical Improvements
- **Performance Optimization**: Further performance improvements
- **Offline Mode**: Enhanced offline functionality
- **Cross-Platform**: Desktop and web support
- **Plugin Architecture**: Extensible plugin system

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for details on how to:
- Report bugs
- Suggest features
- Submit pull requests
- Set up the development environment

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **just_audio**: For excellent audio playback
- **Google**: For YAMNet and AI research
- **Open Source Community**: For the amazing packages

## 📞 Support

For support, feature requests, or bug reports:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

---

**Rhythm Flow** - Where AI meets Music 🎵✨
 
## ℹ️ Notes
 
- Update checks run silently in the background on Android; no blocking UI is shown at launch. High-priority updates may still display system UI as required by Play.
- Shuffle icons in the player reflect three states:
  - AI Shuffle (sparkles icon, active color)
  - Normal Shuffle (shuffle icon, active color)
  - None (shuffle icon with a diagonal cross, inactive color)