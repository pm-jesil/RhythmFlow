import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/widgets/app_custom.dart';
import '../../utils/models/ringtone/ringtone_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/ringtone/ringtone_service.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import 'bloc/ringtone_library_bloc.dart';
import 'my_ringtones_screen.dart';
import 'ringtone_editor_screen.dart';

/// Opens the ringtone editor for [song] (local or Discover). The playing
/// song is paused by the editor.
Future<void> openRingtoneEditor(BuildContext context, Song song) async {
  final reason = RingtoneService.unavailableReason(song);
  if (reason != null) {
    AppCustom.info(context, reason);
    return;
  }
  if (!getIt.isRegistered<RingtoneService>()) return;
  Duration? position;
  try {
    final music = context.read<MusicBloc>();
    if (music.state.myPlayerState.currentSongId == song.id) {
      position = music.audioPosition;
    }
  } catch (_) {}
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RingtoneEditorScreen(song: song, initialPosition: position),
    ),
  );
}

void openMyRingtones(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRingtonesScreen()));
}

/// Sets [item] as the phone's [use] sound, asking for the "Modify system
/// settings" permission when needed.
Future<bool> setRingtoneAs(BuildContext context, RingtoneItem item, RingtoneUse use) async {
  final service = getIt<RingtoneService>();
  final result = await service.setAs(item, use);
  if (!context.mounted) return false;
  switch (result) {
    case RingtoneSetResult.done:
      context.read<RingtoneLibraryBloc>().add(RingtoneLibraryEvent.markedDefault(id: item.id, use: use));
      AppCustom.success(context, '"${item.name}" set as your ${use.label.toLowerCase()} sound');
      return true;
    case RingtoneSetResult.needsPermission:
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('ringtone_permission_dialog'),
          backgroundColor: ctx.cardColor,
          title: Text('Allow changing sounds', style: TextStyle(color: ctx.onSurfaceColor)),
          content: Text(
            'To set a ringtone, allow RhythmFlow to "Modify system settings" on the next screen, '
            'then come back and tap ${use.label} again.',
            style: TextStyle(color: ctx.onSurfaceVariantColor),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            ElevatedButton(
              key: const ValueKey('ringtone_permission_open'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (open == true) await service.openPermissionSettings();
      return false;
    case RingtoneSetResult.unsupported:
      AppCustom.info(context, 'Setting the phone ringtone is available on Android');
      return false;
    case RingtoneSetResult.failed:
      AppCustom.error(context, 'Could not set the ${use.label.toLowerCase()} sound');
      return false;
  }
}

/// Row of "Ringtone / Notification / Alarm" buttons.
class SetAsButtons extends StatelessWidget {
  const SetAsButtons({super.key, required this.item});
  final RingtoneItem item;

  @override
  Widget build(BuildContext context) {
    final uses = context.select<RingtoneLibraryBloc, List<RingtoneUse>>((b) => b.state.usesOf(item.id));
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: [
        for (final use in RingtoneUse.values)
          ChoiceChip(
            key: ValueKey('set_as_${use.name}'),
            selected: uses.contains(use),
            avatar: Icon(
              switch (use) {
                RingtoneUse.ringtone => CupertinoIcons.phone_fill,
                RingtoneUse.notification => CupertinoIcons.bell_fill,
                RingtoneUse.alarm => CupertinoIcons.alarm_fill,
              },
              size: 16.sp,
              color: context.primaryStart,
            ),
            label: Text(use.label),
            onSelected: (_) => setRingtoneAs(context, item, use),
          ),
      ],
    );
  }
}

/// "My Ringtones" tile shown on the Playlists tab (My Music and Discover).
class MyRingtonesTile extends StatelessWidget {
  const MyRingtonesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<RingtoneLibraryBloc, int>((b) => b.state.count);
    return Material(
      color: context.cardColor.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        key: const ValueKey('my_ringtones_tile'),
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => openMyRingtones(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: context.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Ringtones',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'Make one from any song in the player'
                          : '$count ringtone${count == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.onSurfaceVariantColor,
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: context.onSurfaceVariantColor, size: 16.sp),
            ],
          ),
        ),
      ),
    );
  }
}

String formatClock(Duration d, {bool tenths = false}) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  final base = '$m:${s.toString().padLeft(2, '0')}';
  if (!tenths) return base;
  return '$base.${(d.inMilliseconds % 1000) ~/ 100}';
}
