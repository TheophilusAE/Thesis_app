import '../models/playlist.dart';

class PlaylistService {
  Future<Playlist> getTodaysPlaylist() async {
    // In a real app, this would fetch from an API
    return Playlist(
      id: '1',
      title: 'Playlist Hari Ini',
      description: 'Lagu-lagu pujian dan penyembahan untuk hari ini',
      date: DateTime.now(),
      songs: [
        Song(
          id: '1',
          title: 'Yesus Kaulah Segalanya',
          artist: 'Tim Pujian',
          lyrics: '''Yesus Kaulah segalanya
Dalam hidupku
S\'gala yang kutaruhkan
Hanya bagi-Mu

Reff:
Tak akan pernah ada
Yang dapat gantikan Dikau
Yesus Tuhan dan Rajaku''',
        ),
        Song(
          id: '2',
          title: 'Tuhan adalah Gembalaku',
          artist: 'Mazmur 23',
          lyrics: '''Tuhan adalah Gembalaku
Takkan kekurangan aku
Ia membaringkan aku
Di padang rumput hijau

Ia membimbingku ke air yang tenang
Ia menyegarkan jiwaku''',
        ),
        Song(
          id: '3',
          title: 'Kasih-Mu Yesus',
          artist: 'Tim Worship',
          lyrics: '''Kasih-Mu Yesus
Tak terbatas
Kasih-Mu Yesus  
Sempurna adanya

S\'lalu mengampuni
S\'lalu memulihkan
Kasih-Mu Yesus
Terindah''',
        ),
      ],
    );
  }

  Future<List<Playlist>> getPlaylistHistory() async {
    final now = DateTime.now();
    return [
      Playlist(
        id: '2',
        title: 'Playlist Kemarin',
        description: 'Koleksi lagu pujian minggu lalu',
        date: now.subtract(Duration(days: 1)),
        songs: [
          Song(
            id: '4',
            title: 'Bapa yang Kekal',
            artist: 'Hymn',
          ),
        ],
      ),
    ];
  }
}
