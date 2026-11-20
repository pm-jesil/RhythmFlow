# Changelog

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
