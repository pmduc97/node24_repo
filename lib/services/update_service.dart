import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String releaseNotes;
  final String apkUrl;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.releaseNotes,
    required this.apkUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
    );
  }
}

class UpdateService {
  static const String currentVersion = '1.0.3';
  static const int currentVersionCode = 4;
  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/pmduc97/node24_repo/my_music_app/releases/version.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse('$versionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final info = UpdateInfo.fromJson(data);

        if (info.versionCode > currentVersionCode) {
          return info;
        }
      }
    } catch (e) {
      debugPrint('Check update error: $e');
    }
    return null;
  }

  static Future<void> downloadAndInstallApk({
    required String apkUrl,
    required Function(double progress) onProgress,
    required Function(String error) onError,
    required VoidCallback onSuccess,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        onError('Không thể tải file APK (Mã lỗi ${response.statusCode})');
        return;
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/VibeMusic_update.apk';
      final file = File(filePath);

      int bytesDownloaded = 0;
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          bytesDownloaded += chunk.length;
          sink.add(chunk);

          if (contentLength > 0) {
            final progress = bytesDownloaded / contentLength;
            onProgress(progress);
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          onSuccess();

          final result = await OpenFilex.open(filePath);
          if (result.type != ResultType.done) {
            onError('Mở file cài đặt thất bại: ${result.message}');
          }
        },
        onError: (e) async {
          await sink.close();
          onError('Lỗi khi tải file: $e');
        },
        cancelOnError: true,
      );
    } catch (e) {
      onError('Lỗi không xác định: $e');
    }
  }
}
