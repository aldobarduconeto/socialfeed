import 'platform_type.dart';

class StoryItem {
  final String id;
  final SocialPlatform platform;
  final String accountUsername;
  final String authorName;
  final String authorAvatarUrl;
  final String mediaUrl;
  final String? caption;
  final DateTime createdAt;
  bool isSeen;
  final String storyUrl;

  StoryItem({
    required this.id,
    required this.platform,
    required this.accountUsername,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.mediaUrl,
    this.caption,
    DateTime? createdAt,
    this.isSeen = false,
    required this.storyUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  String get authorHandle => '@$accountUsername';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'accountUsername': accountUsername,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'isSeen': isSeen,
      'storyUrl': storyUrl,
    };
  }

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.instagram,
      ),
      accountUsername: json['accountUsername'] as String,
      authorName: json['authorName'] as String? ?? json['accountUsername'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String? ?? '',
      caption: json['caption'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isSeen: json['isSeen'] as bool? ?? false,
      storyUrl: json['storyUrl'] as String? ?? '',
    );
  }
}
