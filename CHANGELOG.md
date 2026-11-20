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

### Taste & suggestions
- **Pick your vibe**: 30 genres and 10 moods (Hip-Hop & Rap, Lo-fi,
  Traditional, Indian, Romantic, Sad, …) — only tags that really have music
  on Jamendo (live survey, ≥ 1000 tracks each).
- **Made for you**: suggestions built on the device from your picked vibes,
  the genres/moods of artists you like and play (`/artists/musicinfo`) and
  more songs by those artists (Jamendo has no working "similar tracks"
  endpoint). Refreshes when you like songs.
- **Because you like …** rows and **Your mixes** (one per vibe).
- New For You layout on Discover: vibe chips, quick-access "Jump back in"
  grid, featured hero carousel and a ranked Top 10 chart.

### New: Ringtone maker
- **Make a ringtone from any song** — My Music or Discover. In the full
  player open the extra options (arrow) and tap the bell, or use
  "Make Ringtone" in a song's menu.
- The editor **pauses the playing song**, then shows the part to cut
  (30 s from where you were listening): range slider, ±0.5 s fine-tune for
  start and end, a preview that plays only the selection (separate player:
  the queue, notification and history are untouched), and a name field.
- **Discover songs are downloaded automatically** for editing (with
  progress), only when the artist allows downloads; a song already
  downloaded to My Music is reused, and the last few are cached. Live radio
  can't be used.
- Lossless cutting, no re-encoding: MP3 on frame boundaries and WAV in Dart,
  AAC/M4A with Android's MediaExtractor + MediaMuxer. Other formats (FLAC,
  OGG, …) show a clear message. Length 1–60 s.
- Saved to `Ringtones/RhythmFlow` and registered with Android as a
  ringtone / notification / alarm sound. **Set as ringtone, notification or
  alarm** right after saving or from the list (asks once for "Modify system
  settings").
- **My Ringtones** tile on the Playlists tab of both My Music and Discover,
  opening a list like the song list: tap to preview, and rename (names kept
  unique), share, set as… or delete. Ringtones deleted outside the app
  disappear from the list.

### Lock screen & notification reliability (all Android versions)
- **Notification no longer disappears mid-queue.** When one song failed to
  load (broken Discover track, network drop, corrupt file) the player
  reported `idle`; audio_service then removed the notification and stopped
  its foreground service, and Android 12+ does not allow restarting it from
  the background — the next song played with no notification or lock-screen
  controls. `idle` is now reported only after an explicit stop.
- **Pausing from the lock screen / headset no longer restarts the song.**
  just_audio's `play()` completes only when playback pauses; it was awaited
  before telling the app, so the app's "play" arrived exactly when the user
  paused. Lock-screen play/pause are now idempotent (`MusicEvent.setPlaying`):
  double presses or late duplicates never toggle the song back on, and an
  app/audio mismatch is corrected.
- **Release builds kept the shuffle/repeat notification icons** — they were
  removed by resource shrinking (only referenced from Dart). Added
  `res/raw/keep.xml` and a proper monochrome status-bar icon.
- **Large cover art is downscaled (512 px)** before it is sent to the lock
  screen; multi-MB embedded covers could exceed Android's Binder limit and
  make the notification update fail.
- **Swiping the app away** no longer disposes the player under a live
  notification: it keeps playing (controls keep working), or ends the
  session cleanly when paused.
- **Audio focus**: the audio session is configured for music, so calls and
  other players pause/duck RhythmFlow and unplugging headphones pauses it.
- Lock-screen seek bar gets the real duration for songs without one in their
  tags; player errors no longer freeze the notification state.
- **Play counts** are credited to the right song (tracking used to start
  only after the song ended, because `play()` was awaited).

### Ringtone platform fixes
- WAV ringtones use Android's `audio/x-wav` type (no double extension).
- A delete Android refuses is reported instead of silently dropping the
  ringtone from the list; renaming a ringtone made by an earlier install
  explains why it can't be renamed.

### Playback fixes (Discover ↔ My Music)
- The queue screen and the mini player now show Discover queues (they only
  looked in the device library).
- The full player's heart likes a Discover song (Liked songs) instead of
  adding its id to the local Favourites playlist; "+" downloads it instead of
  adding it to a local playlist (live radio shows a note).
- Song menu labels no longer overflow with large fonts.

### Access
- Discover (home and its tabs) is only for a signed-in user (profile name)
  who finished the Discover setup. Anything missing — name, country,
  language or vibes — is asked in **one** form; otherwise a "Finish setting
  up Discover" card is shown.

### Notes
- Jamendo's `lang` filter returns no results, so language picks combine
  language tags with artists from countries where the language is spoken.
- Jamendo randomly answers ~1 in 4 requests with an empty result; the client
  retries those and never caches empty responses.
- Build with `--dart-define-from-file=config/jamendo.json` (see README).

### Fixes
- Downloads are checked to be real audio before being saved (Jamendo can
  answer broken tracks with an error page).
- An unplayable Discover song no longer triggers a device library rescan.
- The "too many unplayable songs" limit is now enforced: an offline Discover
  queue stops instead of skipping through every song.
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

_(1.1.2 test count: 492 passing + 19 opt-in live API tests — see docs/TESTING.md.)_
