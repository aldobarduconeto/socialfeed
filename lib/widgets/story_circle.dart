import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/story_item.dart';

class StoryCircle extends StatelessWidget {
  final StoryItem story;
  final VoidCallback onTap;

  const StoryCircle({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Anel com gradiente líquido e sombra com refração
            Container(
              padding: const EdgeInsets.all(2.8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isSeen
                    ? null
                    : LinearGradient(
                        colors: story.platform.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: story.isSeen
                    ? (isDark ? Colors.white24 : Colors.black12)
                    : null,
                boxShadow: story.isSeen
                    ? null
                    : [
                        BoxShadow(
                          color: story.platform.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FD),
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      backgroundImage: story.authorAvatarUrl.isNotEmpty
                          ? NetworkImage(story.authorAvatarUrl)
                          : null,
                      child: story.authorAvatarUrl.isEmpty
                          ? Text(
                              story.accountUsername.isNotEmpty
                                  ? story.accountUsername[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: story.platform.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    // Badge da plataforma em Liquid Glass
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: story.platform.primaryColor,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F1117) : Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: story.platform.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              story.platform.iconData,
                              size: 9.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                story.authorName.isNotEmpty
                    ? story.authorName
                    : story.accountUsername,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: story.isSeen ? FontWeight.normal : FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
