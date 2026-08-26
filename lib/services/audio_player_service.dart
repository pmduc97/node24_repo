import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

enum CustomLoopMode { off, all, one }

// ─────────────────────────────────────────────
// AudioHandler: required by audio_service to
// keep playback alive in the background and
// show media notification on lock screen.
// ─────────────────────────────────────────────
class VibeMusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  VibeMusicHandler() {
    _player.playerStateStream.listen(_broadcastState);
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
    }[ps.processingState]!;

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
    // Signal handled by AudioPlayerService
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

  @override
  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _player.dispose();
    super.noSuchMethod(Invocation.method(#dispose, []));
  }
}

// ─────────────────────────────────────────────
// AudioPlayerService: ChangeNotifier that drives
// all UI state. Delegates actual playback to
// VibeMusicHandler via audio_service.
// ─────────────────────────────────────────────
class AudioPlayerService extends ChangeNotifier {
  late final VibeMusicHandler _handler;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<dynamic>? _customEventSub;

  final List<SongModel> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffleEnabled = false;
  CustomLoopMode _loopMode = CustomLoopMode.off;

  Timer? _sleepTimer;
  int _remainingTimerSeconds = 0;

  // ── Getters ──────────────────────────────────
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  bool get isPlaying => _handler.player.playing;
  bool get isShuffleEnabled => _isShuffleEnabled;
  CustomLoopMode get loopMode => _loopMode;
  int get remainingTimerSeconds => _remainingTimerSeconds;
  bool get isTimerActive => _sleepTimer != null && _sleepTimer!.isActive;

  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;
  Stream<PlayerState> get playerStateStream => _handler.player.playerStateStream;

  // ── Init ─────────────────────────────────────
  AudioPlayerService(this._handler) {
    _initListeners();
  }

  static Future<AudioPlayerService> create() async {
    final handler = await AudioService.init(
      builder: () => VibeMusicHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.vibe.musicplayer.channel.audio',
        androidNotificationChannelName: 'Vibe Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: 0xFFE94057,
      ),
    );
    return AudioPlayerService(handler);
  }

  void _initListeners() {
    // Track completion → auto-advance
    _playerStateSub = _handler.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
      notifyListeners();
    });

    // Handle skip commands from notification buttons
    _customEventSub = _handler.customEvent.listen((event) {
      if (event == 'next') next();
      if (event == 'previous') previous();
    });
  }

  // Called from stream listener — intentionally fire-and-forget
  void _handleSongCompletion() {
    if (_playlist.isEmpty) return;
    if (_loopMode == CustomLoopMode.one) {
      _handler.player.seek(Duration.zero).then((_) => _handler.player.play());
    } else if (_currentIndex < _playlist.length - 1) {
      playAtIndex(_currentIndex + 1);
    } else if (_loopMode == CustomLoopMode.all) {
      playAtIndex(0);
    } else {
      _handler.stop();
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

  // ── File Picking ──────────────────────────────
  Future<int> pickFiles() async {
    await requestStoragePermission();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      int addedCount = 0;
      for (String? path in result.paths) {
        if (path != null && !_playlist.any((s) => s.path == path)) {
          _playlist.add(SongModel.fromFilePath(path));
          addedCount++;
        }
      }
      if (_currentIndex == -1 && _playlist.isNotEmpty) _currentIndex = 0;
      notifyListeners();
      return addedCount;
    }
    return 0;
  }

  Future<int> pickFolder() async {
    await requestStoragePermission();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      int addedCount = 0;
      try {
        final entities = dir.listSync(recursive: true);
        const audioExtensions = ['.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg'];
        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path;
            if (audioExtensions.any((ext) => path.toLowerCase().endsWith(ext))) {
              if (!_playlist.any((s) => s.path == path)) {
                _playlist.add(SongModel.fromFilePath(path));
                addedCount++;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning folder: $e');
      }
      if (_currentIndex == -1 && _playlist.isNotEmpty) _currentIndex = 0;
      notifyListeners();
      return addedCount;
    }
    return 0;
  }

  // ── Playback ──────────────────────────────────
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[_currentIndex];
    try {
      await _handler.setMediaItemFromSong(song);
      await _handler.loadAndPlay(song.path);
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
    if (_handler.player.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
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
    if (_handler.player.position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
      return;
    }
    _currentIndex = _isShuffleEnabled
        ? (List.generate(_playlist.length, (i) => i)..shuffle()).first
        : (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playAtIndex(_currentIndex);
  }

  Future<void> seek(Duration position) => _handler.seek(position);

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
      _handler.stop();
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
    _handler.stop();
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
        _handler.pause();
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
    super.dispose();
    // Note: _handler and its player are managed by audio_service lifecycle
  }
}
