class Sermon {
  final String id;
  final String title;
  final String speaker;
  final String description;
  final String mediaType; // 'youtube', 'audio', 'livestream'
  final String mediaUrl;
  final String? thumbnailUrl;
  final DateTime sermonDate;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Sermon({
    required this.id,
    required this.title,
    this.speaker = '',
    this.description = '',
    this.mediaType = 'youtube',
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.sermonDate,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Extracts the YouTube video id from watch/short/live URL shapes.
  /// Returns null for non-YouTube URLs or ones that can't be parsed.
  String? get youtubeVideoId {
    final uri = Uri.tryParse(mediaUrl);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();

    if (host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      // e.g. /live/<id> or /embed/<id>
      final segments = uri.pathSegments;
      if (segments.length >= 2 && (segments[0] == 'live' || segments[0] == 'embed')) {
        return segments[1];
      }
    }
    return null;
  }

  /// Client-derived thumbnail: prefer an explicit thumbnail_url, else fall
  /// back to YouTube's own thumbnail CDN when the video id is known.
  String? get resolvedThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    final videoId = youtubeVideoId;
    if (videoId != null) return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return null;
  }

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      speaker: (json['speaker'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      mediaType: (json['media_type'] ?? 'youtube') as String,
      mediaUrl: (json['media_url'] ?? '') as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sermonDate: DateTime.parse(json['sermon_date'] as String),
      isActive: (json['is_active'] ?? true) as bool,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'title': title,
      'speaker': speaker,
      'description': description,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'sermon_date': sermonDate.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      ...toSupabaseJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Sermon copyWith({
    String? id,
    String? title,
    String? speaker,
    String? description,
    String? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    DateTime? sermonDate,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      description: description ?? this.description,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sermonDate: sermonDate ?? this.sermonDate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
