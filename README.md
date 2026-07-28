# RhythmFlow — AI Music Player

> *"Music that flows with you."*

A studio-grade Flutter music player built by **TechNexa** — featuring a hardware-accelerated 10-band equalizer with 22 acoustic presets, AI-powered music analysis, intelligent playlist management, a sleep timer, and a beautifully crafted adaptive UI.

---

## Overview

RhythmFlow is a sophisticated local music player that goes far beyond simple playback. It combines professional-grade audio tuning, machine-learning-driven features, and a highly personalized "For You" experience — all persisted locally with zero cloud dependency.

---

## Feature Highlights

| Category | Highlights |
|---|---|
| Audio Engine | Hardware equalizer, Bass Boost, Virtualizer, Loudness, Echo |
| AI | YAMNet genre/mood/instrument analysis, AI Shuffle |
| Playback | Background play, lock-screen controls, variable speed, sleep timer |
| Library | 13+ formats, smart sorting, full metadata, album art |
| UI | Dark/Light adaptive, animated intro, glassmorphism, custom fonts |

---

## Screens & Navigation

### Bottom Tab Navigation (5 tabs)

#### For You
The personalized home dashboard.

- **Daily Quote** — a rotating collection of curated music quotes
- **Listening Statistics** — at-a-glance stats (total songs, albums, artists, play counts)
- **My Suggestions** — deterministic, stable recommendations that only refresh when a song fully completes — no random jumps mid-session
- **Recently Added** — newest tracks from your library
- **Top Artists & Albums** — auto-ranked by your own play history
- **Staggered grid layout** with smooth staggered-entrance animations
- **App Intro popup** — animated 3–4 slide feature tour shown on first install and re-shown automatically on every app update (build-number aware)

#### Songs
Your complete music library.

- Real-time search and multi-criteria filtering
- Multiple sort modes: alphabetical, duration, play count, recently added, year
- **Long-press context menu** on any song: Play, Play Next, Add to Queue, Add to Playlist, Share, Song Info, Delete
- Swipe-to-reveal quick actions (flutter_slidable)
- Skeletonizer loading placeholders while the library scans

#### Albums
- Album grid with extracted cover art
- Tap into an album for its full track list
- Album-level sort and filter

#### Artists
- Artist list with song/album counts
- Drill down to full discography per artist

#### Playlists
- Create, rename, and delete unlimited custom playlists
- Add/remove songs from any screen
- Track source tagging (album, artist, custom)

---

### Music Player

A full-screen player accessible as a modal bottom sheet from anywhere in the app.

- **Large album artwork** with smooth gapless transitions (no flicker on song change)
- **Seek bar** with real-time position tracking (500 ms sync interval)
- **Play / Pause / Previous / Next** controls
- **3-state Shuffle cycle**: None → AI Shuffle → Normal Shuffle → None (icon adapts with active-color indicator)
- **Repeat modes** (via just_audio)
- **Playback speed** — adjustable 0.5×–2.0×
- **Sliding options panel** — swipe left/right on the player to reveal additional actions (queue, playlist, share, etc.)
- **Equalizer Wave Button** — quick-jump to the Equalizer from the player
- **Add to Playlist** popup — browse and assign the current track without leaving the player
- **Auto-scrolling song title** for long track names

---

### Playing Queue

- Full view of the current playback queue
- **Add songs** to the queue on-the-fly
- **Reorder and remove** queue items
- Shuffle controls (same 3-state cycle as the player)
- Displays playlist source context (album / artist / custom playlist / all songs)

---

### Equalizer

Runs in landscape orientation for maximum control surface.

#### 10-Band Equalizer
Hardware-accelerated via Android's `AudioEffect` API through `just_audio`. Drag each band slider to shape your sound across the full frequency spectrum.

#### 22 Built-in Presets

| Genre / Environment | Preset |
|---|---|
| Neutral | Flat |
| Music styles | Bass Boost, Treble, Vocal, Rock, Pop, Jazz, Classical, Studio |
| Room acoustics | Small Room, Medium Room, Large Room |
| Hall acoustics | Small Hall, Medium Hall, Large Hall |
| Special venues | Plate, Concert Hall, Live Stage, Ambient Space |
| Listening contexts | Car Cabin, Headphones Boost |

Each preset automatically configures all four hardware effects for a cohesive sound profile.

