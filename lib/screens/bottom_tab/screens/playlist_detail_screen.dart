import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../utils/logger/logger.dart';
import '../../../utils/models/playlist_source/playlist_source_model.dart';
import '../../../utils/models/song/song_model.dart';
import 'bloc/music_bloc.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_list_item.dart';

enum PlaylistDetailType {
  album,
  artist,
  playlist,
}

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistDetailType type;
  final String id;
  final String name;
  final String? description;
  final String? year;
  final String? bio;
  final int songCount;
  final int? albumCount;

  const PlaylistDetailScreen({
    super.key,
    required this.type,
    required this.id,
    required this.name,
    this.description,
    this.year,
    this.bio,
    required this.songCount,
    this.albumCount,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final AppLogger _logger = AppLogger('PlaylistDetailScreen');
  final TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];
  String? _immediatelySelectedSongId;

  @override
  void initState() {
    super.initState();
    _logger.i('PlaylistDetailScreen initialized for ${widget.type.name}: ${widget.name}');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update selected song when dependencies change
    final musicState = context.read<MusicBloc>().state;
    final newSongId = musicState.myPlayerState.currentSongId;
    
    if (newSongId != _immediatelySelectedSongId) {
      _logger.i(
        '🔄 Updating selected song ID on dependency change: $newSongId (was: $_immediatelySelectedSongId)',
      );
      setState(() {
        _immediatelySelectedSongId = newSongId;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredSongs = _getSongsFromSource();
      } else {
        _filteredSongs = _getSongsFromSource()
            .where((song) => 
                song.title.toLowerCase().contains(query) ||
                song.artists.any((artist) => artist.toLowerCase().contains(query)) ||
                song.albums.any((album) => album.toLowerCase().contains(query)))
            .toList();
      }
    });
  }

  List<Song> _getSongsFromSource() {
    final state = context.read<MusicBloc>().state;
    
    switch (widget.type) {
      case PlaylistDetailType.album:
        return state.allSongs
            .where((song) => song.albums.any((album) => album == widget.name))
            .toList();
      case PlaylistDetailType.artist:
        return state.allSongs
            .where((song) => song.artists.any((artist) => artist == widget.name))
            .toList();
      case PlaylistDetailType.playlist:
        final playlist = state.myPlaylist.firstWhere(
          (p) => p.id == widget.id,
          orElse: () => throw Exception('Playlist not found'),
        );
        return state.allSongs
            .where((song) => playlist.songIds.contains(song.id))
            .toList();
    }
  }

  PlaylistSource _getPlaylistSource() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return PlaylistSource.album(widget.id);
      case PlaylistDetailType.artist:
        return PlaylistSource.artist(widget.id);
      case PlaylistDetailType.playlist:
        return PlaylistSource.myPlaylist(widget.id);
    }
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return 'Album';
      case PlaylistDetailType.artist:
        return 'Artist';
      case PlaylistDetailType.playlist:
        return 'Playlist';
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case PlaylistDetailType.album:
        return Icons.album_rounded;
      case PlaylistDetailType.artist:
        return Icons.person_rounded;
      case PlaylistDetailType.playlist:
        return Icons.queue_music_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<MusicBloc, MusicState>(
            builder: (context, state) {
              // Update filtered songs when state changes
              if (_filteredSongs.isEmpty) {
                _filteredSongs = _getSongsFromSource();
              }

              return CustomScrollView(
                slivers: [
                  // App Bar with Hero Image
                  SliverAppBar(
                    expandedHeight: 280.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: context.primaryGradient,
                        ),
                        child: Stack(
                          children: [
                            // Background Pattern
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      context.primaryStart.withValues(alpha: 0.3),
                                      context.primaryEnd.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Type Badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20.r),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getTypeIcon(),
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            _getTypeTitle(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    // Title
                                    Text(
                                      widget.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.h),
                                    // Description/Bio
                                    if (widget.description?.isNotEmpty == true || widget.bio?.isNotEmpty == true)
                                      Text(
                                        widget.description ?? widget.bio ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14.sp,
                                          fontFamily: 'Poppins',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    SizedBox(height: 12.h),
                                    // Stats Row
                                    Row(
                                      children: [
                                        _buildStatItem(
                                          icon: Icons.music_note_rounded,
                                          label: '${widget.songCount} songs',
                                        ),
                                        if (widget.albumCount != null) ...[
                                          SizedBox(width: 24.w),
                                          _buildStatItem(
                                            icon: Icons.album_rounded,
                                            label: '${widget.albumCount} albums',
                                          ),
                                        ],
                                        if (widget.year != null) ...[
                                          SizedBox(width: 24.w),
                                          _buildStatItem(
                                            icon: Icons.calendar_today_rounded,
                                            label: widget.year!,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: GlassCard(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: context.onSurfaceColor),
                          decoration: InputDecoration(
                            hintText: 'Search songs...',
                            hintStyle: TextStyle(
                              color: context.onSurfaceVariantColor,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: context.onSurfaceVariantColor,
                              size: 20.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Play All Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: GlassCard(
                        child: ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              gradient: context.primaryGradient,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                          title: Text(
                            'Play All',
                            style: TextStyle(
                              color: context.onSurfaceColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            'Play all ${widget.songCount} songs',
                            style: TextStyle(
                              color: context.onSurfaceVariantColor,
                              fontSize: 14.sp,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          trailing: Icon(
                            Icons.shuffle_rounded,
                            color: context.onSurfaceVariantColor,
                            size: 20.sp,
                          ),
                          onTap: () {
                            _playAllSongs();
                          },
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                  // Songs List
                  if (_filteredSongs.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.w),
                          child: Column(
                            children: [
                              Icon(
                                Icons.music_off_rounded,
                                color: context.onSurfaceVariantColor,
                                size: 48.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No songs found',
                                style: TextStyle(
                                  color: context.onSurfaceVariantColor,
                                  fontSize: 16.sp,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = _filteredSongs[index];
                            final isSelected = song.id == _immediatelySelectedSongId;
                            
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                            child: SongListItem(
                              songTitle: song.title,
                              artistName: song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist',
                              albumName: song.albums.isNotEmpty ? song.albums.first : 'Unknown Album',
                              duration: song.duration,
                              songId: song.id,
                              isImmediatelySelected: isSelected,
                              onTap: () {
                                _playSong(song);
                              },
                              onOpenMusicPlayer: () {
                                _playSong(song);
                              },
                            ),
                            );
                          },
                          childCount: _filteredSongs.length,
                        ),
                      ),
                    ),

                  // Bottom padding for navigation
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 16.sp,
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  void _playSong(Song song) {
    _logger.i("🎵 Playing song: ${song.title}");
    
    // Immediately update selected song for instant feedback
    setState(() {
      _immediatelySelectedSongId = song.id;
    });

    // Play the song
    context.read<MusicBloc>().add(
      MusicEvent.playOrPauseSong(
        songId: song.id,
        currentPlayList: _filteredSongs.map((s) => s.id).toList(),
        playlistSource: _getPlaylistSource(),
      ),
    );
  }

  void _playAllSongs() {
    if (_filteredSongs.isNotEmpty) {
      _logger.i("🎵 Playing all songs from ${widget.name}");
      
      final songIds = _filteredSongs.map((song) => song.id).toList();
      context.read<MusicBloc>().add(
        MusicEvent.playOrPauseSong(
          songId: songIds.first,
          currentPlayList: songIds,
          playlistSource: _getPlaylistSource(),
        ),
      );
    }
  }
}
