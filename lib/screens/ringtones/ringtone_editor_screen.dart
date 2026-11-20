import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../utils/models/ringtone/ringtone_model.dart';
import '../../utils/models/song/song_model.dart';
import '../../utils/services/ringtone/ringtone_service.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../online/widgets/online_widgets.dart' show OnlineArtwork;
import '../online/widgets/region_pickers.dart' show GradientButton;
import 'bloc/ringtone_editor_cubit.dart';
import 'bloc/ringtone_library_bloc.dart';
import 'my_ringtones_screen.dart';
import 'ringtone_actions.dart';
import 'ringtone_preview.dart';

/// Full-screen ringtone maker: pauses the music, prepares the song
/// (downloads Discover songs automatically), lets the user pick the start
/// and end, preview, name and save it, then set it as the phone sound.
class RingtoneEditorScreen extends StatefulWidget {
  const RingtoneEditorScreen({super.key, required this.song, this.initialPosition});

  final Song song;
  final Duration? initialPosition;

  @override
  State<RingtoneEditorScreen> createState() => _RingtoneEditorScreenState();
}

class _RingtoneEditorScreenState extends State<RingtoneEditorScreen> {
  late final RingtoneEditorCubit _cubit;
  late final RingtonePreview _preview;
  late final TextEditingController _name;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _previewing = false;
  Duration _previewPosition = Duration.zero;
  bool _loadedPreview = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: '${widget.song.displayTitle} ringtone');
    _preview = RingtonePreview.factory();
    _subs.add(_preview.playingStream.listen((p) {
      if (mounted) setState(() => _previewing = p);
    }));
    _subs.add(_preview.positionStream.listen((p) {
      if (mounted && _previewing) setState(() => _previewPosition = p);
    }));
    _cubit = RingtoneEditorCubit(
      song: widget.song,
      service: getIt<RingtoneService>(),
      library: context.read<RingtoneLibraryBloc>(),
      initialPosition: widget.initialPosition,
    );
    // Stop the music so the preview can be heard.
    try {
      context.read<MusicBloc>().pauseIfPlaying();
    } catch (_) {}
    _cubit.prepare();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _preview.dispose();
    _cubit.close();
    _name.dispose();
    super.dispose();
  }

  Future<void> _onState(RingtoneEditorState state) async {
    if (state.phase == RingtoneEditorPhase.ready && !_loadedPreview && state.sourcePath != null) {
      _loadedPreview = true;
      try {
        final length = await _preview.load(state.sourcePath!);
        if (length != null) _cubit.lengthDetected(length);
      } catch (_) {
        // Preview is optional; cutting still works.
      }
    }
    if (state.phase == RingtoneEditorPhase.saving || state.phase == RingtoneEditorPhase.saved) {
      if (_previewing) await _preview.stop();
    }
  }

  Future<void> _togglePreview(RingtoneEditorState state) async {
    if (_previewing) {
      await _preview.stop();
    } else {
      setState(() => _previewPosition = Duration.zero);
      try {
        await _preview.play(start: state.start, end: state.end);
      } catch (_) {}
    }
  }

  Future<void> _stopPreviewThen(VoidCallback action) async {
    if (_previewing) await _preview.stop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RingtoneEditorCubit, RingtoneEditorState>(
        listener: (context, state) => _onState(state),
        builder: (context, state) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: context.backgroundGradient),
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(saved: state.phase == RingtoneEditorPhase.saved),
                    _SongHeader(song: widget.song),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: switch (state.phase) {
                            RingtoneEditorPhase.preparing => _Preparing(
                              key: const ValueKey('ringtone_preparing'),
                              state: state,
                              online: widget.song.isOnline,
                            ),
                            RingtoneEditorPhase.error => _ErrorView(
                              key: const ValueKey('ringtone_error'),
                              message: state.error ?? 'Something went wrong',
                              canRetry: RingtoneService.unavailableReason(widget.song) == null,
                              onRetry: _cubit.prepare,
                            ),
                            RingtoneEditorPhase.saved => _SavedView(
                              key: const ValueKey('ringtone_saved'),
                              item: state.saved!,
                            ),
                            _ => _TrimView(
                              key: const ValueKey('ringtone_trim'),
                              state: state,
                              name: _name,
                              previewing: _previewing,
                              previewPosition: _previewPosition,
                              onPreview: () => _togglePreview(state),
                              onChangeRange: (values) => _stopPreviewThen(() {
                                if (values.start != state.start) _cubit.setStart(values.start);
                                if (values.end != state.end) _cubit.setEnd(values.end);
                              }),
                              onSave: () => _stopPreviewThen(() {
                                FocusScope.of(context).unfocus();
                                _cubit.save(_name.text);
                              }),
                            ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.saved});
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('ringtone_close'),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(CupertinoIcons.xmark, color: context.onSurfaceColor),
          ),
          Expanded(
            child: Text(
              saved ? 'Ringtone saved' : 'Create ringtone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: OnlineArtwork(url: song.albumArt, icon: CupertinoIcons.music_note, radius: 12.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  song.displayArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({super.key, required this.state, required this.online});
  final RingtoneEditorState state;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          SizedBox(
            width: 64.r,
            height: 64.r,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              value: online && progress != null && progress > 0 ? progress : null,
              color: context.primaryStart,
              backgroundColor: context.onSurfaceColor.withValues(alpha: 0.08),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            online ? 'Getting the song ready…' : 'Opening song…',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            online
                ? 'Downloading from Discover${progress != null && progress > 0 ? ' · ${(progress * 100).round()}%' : ''}'
                : 'This only takes a moment',
            key: const ValueKey('ringtone_progress_text'),
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.canRetry, required this.onRetry});
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 50.h),
      child: Column(
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 52.sp, color: context.onSurfaceVariantColor),
          SizedBox(height: 14.h),
          Text(
            message,
            key: const ValueKey('ringtone_error_text'),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurfaceColor, fontSize: 14.sp, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 20.h),
          if (canRetry)
            GradientButton(
              key: const ValueKey('ringtone_retry'),
              label: 'Try again',
              icon: CupertinoIcons.refresh,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

class _TrimView extends StatelessWidget {
  const _TrimView({
    super.key,
    required this.state,
    required this.name,
    required this.previewing,
    required this.previewPosition,
    required this.onPreview,
    required this.onChangeRange,
    required this.onSave,
  });

  final RingtoneEditorState state;
  final TextEditingController name;
  final bool previewing;
  final Duration previewPosition;
  final VoidCallback onPreview;
  final ValueChanged<({Duration start, Duration end})> onChangeRange;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RingtoneEditorCubit>();
    final saving = state.phase == RingtoneEditorPhase.saving;
    final total = state.songLength > Duration.zero ? state.songLength : state.end;
    final maxMs = total.inMilliseconds.toDouble().clamp(1000.0, double.infinity);
    final error = state.selectionError;
    final previewFraction = state.length.inMilliseconds == 0
        ? 0.0
        : (previewPosition.inMilliseconds / state.length.inMilliseconds).clamp(0.0, 1.0);

    Duration ms(double v) => Duration(milliseconds: v.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.h),
        Center(
          child: Text(
            formatClock(state.length, tenths: true),
            key: const ValueKey('ringtone_length'),
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Center(
          child: Text(
            'selected · up to ${RingtoneService.maxLength.inSeconds} s',
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
        ),
        SizedBox(height: 18.h),
        _Waveform(
          start: state.start.inMilliseconds / maxMs,
          end: state.end.inMilliseconds / maxMs,
          seed: cubit.song.id.hashCode,
          playhead: previewing
              ? (state.start.inMilliseconds + previewFraction * state.length.inMilliseconds) / maxMs
              : null,
        ),
        RangeSlider(
          key: const ValueKey('ringtone_range'),
          min: 0,
          max: maxMs,
          values: RangeValues(
            state.start.inMilliseconds.toDouble().clamp(0, maxMs),
            state.end.inMilliseconds.toDouble().clamp(0, maxMs),
          ),
          activeColor: context.primaryStart,
          inactiveColor: context.onSurfaceColor.withValues(alpha: 0.12),
          onChanged: saving ? null : (v) => onChangeRange((start: ms(v.start), end: ms(v.end))),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0:00', style: _small(context)),
              Text(formatClock(total), style: _small(context)),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _TimeAdjuster(
                label: 'Start',
                keyPrefix: 'start',
                value: state.start,
                enabled: !saving,
                onMinus: () => cubit.nudgeStart(-1),
                onPlus: () => cubit.nudgeStart(1),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _TimeAdjuster(
                label: 'End',
                keyPrefix: 'end',
                value: state.end,
                enabled: !saving,
                onMinus: () => cubit.nudgeEnd(-1),
                onPlus: () => cubit.nudgeEnd(1),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Center(
          child: FilledButton.tonalIcon(
            key: const ValueKey('ringtone_preview'),
            onPressed: saving || error != null ? null : onPreview,
            icon: Icon(previewing ? CupertinoIcons.stop_fill : CupertinoIcons.play_fill),
            label: Text(previewing ? 'Stop preview' : 'Preview'),
          ),
        ),
        SizedBox(height: 18.h),
        TextField(
          key: const ValueKey('ringtone_name'),
          controller: name,
          enabled: !saving,
          maxLength: RingtoneService.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: context.onSurfaceColor),
          decoration: InputDecoration(
            labelText: 'Ringtone name',
            labelStyle: TextStyle(color: context.onSurfaceVariantColor),
            prefixIcon: Icon(CupertinoIcons.pencil, color: context.onSurfaceVariantColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
        if (error != null || state.saveError != null)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              state.saveError ?? error!,
              key: const ValueKey('ringtone_inline_error'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.sp),
            ),
          ),
        GradientButton(
          key: const ValueKey('ringtone_save'),
          label: saving ? 'Saving…' : 'Save ringtone',
          icon: CupertinoIcons.checkmark_alt,
          onPressed: state.canSave ? onSave : null,
        ),
      ],
    );
  }

  TextStyle _small(BuildContext context) =>
      TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp, fontFamily: 'Poppins');
}

class _TimeAdjuster extends StatelessWidget {
  const _TimeAdjuster({
    required this.label,
    required this.keyPrefix,
    required this.value,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String keyPrefix;
  final Duration value;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: ValueKey('${keyPrefix}_minus'),
                tooltip: '$label −0.5 s',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onMinus : null,
                icon: Icon(CupertinoIcons.minus_circle, color: context.primaryStart),
              ),
              Flexible(
                child: FittedBox(
                  child: Text(
                    formatClock(value, tenths: true),
                    key: ValueKey('${keyPrefix}_value'),
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('${keyPrefix}_plus'),
                tooltip: '$label +0.5 s',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onPlus : null,
                icon: Icon(CupertinoIcons.plus_circle, color: context.primaryStart),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative bars with the selected part highlighted.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.start, required this.end, required this.seed, this.playhead});
  final double start;
  final double end;
  final int seed;
  final double? playhead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      child: CustomPaint(
        size: Size.infinite,
        painter: _WavePainter(
          start: start,
          end: end,
          seed: seed,
          playhead: playhead,
          active: context.primaryStart,
          inactive: context.onSurfaceColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.start,
    required this.end,
    required this.seed,
    required this.active,
    required this.inactive,
    this.playhead,
  });

  final double start;
  final double end;
  final int seed;
  final double? playhead;
  final Color active;
  final Color inactive;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 64;
    final gap = size.width / bars;
    final paint = Paint()..strokeCap = StrokeCap.round;
    var x = seed & 0x7fffffff;
    for (var i = 0; i < bars; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      final f = i / bars;
      final h = size.height * (0.25 + 0.75 * ((x % 1000) / 1000) * (0.6 + 0.4 * (1 - (2 * f - 1).abs())));
      final selected = f >= start && f <= end;
      final played = playhead != null && f <= playhead! && selected;
      paint
        ..color = played ? active.withValues(alpha: 0.55) : (selected ? active : inactive)
        ..strokeWidth = gap * 0.55;
      final cx = gap * (i + 0.5);
      canvas.drawLine(Offset(cx, (size.height - h) / 2), Offset(cx, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.start != start || old.end != end || old.playhead != playhead || old.active != active;
}

class _SavedView extends StatelessWidget {
  const _SavedView({super.key, required this.item});
  final RingtoneItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Column(
        children: [
          Container(
            width: 76.r,
            height: 76.r,
            decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 40.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            item.name,
            key: const ValueKey('ringtone_saved_name'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${formatClock(item.duration, tenths: true)} · saved to My Ringtones',
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 24.h),
          Text(
            'Use it as',
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 8.h),
          SetAsButtons(item: item),
          SizedBox(height: 28.h),
          GradientButton(
            key: const ValueKey('ringtone_open_list'),
            label: 'Open My Ringtones',
            icon: CupertinoIcons.bell,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MyRingtonesScreen()),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            key: const ValueKey('ringtone_done'),
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
