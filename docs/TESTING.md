# Testing RhythmFlow

```bash
dart run build_runner build --delete-conflicting-outputs   # once
flutter test                                               # everything (offline)
flutter test test/library                                  # My Music: scanning, counts
flutter test test/online                                   # Discover: client, blocs, playback, UI
flutter test test/ringtone                                 # ringtone maker: cutter, service, blocs, UI
flutter test test/live --dart-define-from-file=config/jamendo.json   # real Jamendo API
```

| Suite | What it covers |
|---|---|
| `test/library/` | Real temp folders + fake tag reader: new / deleted / edited files, removed folders, disabled formats, duplicates (incl. Malayalam/Tamil/Hindi titles), album & artist counts, persistence, concurrent scans, Albums/Artists tab refresh. |
| `test/online/jamendo_data_layer_test.dart` | URL building (`%20`, never `+`), retries, empty-result retries, error mapping, parsing of recorded Jamendo responses (string vs number quirks), cache freshness / offline fallback, repository queries, region lists. |
| `test/online/online_blocs_test.dart` | Discover sections (order, per-section errors, fallbacks, personal rows, Made for you inputs, persistence), browse paging / debounced search, online library (likes, history, downloads). |
| `test/online/taste_and_recommendation_test.dart` | Taste catalogue, taste profile scoring, blending, per-tag query fallback, artist tags, login/profile rules, one-step Discover profile save. |
| `test/online/online_playback_test.dart` | Playing Discover lists through the real `MusicBloc`: queue, next/previous, shuffle revert, AI-shuffle fallback, queue persistence, offline stop, history/region wiring. Switching Discover → My Music → Discover (queue swapped each time, nothing online persisted for a local queue, library untouched), pause/resume for both sources, `pauseIfPlaying`, history only for Discover songs, a failing local song not blocking a later Discover queue. |
| `test/ringtone/audio_trimmer_test.dart` | Synthesised MP3 frames (MPEG-1/2, padding, ID3v2, Xing, ID3v1, junk resync) and WAV files (extra chunks, stereo alignment): frame-exact cuts, durations, headers, unsupported formats. |
| `test/ringtone/ringtone_logic_test.dart` | Selection rules (default 30 s from the play position, 1–60 s, inside the song), names (cleaning, unicode, unique), which songs qualify, auto-download of Discover songs (progress, cache, reuse of My Music downloads, error pages, offline/server errors, cache limit), create / rename / delete / set as (permission, failures, non-Android), library bloc (order, defaults, verify, persistence), editor cubit (prepare, retry, trim handles, real length, save, failed save). |
| `test/ringtone/ringtone_ui_test.dart` | Editor: pauses music, ±0.5 s buttons, preview of the selection, rename + save, Discover download progress, unusable songs, retry, closing, set as ringtone with the permission dialog, open My Ringtones. List: empty state, preview, rename to a taken name, set as alarm, delete with cancel/confirm, files deleted outside the app. My Ringtones tile on the Playlists tab; "Make Ringtone" in the song menu. |
| `test/online/download_service_test.dart` | Allowed-only downloads, progress, tags, validation of real audio, failures, duplicate taps, MediaStore bridge. |
| `test/online/discover_ui_test.dart` | Widget flows: source switch, gate, one-form setup (name + region + vibes) → setting up → closes, pickers, Discover home (chart, vibes, mixes), online tabs, playlists, radio. |
| `test/live/` | One test per Jamendo endpoint and feature against the live API (skipped without a client id), including a ringtone cut from a real downloaded Discover song. |

## Jamendo API behaviour found by the live tests

* About 1 in 4 valid requests returns an empty "success" response; the client
  retries empty results and never caches them.
* `lang` (lyrics language) returns nothing for every language; language picks
  use tags + artists located in countries that speak the language.
* `search` combined with `order`/`boost` returns nothing; filters such as
  `fuzzytags` only work with `boost`; `order` on `/artists/locations` cuts
  results to a handful; `include=musicinfo` increases empty responses.
* Some tags only work with `tags` (e.g. `lofi`), others only with
  `fuzzytags` (e.g. `blues`); `rap` is the same tag as `hiphop`.
* `/tracks/similar` always returns 0 — suggestions are computed on the device.
* Individual tracks can be broken on Jamendo's side (stream 404, download
  500); the player skips them and downloads are validated before saving.
* Download URLs serve real MP3s even though some responses are labelled
  `text/html`.
