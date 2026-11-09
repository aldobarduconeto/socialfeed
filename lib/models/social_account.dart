import 'platform_type.dart';

class SocialAccount {
  final String id;
  final SocialPlatform platform;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String? channelId;
  final int? followers;
  final bool? isPrivate;
  final bool isVerified;
  final DateTime addedAt;
  final bool isActive;

  SocialAccount({
    required this.id,
    required this.platform,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.bio = '',
    this.channelId,
    this.followers,
    this.isPrivate,
    this.isVerified = false,
    DateTime? addedAt,
    this.isActive = true,
  }) : addedAt = addedAt ?? DateTime.now();

  String get handle => '@$username';

  String get visibilityLabel => switch (isPrivate) {
        true => 'Perfil privado',
        false => 'Perfil público',
        null => 'Visibilidade não confirmada',
      };

  String get followerLabel {
    final count = followers;
    if (count == null) return 'Seguidores indisponíveis';
    final formatted = count >= 1000000
        ? '${(count / 1000000).toStringAsFixed(1)}M'
        : count >= 1000
            ? '${(count / 1000).toStringAsFixed(1)}K'
            : '$count';
    return '$formatted seguidores';
  }

  SocialAccount copyWith({
    String? id,
    SocialPlatform? platform,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? followers,
    bool? isPrivate,
    bool? isVerified,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      channelId: channelId,
      followers: followers ?? this.followers,
      isPrivate: isPrivate ?? this.isPrivate,
      isVerified: isVerified ?? this.isVerified,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'channelId': channelId,
      'followers': followers,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'addedAt': addedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.instagram,
      ),
      username: json['username'] as String,
      displayName: json['displayName'] as String? ?? json['username'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      channelId: json['channelId'] as String?,
      followers: json.containsKey('isPrivate') || json['followers'] != 0
          ? (json['followers'] as num?)?.toInt()
          : null,
      isPrivate: json['isPrivate'] as bool?,
      isVerified: json['isVerified'] as bool? ?? false,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
