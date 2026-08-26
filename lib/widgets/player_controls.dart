import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import 'sleep_timer_dialog.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatTimerTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final currentSong = playerService.currentSong;
    final isFav = currentSong != null && playerService.isFavorite(currentSong.path);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Currently Playing Info & Action Icons (Favorite & Sleep Timer)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong?.title ?? 'Chưa chọn bài hát',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentSong?.artist ?? 'Nhấn "Chọn File" hoặc "Chọn Folder"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite Heart Button
              if (currentSong != null)
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? const Color(0xFFE94057) : Colors.white54,
                    size: 24,
                  ),
                  onPressed: () => playerService.toggleFavorite(currentSong.path),
                  tooltip: isFav ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                ),

              // Sleep Timer Button
              IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: playerService.isTimerActive
                          ? const Color(0xFFFF5252)
                          : Colors.white54,
                      size: 24,
                    ),
                    if (playerService.isTimerActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const SleepTimerDialog(),
                  );
                },
                tooltip: 'Hẹn giờ tắt nhạc',
              ),
            ],
          ),

          if (playerService.isTimerActive)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
                ),
                child: Text(
                  'Hẹn giờ: Tự động tắt sau ${_formatTimerTime(playerService.remainingTimerSeconds)}',
                  style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Seekbar & Time indicators
          StreamBuilder<Duration>(
            stream: playerService.positionStream,
            builder: (context, snapshotPosition) {
              final position = snapshotPosition.data ?? Duration.zero;

              return StreamBuilder<Duration?>(
                stream: playerService.durationStream,
                builder: (context, snapshotDuration) {
                  final duration = snapshotDuration.data ?? Duration.zero;

                  double maxVal = duration.inMilliseconds.toDouble();
                  double currentVal = position.inMilliseconds.toDouble();
                  if (currentVal > maxVal) currentVal = maxVal;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: const Color(0xFFE94057),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFFE94057),
                        ),
                        child: Slider(
                          value: maxVal > 0 ? currentVal : 0.0,
                          max: maxVal > 0 ? maxVal : 1.0,
                          onChanged: (val) {
                            playerService.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 6),

          // Media Control Buttons (Shuffle, Prev, Play/Pause, Next, Repeat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle Toggle Button
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: playerService.isShuffleEnabled
                      ? const Color(0xFFE94057)
                      : Colors.white38,
                  size: 22,
                ),
                onPressed: playerService.toggleShuffle,
                tooltip: 'Trộn bài hát',
              ),

              // Previous Track Button
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
                onPressed: playerService.playlist.isEmpty
                    ? null
                    : () => playerService.previous(),
                tooltip: 'Bài trước',
              ),

              // Play / Pause Button
              StreamBuilder<PlayerState>(
                stream: playerService.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.playing ?? false;

                  return GestureDetector(
                    onTap: playerService.playlist.isEmpty
                        ? null
                        : () => playerService.playPause(),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE94057), Color(0xFFF27121)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE94057).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  );
                },
              ),

              // Next Track Button
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                onPressed: playerService.playlist.isEmpty
                    ? null
                    : () => playerService.next(),
                tooltip: 'Bài tiếp theo',
              ),

              // Repeat Toggle Button
              IconButton(
                icon: Icon(
                  playerService.loopMode == CustomLoopMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: playerService.loopMode != CustomLoopMode.off
                      ? const Color(0xFFE94057)
                      : Colors.white38,
                  size: 22,
                ),
                onPressed: playerService.toggleLoopMode,
                tooltip: 'Chế độ lặp lại',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
