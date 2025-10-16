import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/widgets/app_custom.dart';
import '../../utils/logger/logger.dart';
import '../../utils/services/song_features/comprehensive_features_extractor.dart';
import '../../utils/models/song/song_model.dart';
import '../bottom_tab/bloc/music_bloc.dart';

class ComprehensiveFeaturesSettingsScreen extends StatefulWidget {
  const ComprehensiveFeaturesSettingsScreen({super.key});

  @override
  State<ComprehensiveFeaturesSettingsScreen> createState() => _ComprehensiveFeaturesSettingsScreenState();
}

class _ComprehensiveFeaturesSettingsScreenState extends State<ComprehensiveFeaturesSettingsScreen> {
  static final AppLogger _logger = AppLogger('ComprehensiveFeaturesSettings');

  @override
  Widget build(BuildContext context) {
    _logger.d('Building ComprehensiveFeaturesSettingsScreen');
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final allSongs = state.allSongs;
        final progress = ComprehensiveFeaturesExtractor.getExtractionProgress(
          allSongs,
        );
        final stats = _calculateStatistics(allSongs);
        final isLoading = state.isComprehensiveFeaturesExtractingLoading;
        
        _logger.d('Screen state - Songs: ${allSongs.length}, Progress: ${progress['completionPercentage']}%, Loading: $isLoading');
        _logger.d('FEature of Song ${allSongs[0].features}');

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: _buildAppBar(context, isLoading),
          body: RefreshIndicator(
            onRefresh: () async {},
            color: context.primaryStart,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildStatusSection(context: context),
                SizedBox(height: 12.h),
                _buildProgressSection(context: context, progress: progress),
                SizedBox(height: 12.h),
                _buildStatisticsSection(
                  context: context,
                  stats: stats,
                  progress: progress,
                ),
                SizedBox(height: 12.h),
                _buildGenreDistributionSection(
                  context: context,
                  genreDistribution:
                      stats['genreDistribution'] as Map<String, int>,
                ),
                SizedBox(height: 12.h),
                _buildActionsSection(
                  context: context,
                  isLoading: isLoading,
                ),
                SizedBox(height: 12.h),
                _buildInfoSection(context: context),
              ],
            ),
          ),
        );
      },
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLoading) {
    return AppBar(
      title: Text(
        'Music Features Analysis',
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.onSurfaceColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.primaryStart,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSection({required BuildContext context}) {
    final isInitialized = ComprehensiveFeaturesExtractor.isInitialized;
    return _buildCard(
      context: context,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: (isInitialized ? Colors.green : Colors.orange).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isInitialized
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: isInitialized ? Colors.green : Colors.orange,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isInitialized ? 'Ready' : 'Not Initialized',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required BuildContext context,
    required Map<String, dynamic> progress,
  }) {
    final percentage = progress['completionPercentage'] as double? ?? 0.0;
    final analyzed = progress['analyzedSongs'] as int? ?? 0;
    final total = progress['totalSongs'] as int? ?? 0;
    final pending = progress['pendingSongs'] as int? ?? 0;

    return _buildCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Progress',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: context.onSurfaceColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '$analyzed of $total songs analyzed',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.onSurfaceVariantColor,
            ),
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: context.outlineColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(percentage),
            ),
            minHeight: 8.h,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Completion',
                  '${percentage.toStringAsFixed(1)}%',
                  Icons.analytics_rounded,
                  _getProgressColor(percentage),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatRow(
                  'Pending',
                  '$pending',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection({
    required BuildContext context,
    required Map<String, dynamic> stats,
    required Map<String, dynamic> progress,
  }) {
    final avgEnergy = stats['averageEnergy'] as double? ?? 0.0;
    final avgTempo = stats['averageTempo'] as double? ?? 0.0;
    final hasVocals = stats['hasVocalsCount'] as int? ?? 0;
    final analyzed = progress['analyzedSongs'] as int? ?? 0;
    return _buildCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Music Statistics',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: context.onSurfaceColor,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Avg Energy',
                  avgEnergy.toStringAsFixed(2),
                  Icons.bolt_rounded,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatRow(
                  'Avg Tempo',
                  '${avgTempo.toStringAsFixed(0)} BPM',
                  Icons.speed_rounded,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatRow(
                  'Vocals',
                  '$hasVocals/$analyzed',
                  Icons.mic_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreDistributionSection({
    required BuildContext context,
    required Map<String, int> genreDistribution,
  }) {
    if (genreDistribution.isEmpty) {
      return _buildCard(
        context: context,
        child: Text(
          "No genre data available. Run analysis to see genre distribution.",
          style: TextStyle(
            color: context.onSurfaceVariantColor,
            fontSize: 13.sp,
          ),
        ),
      );
    }

    final topGenres = genreDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayedGenres = topGenres.take(5).toList();

    return _buildCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Genres',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: context.onSurfaceColor,
            ),
          ),
          SizedBox(height: 12.h),
          ...displayedGenres.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.onSurfaceColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryStart.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: context.primaryStart,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection({
    required BuildContext context,
    bool? isLoading = false,
  }) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.analytics_rounded,
          title: 'Analyze All Songs',
          subtitle: 'Extract features from all songs in library',
          onTap: () async {
            final confirmed = await AppCustom.showConfirm(
              context: context,
              title: 'Analyze All Songs',
              message: 'This will analyze all songs in your library. This may take a while. Continue?',
              confirmText: 'Analyze',
              confirmColor: context.primaryStart,
              icon: Icons.analytics_rounded,
            );
            if (confirmed == true) {
              try {
                _logger.i('Starting comprehensive features analysis for all songs');
                context.read<MusicBloc>().add(
                  const MusicEvent.extractComprehensiveFeatures(isForce: false),
                );
                AppCustom.showSuccessToast(
                  context: context,
                  message: 'Analysis started successfully',
                );
              } catch (e) {
                _logger.e('Failed to start analysis', error: e);
                AppCustom.showErrorToast(
                  context: context,
                  message: 'Failed to start analysis: $e',
                );
              }
            }
          },
          color: context.primaryStart,
          isEnabled: !(isLoading == true),
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          icon: Icons.refresh_rounded,
          title: 'Refresh Pending Songs',
          subtitle: 'Analyze only songs without features',
          onTap: () async {
            try {
              _logger.i('Refreshing pending songs analysis');
              context.read<MusicBloc>().add(
                const MusicEvent.extractComprehensiveFeatures(isForce: false),
              );
              AppCustom.showInfoToast(
                context: context,
                message: 'Refreshing pending songs...',
              );
            } catch (e) {
              _logger.e('Failed to refresh pending songs', error: e);
              AppCustom.showErrorToast(
                context: context,
                message: 'Failed to refresh: $e',
              );
            }
          },
          color: Colors.blue,
          isEnabled: !(isLoading == true),
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          icon: Icons.update_rounded,
          title: 'Force Re-analyze All',
          subtitle: 'Re-extract features for all songs',
          onTap: () async {
            final confirmed = await AppCustom.showConfirm(
              context: context,
              title: 'Force Re-analyze All',
              message: 'This will re-extract features for all songs, even those already analyzed. Continue?',
              confirmText: 'Re-analyze',
              confirmColor: Colors.orange,
              icon: Icons.update_rounded,
            );
            if (confirmed == true) {
              try {
                _logger.i('Starting force re-analysis: clearing all features first');
                
                // Step 1: Clear all existing features
                final musicBloc = context.read<MusicBloc>();
                final currentState = musicBloc.state;
                final clearedSongs = currentState.allSongs.map((song) {
                  return song.copyWith(features: null);
                }).toList();
                
                // Update state with cleared features
                musicBloc.add(
                  MusicEvent.updateMusicBlocState(
                    newState: currentState.copyWith(allSongs: clearedSongs),
                  ),
                );
                
                _logger.i('Cleared features from ${clearedSongs.length} songs');
                AppCustom.showInfoToast(
                  context: context,
                  message: 'Features cleared, starting re-analysis...',
                );
                
                // Step 2: Start fresh extraction for all songs
                musicBloc.add(
                  const MusicEvent.extractComprehensiveFeatures(isForce: false),
                );
                
                AppCustom.showSuccessToast(
                  context: context,
                  message: 'Force re-analysis started successfully',
                );
              } catch (e) {
                _logger.e('Failed to start force re-analysis', error: e);
                AppCustom.showErrorToast(
                  context: context,
                  message: 'Failed to start re-analysis: $e',
                );
              }
            }
          },
          color: Colors.orange,
          isEnabled: !(isLoading == true),
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          icon: Icons.delete_sweep_rounded,
          title: 'Clear All Features',
          subtitle: 'Remove all extracted features',
          onTap: () async {
            final confirmed = await AppCustom.showDeleteConfirm(
              context: context,
              itemName: 'All Features',
              customMessage: 'This will remove all extracted features. You will need to re-analyze.',
            );
            if (confirmed == true) {
              try {
                _logger.i('Clearing all features from songs');
                final musicBloc = context.read<MusicBloc>();
                final currentState = musicBloc.state;
                final updatedSongs = currentState.allSongs.map((song) {
                  final updatedSong = song.copyWith(features: null);
                  return updatedSong;
                }).toList();
                
                musicBloc.add(
                  MusicEvent.updateMusicBlocState(
                    newState: currentState.copyWith(allSongs: updatedSongs),
                  ),
                );
                _logger.i('Successfully cleared features from ${updatedSongs.length} songs');
                AppCustom.showSuccessToast(
                  context: context,
                  message: 'All features cleared successfully',
                );
              } catch (e) {
                _logger.e('Failed to clear features', error: e);
                AppCustom.showErrorToast(
                  context: context,
                  message: 'Failed to clear features: $e',
                );
              }
            }
          },
          color: Colors.red,
          isEnabled: !(isLoading == true),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
    bool? isEnabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20.sp, color: color),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: (isEnabled == true) ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.09),
          shadowColor: Colors.transparent,
          disabledBackgroundColor: context.outlineColor.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildInfoSection({required BuildContext context}) {
    final infoList = [
      [
        'AI Analysis',
        'Uses Google\'s YAMNet AI model for instruments, vocals, and characteristics',
      ],
      [
        'Signal Processing',
        'Analyzes tempo, energy, beat, and spectral features',
      ],
      [
        'Feature Extraction',
        'Extracts 28 features incl. genre, mood, danceability',
      ],
      ['Smart Playlists', 'Creates workout, chill, and similar-song playlists'],
    ];
    return _buildCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: infoList
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: context.primaryStart.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          '${infoList.indexOf(item) + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: context.primaryStart,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item[0],
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: context.onSurfaceColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item[1],
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.onSurfaceVariantColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.outlineColor.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.onSurfaceVariantColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  static Map<String, dynamic> _calculateStatistics(List<Song> allSongs) {
    final songsWithFeatures = allSongs
        .where((s) => s.features != null)
        .toList();
    if (songsWithFeatures.isEmpty) {
      return {
        'averageEnergy': 0.0,
        'averageTempo': 0.0,
        'genreDistribution': <String, int>{},
        'moodDistribution': <String, int>{},
        'hasVocalsCount': 0,
      };
    }
    final genreCounts = <String, int>{};
    for (final song in songsWithFeatures) {
      final genre = song.features!.estimatedGenre;
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }
    final totalEnergy = songsWithFeatures.fold<double>(
      0.0,
      (sum, s) => sum + s.features!.overallEnergy,
    );
    final totalTempo = songsWithFeatures.fold<double>(
      0.0,
      (sum, s) => sum + s.features!.tempoBpm,
    );
    final hasVocalsCount = songsWithFeatures
        .where((s) => s.features!.hasVocals)
        .length;

    return {
      'averageEnergy': totalEnergy / songsWithFeatures.length,
      'averageTempo': totalTempo / songsWithFeatures.length,
      'genreDistribution': genreCounts,
      'hasVocalsCount': hasVocalsCount,
    };
  }


}