#### Custom Presets
- **Save as new** — type a name and save your manually tuned EQ as a custom preset (pencil icon badge)
- **Update** — modify a custom preset and save changes directly, no popup needed
- **Long-press to delete** — arms the chip for deletion (red border + delete icon); tap again to confirm removal with smooth animated disappearance
- Custom presets are fully persisted between sessions

#### Hardware Audio Effects (all independently tunable)

| Effect | Range | Purpose |
|---|---|---|
| Bass Boost | 0 – 1 000 | Hardware low-frequency enhancement |
| Virtualizer | 0 – 1 000 | 3D spatial / surround sound simulation |
| Loudness Enhancer | 0 – 1 000 mB | Intelligent volume boost without clipping |
| Echo | 0 – 100 | Delay/reflection depth control |

#### Stereo Volume Knobs
Independent left and right channel rotary knobs for precise stereo balance.

#### Action Bar (top bar)
Context-aware save controls that automatically show the right action:

| Situation | Action shown |
|---|---|
| Different preset selected, unmodified | **Save** |
| Built-in preset with manual band changes | **Save as new** |
| Custom preset with manual band changes | **Update** |
| Always available | **Undo** (revert to last saved state) |

---

### Settings

Organised into clear sections:

#### Profile
- Set and edit your display nickname

#### Appearance
- **Dark Mode** toggle
- **Follow System Theme** — auto-switches with Android/iOS system setting

#### AI Shuffle
- **Enable AI Shuffle** — intelligently reorders the queue based on musical similarity to the currently playing song
- **Enable Normal Shuffle** — standard random shuffle (mutually exclusive with AI Shuffle)
- **Music Features Analysis** — navigate to the analysis dashboard

#### Music & Playback
- **Music Library** — manage your local music collection (see below)
- **Notification Bar Widget** — enable lock-screen and status-bar media controls (Android)
- **Auto Play Next** — automatically advance to the next track
- **Playback Speed** — slider from 0.5× to 2.0× in 0.1 steps
- **Sleep Timer** — enable with a duration slider (5 min to 2 hours); playback stops automatically when the timer expires

#### Sound & Equalizer
- **Enable Equalizer** toggle (Android only)
- **Open Equalizer** — navigate directly to the full EQ screen

#### Advanced
- **Background Refresh** — configure the library auto-scan interval (1–24 hours)
- **Reset Settings** — restore all app settings to defaults (profile and theme preserved)
- **App Version** — displays current version and build number

#### About
- **TechNexa** — company website link (in-app WebView)

---

### Music Library Settings
- Add or remove music source folders with the system file picker
- Trigger a full library rescan
- View scan progress in real time

---

### Music Features Analysis (AI Dashboard)

