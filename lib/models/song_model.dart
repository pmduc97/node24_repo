class SongModel {
  final String id;
  final String title;
  final String artist;
  final String path;
  final Duration duration;
  final String? album;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.duration = Duration.zero,
    this.album,
  });

  factory SongModel.fromFilePath(String filePath) {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    // Try parsing 'Artist - Title' format if present
    String title = nameWithoutExt;
    String artist = 'Unknown Artist';

    if (nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    return SongModel(
      id: filePath,
      title: title,
      artist: artist,
      path: filePath,
    );
  }
}
