import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

enum CustomLoopMode { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  
  final List<SongModel> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffleEnabled = false;
  CustomLoopMode _loopMode = CustomLoopMode.off;

  // Sleep Timer
  Timer? _sleepTimer;
  int _remainingTimerSeconds = 0;

  // Streams for UI
  List<SongModel> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  bool get isPlaying => _player.playing;
  bool get isShuffleEnabled => _isShuffleEnabled;
  CustomLoopMode get loopMode => _loopMode;
  int get remainingTimerSeconds => _remainingTimerSeconds;
  bool get isTimerActive => _sleepTimer != null && _sleepTimer!.isActive;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  AudioPlayerService() {
    _initListeners();
  }

  void _initListeners() {
    // Automatically move to next track when completed
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
      notifyListeners();
    });
  }

  void _handleSongCompletion() {
    if (_playlist.isEmpty) return;

    if (_loopMode == CustomLoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_currentIndex < _playlist.length - 1) {
      next();
    } else if (_loopMode == CustomLoopMode.all) {
      playAtIndex(0);
    } else {
      _player.stop();
    }
  }

  // Permission helper
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.request().isGranted ||
          await Permission.storage.request().isGranted) {
        return true;
      }
      return true;
    }
    return true;
  }

  // Pick Multiple Files
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
      if (_currentIndex == -1 && _playlist.isNotEmpty) {
        _currentIndex = 0;
      }
      notifyListeners();
      return addedCount;
    }
    return 0;
  }

  // Pick Folder and Scan audio files
  Future<int> pickFolder() async {
    await requestStoragePermission();

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      int addedCount = 0;

      try {
        final List<FileSystemEntity> entities = dir.listSync(recursive: true);
        final audioExtensions = ['.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg'];

        for (var entity in entities) {
          if (entity is File) {
            String path = entity.path;
            String lowerPath = path.toLowerCase();
            if (audioExtensions.any((ext) => lowerPath.endsWith(ext))) {
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

      if (_currentIndex == -1 && _playlist.isNotEmpty) {
        _currentIndex = 0;
      }
      notifyListeners();
      return addedCount;
    }
    return 0;
  }

  // Playback Operations
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    try {
      await _player.setFilePath(_playlist[_currentIndex].path);
      await _player.play();
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

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_isShuffleEnabled) {
      _currentIndex = (List.generate(_playlist.length, (i) => i)..shuffle()).first;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }

    await playAtIndex(_currentIndex);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_isShuffleEnabled) {
      _currentIndex = (List.generate(_playlist.length, (i) => i)..shuffle()).first;
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }

    await playAtIndex(_currentIndex);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case CustomLoopMode.off:
        _loopMode = CustomLoopMode.all;
        break;
      case CustomLoopMode.all:
        _loopMode = CustomLoopMode.one;
        break;
      case CustomLoopMode.one:
        _loopMode = CustomLoopMode.off;
        break;
    }
    notifyListeners();
  }

  void removeSong(int index) {
    if (index < 0 || index >= _playlist.length) return;

    bool isRemovingCurrent = (index == _currentIndex);
    _playlist.removeAt(index);

    if (_playlist.isEmpty) {
      _player.stop();
      _currentIndex = -1;
    } else if (isRemovingCurrent) {
      _currentIndex = _currentIndex % _playlist.length;
      playAtIndex(_currentIndex);
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    notifyListeners();
  }

  void clearPlaylist() {
    _player.stop();
    _playlist.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
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

  // Sleep Timer logic
  void setSleepTimer(int minutes) {
    cancelSleepTimer();

    if (minutes <= 0) return;

    _remainingTimerSeconds = minutes * 60;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTimerSeconds > 0) {
        _remainingTimerSeconds--;
        notifyListeners();
      } else {
        cancelSleepTimer();
        _player.pause();
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
    _player.dispose();
    super.dispose();
  }
}
