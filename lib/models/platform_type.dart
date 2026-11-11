import 'package:flutter/cupertino.dart';

enum SocialPlatform {
  instagram,
  tiktok,
  x,
  youtube;

  String get displayName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.x:
        return 'X (Twitter)';
      case SocialPlatform.youtube:
        return 'YouTube';
    }
  }

  String get shortName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.x:
        return 'X';
      case SocialPlatform.youtube:
        return 'YouTube';
    }
  }

  Color get primaryColor {
    switch (this) {
      case SocialPlatform.instagram:
        return const Color(0xFFE1306C);
      case SocialPlatform.tiktok:
        return const Color(0xFF00F2FE);
      case SocialPlatform.x:
        return const Color(0xFF1DA1F2);
      case SocialPlatform.youtube:
        return const Color(0xFFFF0033);
    }
  }

  Color get accentColor {
    switch (this) {
      case SocialPlatform.instagram:
        return const Color(0xFFF77737);
      case SocialPlatform.tiktok:
        return const Color(0xFFFE2C55);
      case SocialPlatform.x:
        return const Color(0xFF0F1419);
      case SocialPlatform.youtube:
        return const Color(0xFFFF694F);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case SocialPlatform.instagram:
        return const [
          Color(0xFF833AB4),
          Color(0xFFFD1D1D),
          Color(0xFFFCB045),
        ];
      case SocialPlatform.tiktok:
        return const [
          Color(0xFF00F2FE),
          Color(0xFFFE2C55),
        ];
      case SocialPlatform.x:
        return const [
          Color(0xFF1DA1F2),
          Color(0xFF14171A),
        ];
      case SocialPlatform.youtube:
        return const [Color(0xFFFF0033), Color(0xFFB60029)];
    }
  }

  IconData get iconData {
    switch (this) {
      case SocialPlatform.instagram:
        return CupertinoIcons.camera_fill;
      case SocialPlatform.tiktok:
        return CupertinoIcons.play_circle_fill;
      case SocialPlatform.x:
        return CupertinoIcons.bubble_left_bubble_right_fill;
      case SocialPlatform.youtube:
        return CupertinoIcons.play_rectangle_fill;
    }
  }

  String profileUrl(String username) {
    final clean = username.replaceAll('@', '').trim();
    switch (this) {
      case SocialPlatform.instagram:
        return 'https://www.instagram.com/$clean/';
      case SocialPlatform.tiktok:
        return 'https://www.tiktok.com/@$clean';
      case SocialPlatform.x:
        return 'https://x.com/$clean';
      case SocialPlatform.youtube:
        return RegExp(r'^UC[\w-]{22}$').hasMatch(clean)
            ? 'https://www.youtube.com/channel/$clean'
            : 'https://www.youtube.com/@$clean';
    }
  }
}
