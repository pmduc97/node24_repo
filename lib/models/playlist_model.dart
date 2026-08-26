class PlaylistModel {
  final String id;
  final String name;
  final List<String> songPaths;
  final DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songPaths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songPaths': songPaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Playlist',
      songPaths: List<String>.from(json['songPaths'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
