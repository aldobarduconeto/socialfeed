import 'platform_type.dart';

enum FeedItemType {
  post,
  video,
  reel;

  String get label {
    switch (this) {
      case FeedItemType.post:
        return 'Publicação';
      case FeedItemType.video:
        return 'Vídeo';
      case FeedItemType.reel:
        return 'Reel';
    }
  }
}

class FeedItem {
  final String id;
  final SocialPlatform platform;
  final String accountUsername;
  final String authorName;
  final String authorAvatarUrl;
  final DateTime publishedAt;
  final String caption;
  final List<String> mediaUrls;
  final String? videoUrl;
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final String postUrl;
  final FeedItemType type;
  final String? soundTrack;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.platform,
    required this.accountUsername,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.publishedAt,
    required this.caption,
    required this.mediaUrls,
    this.videoUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    required this.postUrl,
    this.type = FeedItemType.post,
    this.soundTrack,
    this.isLiked = false,
  });

  String get authorHandle => '@$accountUsername';

  String get formattedLikes => formatCompact(likes);
  String get formattedComments => formatCompact(comments);
  String get formattedShares => formatCompact(shares);
  String get formattedViews => formatCompact(views);

  static String formatCompact(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'accountUsername': accountUsername,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'caption': caption,
      'mediaUrls': mediaUrls,
      'videoUrl': videoUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'views': views,
      'postUrl': postUrl,
      'type': type.name,
      'soundTrack': soundTrack,
      'isLiked': isLiked,
    };
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.instagram,
      ),
      accountUsername: json['accountUsername'] as String,
      authorName: json['authorName'] as String? ?? json['accountUsername'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : DateTime.now(),
      caption: json['caption'] as String? ?? '',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoUrl: json['videoUrl'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      postUrl: json['postUrl'] as String? ?? '',
      type: FeedItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedItemType.post,
      ),
      soundTrack: json['soundTrack'] as String?,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }
}
