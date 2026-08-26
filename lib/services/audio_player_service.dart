import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'playlist_storage_service.dart';

enum CustomLoopMode { off, all, one }

// ─────────────────────────────────────────────
// AudioHandler: required by audio_service to
// keep playback alive in background & lockscreen.
// ─────────────────────────────────────────────
class VibeMusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  VibeMusicHandler() {
    _playerStateSub = _player.playerStateStream.listen(_broadcastState);
    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });
    _player.durationStream.listen((dur) {
      if (dur != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: dur));
      }
    });
  }

  AudioPlayer get player => _player;

  void _broadcastState(PlayerState ps) {
    final isPlaying = ps.playing;
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[ps.processingState] ?? AudioProcessingState.idle;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: processingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  Future<void> setMediaItemFromSong(SongModel song) async {
    mediaItem.add(MediaItem(
      id: song.path,
      title: song.title,
      artist: song.artist,
      album: song.album ?? '',
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    customEvent.add('next');
  }

  @override
  Future<void> skipToPrevious() async {
    customEvent.add('previous');
  }

  Future<void> loadAndPlay(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  Future<void> disposeHandler() async {
    await _playerStateSub?.cancel();
    await _player.dispose();
  }
}

// ─────────────────────────────────────────────
// AudioPlayerService: drives UI state with
// ZERO-FREEZE non-blocking async execution.
// Includes Playlists, Favorites & Custom Titles.
// ─────────────────────────────────────────────
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _fallbackPlayer = AudioPlayer();
  VibeMusicHandler? _handler;
  bool _isScanning = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<dynamic>? _customEventSub;

  final List<SongModel> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffleEnabled = false;
  CustomLoopMode _loopMode = CustomLoopMode.off;

  Timer? _sleepTimer;
  int _remainingTimerSeconds = 0;

  // Favorites, Playlists & Custom Titles Persistence
  Set<String> _favoritePaths = {};
  List<PlaylistModel> _customPlaylists = [];
  Map<String, Map<String, String>> _customSongTitles = {};

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wma',
    '.amr'
  };

  AudioPlayer get _activePlayer => _handler?.player ?? _fallbackPlayer;

  // ── Getters ──────────────────────────────────
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  bool get isScanning => _isScanning;
  Set<String> get favoritePaths => Set.unmodifiable(_favoritePaths);
  List<PlaylistModel> get customPlaylists => List.unmodifiable(_customPlaylists);
  Map<String, Map<String, String>> get customSongTitles => Map.unmodifiable(_customSongTitles);

  List<SongModel> get favoriteSongs =>
      _playlist.where((s) => _favoritePaths.contains(s.path)).toList();

  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  bool get isPlaying => _activePlayer.playing;
  bool get isShuffleEnabled => _isShuffleEnabled;
  CustomLoopMode get loopMode => _loopMode;
  int get remainingTimerSeconds => _remainingTimerSeconds;
  bool get isTimerActive => _sleepTimer != null && _sleepTimer!.isActive;

  Stream<Duration> get positionStream => _activePlayer.positionStream;
  Stream<Duration?> get durationStream => _activePlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _activePlayer.playerStateStream;

  // ── Init ─────────────────────────────────────
  AudioPlayerService() {
    _initAudioService();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    _favoritePaths = await PlaylistStorageService.loadFavorites();
    _customPlaylists = await PlaylistStorageService.loadPlaylists();
    _customSongTitles = await PlaylistStorageService.loadCustomTitles();
    notifyListeners();
  }

  Future<void> _initAudioService() async {
    try {
      _handler = await AudioService.init(
        builder: () => VibeMusicHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.vibe.musicplayer.channel.audio',
          androidNotificationChannelName: 'Vibe Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          notificationColor: Color(0xFFE94057),
        ),
      );
      _initListeners();
    } catch (e) {
      debugPrint('AudioService init fallback to internal player: $e');
      _playerStateSub = _fallbackPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _handleSongCompletion();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _initListeners() {
    if (_handler == null) return;

    _playerStateSub = _handler!.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
      notifyListeners();
    });

    _customEventSub = _handler!.customEvent.listen((event) {
      if (event == 'next') next();
      if (event == 'previous') previous();
    });
  }

  void _handleSongCompletion() {
    if (_playlist.isEmpty) return;
    if (_loopMode == CustomLoopMode.one) {
      _activePlayer.seek(Duration.zero).then((_) => _activePlayer.play());
    } else if (_currentIndex < _playlist.length - 1) {
      playAtIndex(_currentIndex + 1);
    } else if (_loopMode == CustomLoopMode.all) {
      playAtIndex(0);
    } else {
      _handler?.stop() ?? _fallbackPlayer.stop();
    }
  }

  // ── Permissions ───────────────────────────────
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted || storageStatus.isLimited;
    }
    return true;
  }

  // Helper to create SongModel applying custom title mapping if available
  SongModel _createSongModel(String path) {
    if (_customSongTitles.containsKey(path)) {
      final custom = _customSongTitles[path]!;
      return SongModel.fromFilePath(
        path,
        customTitle: custom['title'],
        customArtist: custom['artist'],
      );
    }
    return SongModel.fromFilePath(path);
  }

  // ── File Picking (STRICT Audio Filter audio/*) ──
  Future<int> pickFiles() async {
    await requestStoragePermission();
    _isScanning = true;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        int addedCount = 0;
        final existingPaths = _playlist.map((s) => s.path).toSet();
        for (String? path in result.paths) {
          if (path != null && !existingPaths.contains(path)) {
            final lower = path.toLowerCase();
            if (_audioExtensions.any((ext) => lower.endsWith(ext))) {
              _playlist.add(_createSongModel(path));
              existingPaths.add(path);
              addedCount++;
            }
          }
        }
        if (_currentIndex == -1 && _playlist.isNotEmpty) _currentIndex = 0;
        return addedCount;
      }
    } finally {
      _isScanning = false;
      notifyListeners();
    }
    return 0;
  }

  // ── Folder Scanning (STRICT Audio Filter & Stream) ──
  Future<int> pickFolder() async {
    await requestStoragePermission();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return 0;

    _isScanning = true;
    notifyListeners();

    int addedCount = 0;
    try {
      final dir = Directory(selectedDirectory);
      final existingPaths = _playlist.map((s) => s.path).toSet();

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final path = entity.path;
          final lower = path.toLowerCase();
          if (_audioExtensions.any((ext) => lower.endsWith(ext))) {
            if (!existingPaths.contains(path)) {
              _playlist.add(_createSongModel(path));
              existingPaths.add(path);
              addedCount++;
            }
          }
        }
      }
      if (_currentIndex == -1 && _playlist.isNotEmpty) _currentIndex = 0;
    } catch (e) {
      debugPrint('Error scanning folder: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
    return addedCount;
  }

  // ── Custom Song Title Override Mapping ──────────
  Future<void> updateSongDisplayName(
      String songPath, String newTitle, String newArtist) async {
    _customSongTitles[songPath] = {
      'title': newTitle.trim(),
      'artist': newArtist.trim(),
    };
    await PlaylistStorageService.saveCustomTitles(_customSongTitles);

    // Update in-memory playlist
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i].path == songPath) {
        _playlist[i] = _playlist[i].copyWith(
          title: newTitle.trim(),
          artist: newArtist.trim(),
        );
      }
    }

    // Update background player notification if active
    if (currentSong?.path == songPath && _handler != null) {
      await _handler!.setMediaItemFromSong(currentSong!);
    }
    notifyListeners();
  }

  Future<void> resetSongDisplayName(String songPath) async {
    _customSongTitles.remove(songPath);
    await PlaylistStorageService.saveCustomTitles(_customSongTitles);

    // Re-create default SongModel
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i].path == songPath) {
        _playlist[i] = SongModel.fromFilePath(songPath);
      }
    }

    if (currentSong?.path == songPath && _handler != null) {
      await _handler!.setMediaItemFromSong(currentSong!);
    }
    notifyListeners();
  }

  // ── Favorites Management ─────────────────────
  bool isFavorite(String songPath) => _favoritePaths.contains(songPath);

  void toggleFavorite(String songPath) {
    if (_favoritePaths.contains(songPath)) {
      _favoritePaths.remove(songPath);
    } else {
      _favoritePaths.add(songPath);
    }
    PlaylistStorageService.saveFavorites(_favoritePaths);
    notifyListeners();
  }

  // ── Custom Playlists Management ───────────────
  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final newPlaylist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songPaths: [],
      createdAt: DateTime.now(),
    );
    _customPlaylists.add(newPlaylist);
    await PlaylistStorageService.savePlaylists(_customPlaylists);
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    await PlaylistStorageService.savePlaylists(_customPlaylists);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, String songPath) async {
    final index = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final p = _customPlaylists[index];
      if (!p.songPaths.contains(songPath)) {
        final updatedPaths = List<String>.from(p.songPaths)..add(songPath);
        _customPlaylists[index] = PlaylistModel(
          id: p.id,
          name: p.name,
          songPaths: updatedPaths,
          createdAt: p.createdAt,
        );
        await PlaylistStorageService.savePlaylists(_customPlaylists);
        notifyListeners();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songPath) async {
    final index = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final p = _customPlaylists[index];
      final updatedPaths = List<String>.from(p.songPaths)..remove(songPath);
      _customPlaylists[index] = PlaylistModel(
        id: p.id,
        name: p.name,
        songPaths: updatedPaths,
        createdAt: p.createdAt,
      );
      await PlaylistStorageService.savePlaylists(_customPlaylists);
      notifyListeners();
    }
  }

  List<SongModel> getSongsForPlaylist(PlaylistModel playlistModel) {
    return _playlist.where((s) => playlistModel.songPaths.contains(s.path)).toList();
  }

  void playCustomPlaylist(PlaylistModel playlistModel, {int startIndex = 0}) {
    final songs = getSongsForPlaylist(playlistModel);
    if (songs.isNotEmpty) {
      _playlist.clear();
      _playlist.addAll(songs);
      playAtIndex(startIndex);
    }
  }

  // ── Playback ──────────────────────────────────
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    notifyListeners();

    final song = _playlist[_currentIndex];
    try {
      if (_handler != null) {
        await _handler!.setMediaItemFromSong(song);
        await _handler!.loadAndPlay(song.path);
      } else {
        await _fallbackPlayer.setFilePath(song.path);
        await _fallbackPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex == -1) {
      await playAtIndex(0);
      return;
    }
    if (_activePlayer.playing) {
      if (_handler != null) {
        await _handler!.pause();
      } else {
        await _fallbackPlayer.pause();
      }
    } else {
      if (_handler != null) {
        await _handler!.play();
      } else {
        await _fallbackPlayer.play();
      }
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    _currentIndex = _isShuffleEnabled
        ? (List.generate(_playlist.length, (i) => i)..shuffle()).first
        : (_currentIndex + 1) % _playlist.length;
    await playAtIndex(_currentIndex);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_activePlayer.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    _currentIndex = _isShuffleEnabled
        ? (List.generate(_playlist.length, (i) => i)..shuffle()).first
        : (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playAtIndex(_currentIndex);
  }

  Future<void> seek(Duration position) async {
    if (_handler != null) {
      await _handler!.seek(position);
    } else {
      await _fallbackPlayer.seek(position);
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleLoopMode() {
    _loopMode = CustomLoopMode.values[(_loopMode.index + 1) % 3];
    notifyListeners();
  }

  void removeSong(int index) {
    if (index < 0 || index >= _playlist.length) return;
    final isCurrent = (index == _currentIndex);
    _playlist.removeAt(index);
    if (_playlist.isEmpty) {
      _handler?.stop() ?? _fallbackPlayer.stop();
      _currentIndex = -1;
    } else if (isCurrent) {
      _currentIndex = _currentIndex % _playlist.length;
      playAtIndex(_currentIndex);
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    notifyListeners();
  }

  void clearPlaylist() {
    _handler?.stop() ?? _fallbackPlayer.stop();
    _playlist.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }

  // ── Sleep Timer ───────────────────────────────
  void setSleepTimer(int minutes) {
    cancelSleepTimer();
    if (minutes <= 0) return;
    _remainingTimerSeconds = minutes * 60;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingTimerSeconds > 0) {
        _remainingTimerSeconds--;
        notifyListeners();
      } else {
        cancelSleepTimer();
        if (_handler != null) {
          _handler!.pause();
        } else {
          _fallbackPlayer.pause();
        }
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _remainingTimerSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _playerStateSub?.cancel();
    _customEventSub?.cancel();
    _fallbackPlayer.dispose();
    _handler?.disposeHandler();
    super.dispose();
  }
}