- **Extraction progress** — percentage of library analyzed, with per-song status
- **Genre distribution** — visual breakdown of detected genres across your library
- **Statistics** — count of analyzed tracks, detected genres, instruments, mood categories
- **Start / Stop analysis** — run background extraction on demand
- Built on **YAMNet** (Google's audio classification model) via the `music_feature_analyzer` package

---

## AI & Intelligent Features

### Music Feature Analysis
Uses the YAMNet TFLite model to extract musical characteristics from each track in the background without blocking playback:

- **Genre classification** — Rock, Pop, Jazz, Classical, Electronic, and more
- **Instrument detection** — identify dominant instruments in a track
- **Mood & energy analysis** — valence, energy, danceability estimation
- **Tempo detection** — BPM estimation and rhythmic classification

Progress is tracked per-song and persisted, so extraction resumes seamlessly after app restarts.

### AI Shuffle
When AI Shuffle is active, the playing queue is dynamically reordered to place the most musically similar songs next — based on extracted features of the currently playing track. The three shuffle states cycle in order:

```
None  →  AI Shuffle  →  Normal Shuffle  →  None
```

Only one mode is active at a time. All states are synced between the Music Player, Playing Queue, and Settings screens.

> **AI Accuracy Note:** Genre classification, instrument detection, and mood analysis rely on the YAMNet model. Results are best-effort approximations and may not always be accurate. This reflects the current state of available open models rather than a limitation of the app itself.

---

## Audio & Playback

### Supported Formats
MP3, M4A, AAC, WAV, FLAC, OGG, WMA, OPUS, AIFF, ALAC, and more (13+ formats via `just_audio`).

### Playback Capabilities
- **High-quality audio** via the `just_audio` engine
- **Background playback** — music continues when the app is backgrounded or the screen is locked
- **Lock screen & notification controls** — rich media session with album art, title, and transport controls
- **Gapless album art transitions** — no default-image flash between tracks or on screen/tab change
- **Variable speed** — 0.5× to 2.0× without pitch change
- **Sleep timer** — auto-stop after a configurable duration (5 min – 2 hours)
- **Auto play next** — seamlessly advance through the queue

---

## Metadata & Library Management

- **Comprehensive tag support**: ID3v1, ID3v2, APE, Vorbis Comments, iTunes/MP4, FLAC via `audiotags`
- **Fields extracted**: Title, artist, album, genre, year, track number, disc number, duration, file size, bitrate
- **Album art**: Automatic extraction and in-memory caching; displayed everywhere from list items to the full-screen player
- **Smart grouping**: Songs are automatically grouped into Albums and Artists
- **Background scanning**: `workmanager` schedules periodic library rescans at a user-configurable interval
- **Play count tracking**: Every listen is recorded and drives the "Top Artists", "Top Albums", and "My Suggestions" sections

---

## User Interface & Design

### Theme System
- **Adaptive dark / light themes** with `ThemeExtension`-based semantic color tokens
- **Follow System Theme** mode keeps the app in sync with the OS preference automatically
- **Gradient backgrounds** — unique for each theme variant; equalizer background cycles through curated photography

### Typography
Four custom font families, each serving a distinct purpose:

| Font | Usage |
|---|---|
| Poppins | Primary UI text, settings, labels |
| Urbanist | Headings, artist/album names |
| EduNSWACTCursive | Decorative accents, daily quote |
| Yu Gothic UI | Alternative display contexts |

### Animations & Motion
- **Lottie animations** — equalizer wave and loop sequences
- **Staggered list entrance** — items animate in with delays per section
- **AnimatedSwitcher & AnimatedContainer** — smooth state transitions (e.g. preset chip delete arm/disarm)
- **Slide + fade animations** — app intro popup card transitions; equalizer action bar reveal
- **Auto-scrolling text** — long song titles scroll horizontally rather than truncate
- **3D card effect** — custom perspective tilt widget used in the app intro
- **Liquid glass renderer** — glassmorphism effects on select UI surfaces

### App Intro Popup
Displayed on first launch and re-shown after every app update:

- 3–4 animated slides, each highlighting a key feature (Equalizer, AI Shuffle, Player gestures, Library)
- Auto-advances to the next card after 3 seconds; timer resets on manual swipe
- Dot-indicator page progress
- "Explore app" button on the final slide to dismiss
- Fully theme-adaptive (dark/light)

---

## Architecture

### Pattern
Clean Architecture with the BLoC pattern throughout.

```
lib/
├── core/
│   ├── constants/       # AppConstants, EqualizerBandPresets, EqualizerPresetEffects, enums
│   ├── di/              # GetIt service locator + Injectable
│   ├── router/          # GoRouter navigation graph + extension helpers
│   ├── theme/           # ThemeBloc, AppTheme, ThemeExtension
│   └── widgets/         # Shared widgets (AppCustom, CustomToast, CustomPopup, Custom3DCard …)
├── screens/
│   ├── app_settings/    # Settings, Profile Edit, Music Library Settings, AI Features Settings
│   │   └── bloc/        # AppSettingsBloc (HydratedBloc)
│   ├── bottom_tab/      # For You, Songs, Albums, Artists, Playlists tabs + shared widgets
│   │   └── bloc/        # MusicBloc (HydratedBloc) — central music state
│   ├── equalizer/       # Equalizer screen, band sliders, knob row, app bar
│   │   └── bloc/        # EqualizerBloc (HydratedBloc) + EqualizerPresetEntry
│   ├── music_player/    # Full-screen player modal + popup mini player
│   ├── palying_queue_screen/  # Playing queue view
│   ├── playlist_detail_screen/
│   └── widgets/         # AlbumArtWidget, SortingHelper, PlaylistSourceHelper …
└── utils/
    ├── models/          # Song, Album, Artist, MyPlaylist, SongFeatures, PlaylistSource
    ├── services/        # AudioService, AudioEffectsService, AiShuffleService,
    │                    #   PlayCountTrackingService, FetchSongsService,
    │                    #   MusicMetadataService, EnhancedNotificationService, PermissionService
    └── logger/          # AppLogger (wraps the logger package)
```

### State Management
- **HydratedBloc** for `MusicBloc`, `AppSettingsBloc`, and `EqualizerBloc` — state survives process kills
- **BlocConsumer / BlocBuilder** for reactive UI rebuilds scoped to the minimum required subtree
- **Freezed** unions for type-safe events and states with code generation

### Key Services

| Service | Responsibility |
|---|---|
| `AudioService` | `just_audio` player lifecycle, queue, position streams |
| `AudioEffectsService` | Hardware EQ, Bass Boost, Virtualizer, Loudness, Echo |
| `FetchSongsService` | Batch metadata extraction via `MusicFeatureAnalyzer` |
| `MusicMetadataService` | Maps raw `SongModel` → app `Song` + `SongFeatures` |
| `AiShuffleService` | Similarity-based queue reordering |
| `PlayCountTrackingService` | Increments per-song play counts, drives recommendations |
| `EnhancedNotificationService` | Rich media notification with artwork |
| `PermissionService` | Storage and notification permission gating |

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `just_audio` | Audio playback engine |
| `audio_service` | Background audio service + media session |
| `music_feature_analyzer` | YAMNet-based audio feature extraction (custom package) |
| `flutter_bloc` + `hydrated_bloc` | State management + persistence |
| `get_it` + `injectable` | Dependency injection |
| `go_router` | Declarative navigation |
| `hive` + `hive_flutter` | Local database |
| `workmanager` | Background task scheduling |
| `in_app_update` | Silent Android in-app updates |
| `flutter_animate` | Declarative animation API |
| `lottie` | Lottie JSON animations |
| `liquid_glass_renderer` | Glassmorphism shader effects |
| `knob_widget` | Rotary volume knob UI |
| `flutter_slidable` | Swipe-to-reveal list actions |
| `skeletonizer` | Skeleton loading shimmer |
| `freezed` | Immutable model + union code generation |

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.8.1` and Dart SDK `^3.8.1`
- Android Studio or VS Code with Flutter/Dart plugins
- Android device or emulator (Android 6.0+ for equalizer hardware effects)

### Installation

```bash
# 1. Clone the repo
git clone <repository-url>
cd RhythmFlow

# 2. Install dependencies
flutter pub get

# 3. Generate code (Freezed, JSON serialization, Injectable, GoRouter)
flutter packages pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

> **Dev loop** (watch mode): `flutter packages pub run build_runner watch --delete-conflicting-outputs`

### Android Permissions
The following are declared in `AndroidManifest.xml`:
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` — music library access
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — background audio
- `POST_NOTIFICATIONS` — lock-screen and status-bar media controls

### In-App Updates (Android)
Update checks run silently in the background at launch. No blocking UI is shown for flexible updates. High-priority (immediate) updates may display system UI as required by the Play Store policy. The app must be distributed via the Google Play Store for in-app updates to function.

---

## Notes

- **Equalizer** is available on Android only (hardware `AudioEffect` API). The Settings screen shows the EQ option only when running on Android.
- **Shuffle icon states** in the Music Player and Playing Queue:
  - Sparkles icon, active colour → **AI Shuffle**
  - Shuffle arrows, active colour → **Normal Shuffle**
  - Shuffle arrows with diagonal cross, inactive colour → **Off**
- **My Suggestions** list is deterministic within a session — it only recalculates when a song finishes playing or the library changes, preventing disruptive reordering mid-session.
- **Background Refresh** time gap (1–24 hours) controls how often `workmanager` rescans the music library for new or removed files.
- **AI Accuracy Disclaimer**: Genre classification, instrument detection, and mood analysis use the YAMNet TFLite model. Accuracy is best-effort and results should be considered approximate. This reflects current open-model limitations rather than an app deficiency.

---

## Future Enhancements

- **Cloud sync** — playlists and preferences across devices
- **Crossfade** — configurable crossfade duration between tracks
- **Advanced analytics** — listening trends, time-of-day patterns
- **Custom themes** — user-defined accent colours
- **Voice commands** — hands-free playback control
- **Desktop / Web** — cross-platform expansion

---

## Contributing

Contributions are welcome! To get started:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes following the existing code style
4. Open a pull request describing the change and the motivation

Please report bugs and suggest features via GitHub Issues.

---

## License

This project is licensed under the **MIT License** — see the `LICENSE` file for details.

---

## Acknowledgements

- **Flutter team** — for the excellent cross-platform framework
- **just_audio** — for the robust and flexible audio engine
- **Google** — for YAMNet and the AudioEffect API
- **Open-source community** — for every package that powers this app

---

## Support

- Open an issue on GitHub for bugs or feature requests
- Visit [TechNexa](https://technexa.in) for company information and other projects

---

*RhythmFlow — Where AI meets Music*
