import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final playlist = playerService.playlist;
    final currentIndex = playerService.currentIndex;
    final isScanning = playerService.isScanning;

    return Column(
      children: [
        // Action buttons: Pick Files & Pick Folder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF32384A)),
                    ),
                  ),
                  icon: isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE94057),
                          ),
                        )
                      : const Icon(Icons.audio_file, color: Color(0xFFE94057), size: 18),
                  label: Text(
                    isScanning ? 'Đang quét...' : 'Chọn File (Nhạc)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: isScanning
                      ? null
                      : () async {
                          int added = await playerService.pickFiles();
                          if (context.mounted && added > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm $added file nhạc vào danh sách'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF32384A)),
                    ),
                  ),
                  icon: isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF27121),
                          ),
                        )
                      : const Icon(Icons.folder_open, color: Color(0xFFF27121), size: 18),
                  label: Text(
                    isScanning ? 'Đang quét...' : 'Chọn Folder',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: isScanning
                      ? null
                      : () async {
                          int added = await playerService.pickFolder();
                          if (context.mounted && added > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã tìm thấy & thêm $added bài hát từ folder'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ),
              if (playlist.isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white54, size: 22),
                  tooltip: 'Xóa toàn bộ danh sách',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: isScanning ? null : () => playerService.clearPlaylist(),
                ),
              ],
            ],
          ),
        ),

        // Non-blocking scanning progress line
        if (isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFF1E222D),
              color: Color(0xFFE94057),
              minHeight: 2,
            ),
          ),

        // Playlist counter info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH PHÁT (${playlist.length})',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (playlist.isNotEmpty)
                const Text(
                  'Kéo thả để sắp xếp',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Compact Playlist List View
        Expanded(
          child: playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252A38),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.library_music_outlined,
                          size: 40,
                          color: Color(0xFFE94057),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có bài hát nào trong danh sách',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nhấn "Chọn File" hoặc "Chọn Folder" để đưa nhạc vào',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
                  itemCount: playlist.length,
                  onReorder: playerService.reorderPlaylist,
                  itemBuilder: (context, index) {
                    final song = playlist[index];
                    final isPlayingSong = (index == currentIndex);

                    return Container(
                      key: ValueKey(song.id),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isPlayingSong
                            ? const Color(0xFFE94057).withOpacity(0.18)
                            : const Color(0xFF1B1E29),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPlayingSong
                              ? const Color(0xFFE94057).withOpacity(0.6)
                              : Colors.white.withOpacity(0.04),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPlayingSong
                                ? const Color(0xFFE94057)
                                : const Color(0xFF282C3A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPlayingSong ? Icons.equalizer : Icons.music_note,
                            color: isPlayingSong ? Colors.white : Colors.white54,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlayingSong ? const Color(0xFFE94057) : Colors.white90,
                            fontWeight: isPlayingSong ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlayingSong ? Colors.white70 : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => playerService.removeSong(index),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.close, color: Colors.white30, size: 16),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.drag_handle, color: Colors.white24, size: 18),
                          ],
                        ),
                        onTap: () => playerService.playAtIndex(index),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
