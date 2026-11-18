/// YouTube link helpers shared by sermons, church events and worship
/// schedules (YouTube Live).
library;

/// Extracts the video id from watch / youtu.be / live / embed / shorts URLs.
/// Returns null for non-YouTube or unparseable URLs.
String? youtubeVideoId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.toLowerCase();

  if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
    return uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty
        ? uri.pathSegments.first
        : null;
  }
  if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        (segments[0] == 'live' || segments[0] == 'embed' || segments[0] == 'shorts')) {
      return segments[1].isEmpty ? null : segments[1];
    }
  }
  return null;
}

/// Validates an optional YouTube link before it is saved. Mirrors the
/// database CHECK (`^https://(www.|m.)?(youtube.com|youtu.be)/`).
/// Returns an error message, or null when [value] is empty or valid.
String? validateYoutubeUrl(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  final uri = Uri.tryParse(v);
  if (uri == null || uri.scheme != 'https') {
    return 'Tautan harus diawali https://';
  }
  final host = uri.host.toLowerCase();
  const allowed = {'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'};
  if (!allowed.contains(host)) {
    return 'Masukkan tautan YouTube (youtube.com atau youtu.be).';
  }
  if (host != 'youtu.be' && uri.path == '/' && uri.queryParameters.isEmpty) {
    return 'Tautan YouTube belum lengkap.';
  }
  return null;
}

/// Thumbnail served by YouTube for a video id.
String youtubeThumbnail(String videoId) => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
