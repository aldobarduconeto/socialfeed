import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';

class TikTokCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onLikeToggled;

  const TikTokCard({
    super.key,
    required this.item,
    this.onLikeToggled,
  });

  @override
  State<TikTokCard> createState() => _TikTokCardState();
}

class _TikTokCardState extends State<TikTokCard>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likesCount;
  late AnimationController _discController;

  @override
  void initState() {
    super.initState();
    isLiked = widget.item.isLiked;
    likesCount = widget.item.likes;
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _discController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likesCount++;
        widget.item.isLiked = true;
      } else {
        likesCount--;
        widget.item.isLiked = false;
      }
    });
    widget.onLikeToggled?.call();
  }

  Future<void> _openTikTok() async {
    final uri = Uri.parse(widget.item.postUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
      ),
      elevation: 1,
      child: Stack(
        children: [
          // Background Media
          AspectRatio(
            aspectRatio: 9 / 12,
            child: item.mediaUrls.isNotEmpty
                ? Image.network(
                    item.mediaUrls.first,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white54, size: 50),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(CupertinoIcons.play_rectangle_fill, color: Colors.white30, size: 60),
                    ),
                  ),
          ),

          // Gradiente inferior para legibilidade
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header do card (TikTok badge & views)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00F2FE), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(SocialPlatform.tiktok.iconData, size: 13, color: const Color(0xFF00F2FE)),
                      const SizedBox(width: 4),
                      const Text(
                        'TikTok',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.eye_fill, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedViews,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra Lateral Direita de Interações (estilo clássico do TikTok)
          Positioned(
            right: 12,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar com botão '+'
                GestureDetector(
                  onTap: _openTikTok,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: item.authorAvatarUrl.isNotEmpty
                            ? NetworkImage(item.authorAvatarUrl)
                            : null,
                        child: item.authorAvatarUrl.isEmpty
                            ? Text(item.accountUsername[0].toUpperCase())
                            : null,
                      ),
                      Positioned(
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFE2C55),
                          ),
                          child: const Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Like
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart_fill,
                    color: isLiked ? const Color(0xFFFE2C55) : Colors.white,
                    size: 32,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(
                  item.formattedLikes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Comentários
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    CupertinoIcons.chat_bubble_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _openTikTok,
                ),
                Text(
                  item.formattedComments,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Compartilhar
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    CupertinoIcons.arrowshape_turn_up_right_fill,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: _openTikTok,
                ),
                Text(
                  item.formattedShares,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // Vinil giratório com trilha sonora
                RotationTransition(
                  turns: _discController,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.grey, Colors.black],
                      ),
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações Inferiores (Legenda, @ do criador e áudio)
          Positioned(
            left: 14,
            right: 80,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openTikTok,
                  child: Text(
                    item.authorHandle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.soundTrack ?? 'Som original - ${item.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  onPressed: _openTikTok,
                  child: const Text('Assistir no TikTok', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
