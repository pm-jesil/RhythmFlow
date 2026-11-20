// Static checks of the Android platform files that background playback,
// the lock-screen notification, Discover downloads and the ringtone maker
// depend on. A release build strips, renames or rejects things silently, so
// these are checked from source.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythmflow/main.dart' show rhythmFlowAudioServiceConfig;
import 'package:rhythmflow/utils/services/audio_handler.dart';

const res = 'android/app/src/main/res';
final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
final activity =
    File('android/app/src/main/kotlin/com/technexa/rhythmflow/MainActivity.kt').readAsStringSync();
final bridge = File('lib/utils/services/media_store_bridge.dart').readAsStringSync();
final handlerSource = File('lib/utils/services/audio_handler.dart').readAsStringSync();
final keep = File('$res/raw/keep.xml').readAsStringSync();
final gradle = File('android/app/build.gradle.kts').existsSync()
    ? File('android/app/build.gradle.kts').readAsStringSync()
    : File('android/app/build.gradle').readAsStringSync();

/// `<uses-permission android:name="X" .../>` blocks.
Map<String, String> permissions() {
  final out = <String, String>{};
  for (final m in RegExp(r'<uses-permission\b[^>]*?/>', dotAll: true).allMatches(manifest)) {
    final tag = m.group(0)!;
    final name = RegExp(r'android:name="android\.permission\.([A-Z_]+)"').firstMatch(tag)?.group(1);
    if (name != null) out[name] = tag;
  }
  return out;
}

