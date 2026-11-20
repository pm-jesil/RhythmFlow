# Changelog

## 1.1.2

### New: Discover (free online music from Jamendo)
- **My Music | Discover** switch under the greeting card on For You. Every
  tab follows the selected source; Discover is the default.
- **Discover home**: Top in your country, picks in your language, trending,
  fresh albums, curated mixes, artists and 24/7 live radio, plus "Jump back
  in". Each row loads independently with its own shimmer skeleton and retry.
- **Online tabs**: Songs (search, Popular/Newest, mood and genre chips,
  infinite scroll), Albums, Artists, and Playlists (liked songs, recently
  played, downloads, mixes, radio).
- **Country & language**: chosen from lists of the 159 countries and 47
  languages that actually have music on Jamendo (surveyed from the live
  API). Asked on the Welcome screen, in Profile, and through a first-time
  "Personalise Discover" popup that shows a "setting up your music player"
  progress while Discover loads, then closes by itself.
- **Streaming** through the existing player, mini player, queue and
  notification (network cover art); signed stream URLs are refreshed.
- **Download to My Music** for tracks whose artists allow it: progress,
  title/artist/album/cover/licence tags, saved to `Music/RhythmFlow`, and the
  library updates automatically.
- Offline: cached results with an offline banner; nothing is lost.

### Notes
- Jamendo's `lang` filter returns no results, so language picks combine
  language tags with artists from countries where the language is spoken.
- Jamendo randomly answers ~1 in 4 requests with an empty result; the client
  retries those and never caches empty responses.
- Build with `--dart-define-from-file=config/jamendo.json` (see README).

### Fixes
- `isAiShuffleEnabled` is now persisted.
- Media cards / pickers no longer overflow with large fonts.


## 1.1.1

### Fixed – music library scanning and counts
- Albums and Artists tabs now update immediately when a scan adds or removes
  albums/artists (they previously kept the first list until restart).
- Duplicate detection no longer hides real songs: it needs the same title,
  artist **and** duration, keeps "(Live)", "(Remix)" etc., and handles
  non-Latin titles (Malayalam, Tamil, Hindi, ...) which previously all
  collapsed into a single song.
- Duplicate removal now covers the whole library, not each batch of 10 files
  separately, so the song count is the same whichever scan path ran.
- Songs whose duration cannot be read are kept (duration is learned on first
  play); files over 100 MB / 1 hour are no longer dropped; MP3s with padding
  before the first frame and FLACs with an ID3 header are accepted.
- The library refreshes automatically when the app is resumed, when Android
  reports audio file changes, and when music folders/formats change.
  "Fetch songs" always rescans.
- Removing a music folder (or disabling a format) removes its songs.
- Edited files are re-read; play counts, favourites and playlists are kept.
- Concurrent scan / feature-extraction requests are coalesced instead of
  running in parallel.
- Albums are grouped by album name + album artist (or folder) with stable
  IDs; removed songs no longer leave empty albums/artists behind.
- Deleting the current song clears it from the player.
- Deleting a song works on Android 11+ (system confirmation dialog) and no
  longer triggers a full rescan.
- Orphaned cached album art is deleted.
- Shuffle-off no longer fails when the queue's album/artist disappeared.

### Performance
- The library is stored in its own Hive box and written (debounced) only when
  it changes, instead of being re-serialised by HydratedBloc on every state
  change (e.g. every playback position update).
- Files that were skipped (duplicates, clips, unreadable) are not re-read on
  every scan unless they change.
- The ML feature analyzer is initialised lazily (faster cold start).

### Android / Play Store
- Removed `MANAGE_EXTERNAL_STORAGE` and `WRITE_SETTINGS`; legacy storage
  permissions are limited to the Android versions that need them.
- `MainActivity` now extends `AudioServiceActivity` and adds the MediaStore
  delete / change-observer bridge.

### Other
- Storage permission is requested once on first launch.
- Settings shows the real app version.
- Stat cards on For You no longer overflow with large system fonts.
- Fixed 17 previously failing tests; added 119 library tests.
