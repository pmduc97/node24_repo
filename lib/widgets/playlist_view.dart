import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2430),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.playlist_add, color: Color(0xFFE94057)),
            SizedBox(width: 10),
            Text('Tạo Playlist Mới', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên Playlist (ví dụ: Nhạc Chill)...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE94057)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94057),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Provider.of<AudioPlayerService>(context, listen: false)
                    .createPlaylist(name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Tạo Playlist'),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, SongModel song) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    final playlists = playerService.customPlaylists;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.playlist_add_check, color: Color(0xFFE94057)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thêm "${song.title}" vào Playlist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có Playlist nào. Hãy tạo Playlist trước!',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, idx) {
                    final pl = playlists[idx];
                    final contains = pl.songPaths.contains(song.path);

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.queue_music, color: Color(0xFFF27121)),
                      title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${pl.songPaths.length} bài hát', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: contains
                          ? const Icon(Icons.check_circle, color: Color(0xFFE94057))
                          : const Icon(Icons.add_circle_outline, color: Colors.white38),
                      onTap: () {
                        if (contains) {
                          playerService.removeSongFromPlaylist(pl.id, song.path);
                        } else {
                          playerService.addSongToPlaylist(pl.id, song.path);
                        }
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE94057),
                  side: const BorderSide(color: Color(0xFFE94057)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tạo Playlist Mới'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showCreatePlaylistDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final playlist = playerService.playlist;
    final currentIndex = playerService.currentIndex;
    final isScanning = playerService.isScanning;
    final favoriteSongs = playerService.favoriteSongs;
    final customPlaylists = playerService.customPlaylists;

    return Column(
      children: [
        // Tab Navigation Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D27),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE94057), Color(0xFFF27121)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Tất Cả Bài Hát'),
              Tab(text: 'Playlist & Yêu Thích'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: ALL SONGS (File & Folder Picker + Main List)
              Column(
                children: [
                  // Action buttons: Pick Files & Pick Folder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

                  // Progress Bar
                  if (isScanning)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF1E222D),
                        color: Color(0xFFE94057),
                        minHeight: 2,
                      ),
                    ),

                  // Song Counter Line
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

                  // Main List
                  Expanded(
                    child: playlist.isEmpty
                        ? _buildEmptyState()
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
                            itemCount: playlist.length,
                            onReorder: playerService.reorderPlaylist,
                            itemBuilder: (context, index) {
                              final song = playlist[index];
                              final isPlayingSong = (index == currentIndex);
                              final isFav = playerService.isFavorite(song.path);

                              return _buildCompactSongTile(
                                context: context,
                                song: song,
                                index: index,
                                isPlayingSong: isPlayingSong,
                                isFav: isFav,
                                playerService: playerService,
                              );
                            },
                          ),
                  ),
                ],
              ),

              // TAB 2: PLAYLISTS & FAVORITES
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FAVORITES SECTION
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE94057).withOpacity(0.2),
                            const Color(0xFF1E222D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE94057).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE94057),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bài Hát Yêu Thích',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${favoriteSongs.length} bài hát',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (favoriteSongs.isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE94057),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text('Phát Tất Cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                playerService.playCustomPlaylist(
                                  PlaylistModel(
                                    id: 'fav',
                                    name: 'Bài Hát Yêu Thích',
                                    songPaths: favoriteSongs.map((s) => s.path).toList(),
                                    createdAt: DateTime.now(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CUSTOM PLAYLISTS HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PLAYLIST CỦA TÔI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF252A38),
                            foregroundColor: const Color(0xFFF27121),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFF27121)),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tạo Playlist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showCreatePlaylistDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // CUSTOM PLAYLISTS LIST
                    if (customPlaylists.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.queue_music, color: Colors.white38, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Chưa có Playlist cá nhân nào',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nhấn "Tạo Playlist" để nhóm các bài hát theo chủ đề',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: customPlaylists.length,
                        itemBuilder: (context, idx) {
                          final pl = customPlaylists[idx];
                          final songs = playerService.getSongsForPlaylist(pl);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222D),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF27121).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.queue_music, color: Color(0xFFF27121), size: 22),
                              ),
                              title: Text(
                                pl.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${songs.length} bài hát',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (songs.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill, color: Color(0xFFE94057), size: 28),
                                      onPressed: () => playerService.playCustomPlaylist(pl),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                                    onPressed: () => playerService.deletePlaylist(pl.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSongTile({
    required BuildContext context,
    required SongModel song,
    required int index,
    required bool isPlayingSong,
    required bool isFav,
    required AudioPlayerService playerService,
  }) {
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
            color: isPlayingSong ? const Color(0xFFE94057) : const Color(0xFF282C3A),
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
            // Favorite toggle
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => playerService.toggleFavorite(song.path),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? const Color(0xFFE94057) : Colors.white24,
                  size: 16,
                ),
              ),
            ),
            // Add to Playlist
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showAddToPlaylistDialog(context, song),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.playlist_add, color: Colors.white30, size: 18),
              ),
            ),
            // Remove
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => playerService.removeSong(index),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, color: Colors.white30, size: 16),
              ),
            ),
            const Icon(Icons.drag_handle, color: Colors.white24, size: 16),
          ],
        ),
        onTap: () => playerService.playAtIndex(index),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }
}
