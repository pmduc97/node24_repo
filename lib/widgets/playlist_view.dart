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

    return Column(
      children: [
        // Action buttons: Pick Files & Pick Folder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF32384A)),
                    ),
                  ),
                  icon: const Icon(Icons.audio_file, color: Color(0xFFE94057), size: 20),
                  label: const Text('Chọn File', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    int added = await playerService.pickFiles();
                    if (context.mounted && added > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm $added file nhạc vào danh sách')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFF32384A)),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open, color: Color(0xFFF27121), size: 20),
                  label: const Text('Chọn Folder', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    int added = await playerService.pickFolder();
                    if (context.mounted && added > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã tìm thấy & thêm $added bài hát từ folder')),
                      );
                    }
                  },
                ),
              ),
              if (playlist.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white54),
                  tooltip: 'Xóa toàn bộ danh sách',
                  onPressed: () {
                    playerService.clearPlaylist();
                  },
                ),
              ],
            ],
          ),
        ),

        // Playlist counter info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH PHÁT (${playlist.length})',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              if (playlist.isNotEmpty)
                const Text(
                  'Kéo thả để sắp xếp',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Playlist List View or Empty State
        Expanded(
          child: playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252A38),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.library_music_outlined,
                          size: 48,
                          color: Color(0xFFE94057),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có bài hát nào trong danh sách',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhấn "Chọn File" hoặc "Chọn Folder" để đưa nhạc vào',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                  itemCount: playlist.length,
                  onReorder: playerService.reorderPlaylist,
                  itemBuilder: (context, index) {
                    final song = playlist[index];
                    final isPlayingSong = (index == currentIndex);

                    return Container(
                      key: ValueKey(song.id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isPlayingSong
                            ? const Color(0xFFE94057).withOpacity(0.15)
                            : const Color(0xFF1E222D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPlayingSong
                              ? const Color(0xFFE94057).withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isPlayingSong
                                ? const Color(0xFFE94057)
                                : const Color(0xFF2A2E3D),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPlayingSong ? Icons.equalizer : Icons.music_note,
                            color: isPlayingSong ? Colors.white : Colors.white54,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlayingSong ? const Color(0xFFE94057) : Colors.white,
                            fontWeight: isPlayingSong ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlayingSong ? Colors.white70 : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                              onPressed: () => playerService.removeSong(index),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.white24, size: 20),
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
