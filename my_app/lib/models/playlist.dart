class Playlist {
  final String id;
  final String title;
  final String description;
  final List<Song> songs;
  final DateTime date;
  final String? coverImage;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.songs,
    required this.date,
    this.coverImage,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      songs: (json['songs'] as List).map((s) => Song.fromJson(s)).toList(),
      date: DateTime.parse(json['date']),
      coverImage: json['coverImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'songs': songs.map((s) => s.toJson()).toList(),
      'date': date.toIso8601String(),
      'coverImage': coverImage,
    };
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String? lyrics;
  final String? audioUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.lyrics,
    this.audioUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      lyrics: json['lyrics'],
      audioUrl: json['audioUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'lyrics': lyrics,
      'audioUrl': audioUrl,
    };
  }
}
