import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/playlist_model.dart';

class PlaylistStorageService {
  static Future<File> _getFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  // ── Favorites Storage ────────────────────────
  static Future<Set<String>> loadFavorites() async {
    try {
      final file = await _getFile('vibe_favorites.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = json.decode(content);
        return list.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
    return {};
  }

  static Future<void> saveFavorites(Set<String> favorites) async {
    try {
      final file = await _getFile('vibe_favorites.json');
      await file.writeAsString(json.encode(favorites.toList()));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // ── Custom Playlists Storage ──────────────────
  static Future<List<PlaylistModel>> loadPlaylists() async {
    try {
      final file = await _getFile('vibe_playlists.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = json.decode(content);
        return list.map((e) => PlaylistModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
    return [];
  }

  static Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    try {
      final file = await _getFile('vibe_playlists.json');
      final data = playlists.map((p) => p.toJson()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  // ── Custom Song Titles Mapping Storage ────────
  static Future<Map<String, Map<String, String>>> loadCustomTitles() async {
    try {
      final file = await _getFile('vibe_song_titles.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> rawMap = json.decode(content);
        final Map<String, Map<String, String>> result = {};
        rawMap.forEach((path, val) {
          if (val is Map) {
            result[path] = {
              'title': val['title']?.toString() ?? '',
              'artist': val['artist']?.toString() ?? '',
            };
          }
        });
        return result;
      }
    } catch (e) {
      debugPrint('Error loading custom titles: $e');
    }
    return {};
  }

  static Future<void> saveCustomTitles(Map<String, Map<String, String>> titlesMap) async {
    try {
      final file = await _getFile('vibe_song_titles.json');
      await file.writeAsString(json.encode(titlesMap));
    } catch (e) {
      debugPrint('Error saving custom titles: $e');
    }
  }
}
