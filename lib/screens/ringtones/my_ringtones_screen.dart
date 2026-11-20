import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/injection.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/widgets/app_custom.dart';
import '../../utils/models/ringtone/ringtone_model.dart';
import '../../utils/services/ringtone/ringtone_service.dart';
import '../bottom_tab/bloc/music_bloc.dart';
import '../online/widgets/online_widgets.dart' show OnlineArtwork;
import 'bloc/ringtone_library_bloc.dart';
import 'ringtone_actions.dart';
import 'ringtone_preview.dart';

/// "My Ringtones": every ringtone the user made, like a song list. Tap to
/// preview; the menu sets it as ringtone / notification / alarm, renames,
/// shares or deletes it.
class MyRingtonesScreen extends StatefulWidget {
  const MyRingtonesScreen({super.key});

  @override
  State<MyRingtonesScreen> createState() => _MyRingtonesScreenState();
}

class _MyRingtonesScreenState extends State<MyRingtonesScreen> {
  late final RingtonePreview _preview;
  StreamSubscription<bool>? _sub;
  String? _playingId;

  /// True while a new preview is starting: the "stopped" event of the
  /// previous one must not clear the new row.
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _preview = RingtonePreview.factory();
    _sub = _preview.playingStream.listen((playing) {
      if (!playing && !_starting && mounted && _playingId != null) {
        setState(() => _playingId = null);
      }
    });
    context.read<RingtoneLibraryBloc>().add(const RingtoneLibraryEvent.verify());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _preview.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(RingtoneItem item) async {
    if (_playingId == item.id) {
      await _preview.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      context.read<MusicBloc>().pauseIfPlaying();
    } catch (_) {}
    setState(() => _playingId = item.id);
    _starting = true;
    try {
      await _preview.stop();
      await _preview.load(item.path.isNotEmpty ? item.path : item.uri!);
      await _preview.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingId = null);
      AppCustom.error(context, 'Could not play this ringtone');
    } finally {
      // Let the pending "stopped" event of the previous preview pass.
      Future<void>.delayed(const Duration(milliseconds: 300), () => _starting = false);
    }
  }

  Future<void> _rename(RingtoneItem item) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: item.name),
    );
    if (name == null || !mounted) return;
    final bloc = context.read<RingtoneLibraryBloc>();
    final clean = RingtoneService.sanitizeName(name, fallback: item.name);
    if (clean == item.name) return;
    final unique = RingtoneService.uniqueName(clean, bloc.state.names.where((n) => n != item.name));
    try {
      if (_playingId == item.id) await _preview.stop();
      final updated = await getIt<RingtoneService>().rename(item, unique);
      bloc.add(RingtoneLibraryEvent.updated(updated));
      if (mounted) AppCustom.success(context, 'Renamed to "${updated.name}"');
    } on RingtoneException catch (e) {
      if (mounted) AppCustom.error(context, e.message);
    }
  }

  Future<void> _delete(RingtoneItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('delete_dialog'),
        backgroundColor: ctx.cardColor,
        title: Text('Delete ringtone?', style: TextStyle(color: ctx.onSurfaceColor)),
        content: Text(
          '"${item.name}" will be removed from your phone. The original song is not affected.',
          style: TextStyle(color: ctx.onSurfaceVariantColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            key: const ValueKey('delete_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final bloc = context.read<RingtoneLibraryBloc>();
    try {
      if (_playingId == item.id) await _preview.stop();
      await getIt<RingtoneService>().delete(item);
      bloc.add(RingtoneLibraryEvent.removed(item.id));
      if (mounted) AppCustom.success(context, 'Ringtone deleted');
    } on RingtoneException catch (e) {
      if (mounted) AppCustom.error(context, e.message);
    }
  }

  Future<void> _share(RingtoneItem item) async {
    if (item.path.isEmpty) {
      AppCustom.info(context, 'This ringtone can\'t be shared');
      return;
    }
    await Share.shareXFiles([XFile(item.path)], text: item.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<RingtoneLibraryBloc, RingtoneLibraryState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 8.h),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(CupertinoIcons.back, color: context.onSurfaceColor),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Ringtones',
                                  style: TextStyle(
                                    color: context.onSurfaceColor,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  '${state.count} ringtone${state.count == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: context.onSurfaceVariantColor,
                                    fontSize: 12.sp,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Empty(key: const ValueKey('ringtones_empty')),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 120.h),
                      sliver: SliverList.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, i) {
                          final item = state.items[i];
                          return RingtoneTile(
                            key: ValueKey('ringtone_${item.id}'),
                            item: item,
                            uses: state.usesOf(item.id),
                            playing: _playingId == item.id,
                            onTap: () => _togglePlay(item),
                            onAction: (action) async {
                              switch (action) {
                                case 'rename':
                                  await _rename(item);
                                case 'delete':
                                  await _delete(item);
                                case 'share':
                                  await _share(item);
                                default:
                                  final use = RingtoneUse.values.where((u) => u.name == action);
                                  if (use.isNotEmpty) await setRingtoneAs(context, item, use.first);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class RingtoneTile extends StatelessWidget {
  const RingtoneTile({
    super.key,
    required this.item,
    required this.uses,
    required this.playing,
    required this.onTap,
    required this.onAction,
  });

  final RingtoneItem item;
  final List<RingtoneUse> uses;
  final bool playing;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: playing ? context.primaryStart.withValues(alpha: 0.10) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48.r,
                height: 48.r,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OnlineArtwork(url: item.albumArt, icon: CupertinoIcons.bell_fill, radius: 10.r),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        playing ? CupertinoIcons.stop_fill : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: playing ? context.primaryStart : context.onSurfaceColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      [
                        formatClock(item.duration, tenths: true),
                        item.songTitle,
                        if (uses.isNotEmpty) uses.map((u) => u.label).join(', '),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 11.sp, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
              if (uses.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(CupertinoIcons.checkmark_seal_fill, size: 16.sp, color: context.primaryStart),
                ),
              PopupMenuButton<String>(
                key: ValueKey('ringtone_menu_${item.id}'),
                tooltip: 'More',
                icon: Icon(CupertinoIcons.ellipsis_vertical, size: 18.sp, color: context.onSurfaceVariantColor),
                onSelected: onAction,
                itemBuilder: (_) => [
                  for (final use in RingtoneUse.values)
                    PopupMenuItem(value: use.name, child: Text('Set as ${use.label.toLowerCase()}')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84.r,
            height: 84.r,
            decoration: BoxDecoration(gradient: context.primaryGradient, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 38.sp),
          ),
          SizedBox(height: 18.h),
          Text(
            'No ringtones yet',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'While a song plays, open the player and tap the bell to cut your favourite part.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 12.sp, fontFamily: 'Poppins'),
          ),
          SizedBox(height: 120.h),
        ],
      ),
    );
  }
}

/// Owns its text controller so it outlives the closing animation.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});
  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('rename_dialog'),
      backgroundColor: context.cardColor,
      title: Text('Rename ringtone', style: TextStyle(color: context.onSurfaceColor)),
      content: TextField(
        key: const ValueKey('rename_field'),
        controller: _controller,
        autofocus: true,
        maxLength: RingtoneService.maxNameLength,
        style: TextStyle(color: context.onSurfaceColor),
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          key: const ValueKey('rename_save'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