void main() {
  group('background playback & lock screen', () {
    test('foreground service permissions for every Android version', () {
      final p = permissions();
      expect(p.keys, containsAll(['WAKE_LOCK', 'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MEDIA_PLAYBACK']),
          reason: 'Android 9+ needs FOREGROUND_SERVICE, Android 14+ the typed permission');
    });

    test('audio_service service is declared with the mediaPlayback type', () {
      final service = RegExp(
        r'<service\s[^>]*com\.ryanheise\.audioservice\.AudioService[^>]*>',
        dotAll: true,
      ).firstMatch(manifest)?.group(0);
      expect(service, isNotNull);
      expect(service, contains('android:foregroundServiceType="mediaPlayback"'),
          reason: 'Android 14+ refuses to start an untyped foreground service');
      expect(service, contains('android:exported="true"'), reason: 'Android 12+ requires exported');
      expect(manifest, contains('android.media.browse.MediaBrowserService'));
    });

    test('media buttons (headset, Bluetooth, lock screen) reach the app', () {
      expect(manifest, contains('com.ryanheise.audioservice.MediaButtonReceiver'));
      expect(manifest, contains('android.intent.action.MEDIA_BUTTON'));
      expect(activity, contains('class MainActivity : AudioServiceActivity()'),
          reason: 'audio_service needs its activity to share the Flutter engine');
    });

    test('every notification icon exists and survives release resource shrinking', () {
      final icons = RegExp(r"'drawable/([a-z_]+)'").allMatches(handlerSource).map((m) => m.group(1)!).toSet()
        ..add(rhythmFlowAudioServiceConfig.androidNotificationIcon.split('/').last);
      expect(icons, containsAll(['ic_shuffle', 'ic_shuffle_ai', 'ic_shuffle_off', 'ic_repeat_off',
          'ic_repeat_one', 'ic_repeat_all', 'ic_stat_rhythmflow']));
      for (final icon in icons) {
        expect(File('$res/drawable/$icon.xml').existsSync(), isTrue, reason: '$icon.xml missing');
        expect(keep, contains('@drawable/$icon'),
            reason: '$icon is only referenced from Dart; shrinkResources removes it without keep.xml');
      }
      expect(gradle, contains('isShrinkResources = true'),
          reason: 'if shrinking is turned off this test can be relaxed, keep.xml stays harmless');
    });

    test('notification config: ongoing needs stop-foreground-on-pause; art is downscaled', () {
      const c = rhythmFlowAudioServiceConfig;
      expect(c.androidNotificationOngoing, isTrue);
      expect(c.androidStopForegroundOnPause, isTrue, reason: 'audio_service asserts this pairing');
      expect(c.androidNotificationIcon, 'drawable/ic_stat_rhythmflow');
      expect(c.artDownscaleWidth, lessThanOrEqualTo(1024));
      expect(c.artDownscaleHeight, lessThanOrEqualTo(1024),
          reason: 'full-size covers can exceed the Binder limit of a lock-screen update');
      expect(c.androidNotificationClickStartsActivity, isTrue);
    });

    test('custom action ids are stable (used by the notification)', () {
      expect(RhythmFlowAudioHandler.shuffleActionId, 'com.technexa.rhythmflow.SHUFFLE');
      expect(RhythmFlowAudioHandler.repeatActionId, 'com.technexa.rhythmflow.REPEAT');
    });
  });

  group('storage, downloads and ringtones', () {
    test('storage permissions are limited to the versions that need them', () {
      final p = permissions();
      expect(p['READ_EXTERNAL_STORAGE'], contains('android:maxSdkVersion="32"'));
      expect(p['WRITE_EXTERNAL_STORAGE'], contains('android:maxSdkVersion="28"'),
          reason: 'needed to write Music/ and Ringtones/ on Android 9 and older only');
      expect(p.keys, contains('READ_MEDIA_AUDIO'));
      expect(p.keys, isNot(contains('MANAGE_EXTERNAL_STORAGE')), reason: 'Play rejects it for music players');
    });

    test('WRITE_SETTINGS (set as ringtone) is declared as a protected permission', () {
      final tag = permissions()['WRITE_SETTINGS'];
      expect(tag, isNotNull);
      expect(tag, contains('tools:ignore="ProtectedPermissions"'));
      expect(activity, contains('Settings.ACTION_MANAGE_WRITE_SETTINGS'));
      expect(activity, contains('Settings.System.canWrite'));
      expect(activity, contains('RingtoneManager.setActualDefaultRingtoneUri'));
    });

    test('every platform call made from Dart has a handler in MainActivity', () {
      final calls = RegExp(r"invoke(?:Map)?Method<[^>]*>\(\s*'([a-zA-Z]+)'")
          .allMatches(bridge)
          .map((m) => m.group(1)!)
          .toSet();
      expect(calls, containsAll(['deleteAudioFile', 'saveAudioToMusic', 'startObserving', 'stopObserving',
          'saveRingtone', 'setDefaultRingtone', 'canWriteSettings', 'openWriteSettings',
          'renameRingtone', 'deleteRingtone', 'trimAudio']));
      for (final method in calls) {
        expect(activity, contains('"$method" ->'), reason: 'no Kotlin handler for $method');
      }
      expect(activity, contains('"onMediaStoreChanged"'), reason: 'native -> Dart change callback');
      expect(bridge, contains("call.method == 'onMediaStoreChanged'"));
    });

    test('ringtones are saved where Android lists them, scoped and legacy', () {
      expect(activity, contains('Environment.DIRECTORY_RINGTONES + "/RhythmFlow"'), reason: 'Android 10+');
      expect(activity, contains('Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RINGTONES)'),
          reason: 'Android 9 and older');
      for (final flag in ['IS_RINGTONE', 'IS_NOTIFICATION', 'IS_ALARM', 'IS_PENDING']) {
        expect(activity, contains('MediaStore.Audio.Media.$flag'));
      }
      expect(activity, contains('MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4'));
      expect(activity, contains('MediaFormat.MIMETYPE_AUDIO_AAC'));
    });

    test('long work runs off the main thread', () {
      final body = activity.substring(activity.indexOf('private fun saveAudioToMusic'));
      expect(body, contains('Thread {'));
      expect(activity, contains('private fun background(result: MethodChannel.Result'));
      expect(RegExp(r'"trimAudio" ->[\s\S]*?Thread \{').hasMatch(activity), isTrue);
    });

    test('channel name matches on both sides', () {
      expect(activity, contains('"com.technexa.rhythmflow/media_store"'));
      expect(bridge, contains("'com.technexa.rhythmflow/media_store'"));
    });
  });
}
