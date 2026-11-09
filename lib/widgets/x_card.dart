import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';

class XCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onLikeToggled;

  const XCard({
    super.key,
    required this.item,
    this.onLikeToggled,
  });

  @override
  State<XCard> createState() => _XCardState();
}

class _XCardState extends State<XCard> {
  late bool isLiked;
  late int likesCount;
  bool isRetweeted = false;
  late int sharesCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.item.isLiked;
    likesCount = widget.item.likes;
    sharesCount = widget.item.shares;
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

  void _toggleRetweet() {
    setState(() {
      isRetweeted = !isRetweeted;
      if (isRetweeted) {
        sharesCount++;
      } else {
        sharesCount--;
      }
    });
  }

  Future<void> _openX() async {
    final uri = Uri.parse(widget.item.postUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return DateFormat('dd MMM').format(dt);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'agora';
  }

  List<TextSpan> _buildTweetSpans(String text, BuildContext context, bool isDark) {
    final defaultStyle = TextStyle(
      color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0F1419),
      fontSize: 14.5,
      height: 1.35,
    );
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 14.5,
      height: 1.35,
      fontWeight: FontWeight.w600,
    );

    final List<TextSpan> spans = [];
    final words = text.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isLast = i == words.length - 1;
      final suffix = isLast ? '' : ' ';

      if (word.startsWith('@') || word.startsWith('#') || word.startsWith('http')) {
        spans.add(TextSpan(text: '$word$suffix', style: linkStyle));
      } else {
        spans.add(TextSpan(text: '$word$suffix', style: defaultStyle));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: _openX,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: item.authorAvatarUrl.isNotEmpty
                    ? NetworkImage(item.authorAvatarUrl)
                    : null,
                child: item.authorAvatarUrl.isEmpty
                    ? Text(item.accountUsername[0].toUpperCase())
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Conteúdo do Tweet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com nome, verificado, @ e logo do X
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 15, color: Color(0xFF1D9BF0)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.authorHandle,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' • ${_formatTimeAgo(item.publishedAt)}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      // Ícone de X
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '𝕏',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Texto do Tweet com destaque para # e @
                  RichText(
                    text: TextSpan(
                      children: _buildTweetSpans(item.caption, context, isDark),
                    ),
                  ),

                  // Mídia anexada se houver
                  if (item.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          item.mediaUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Barra de Interação (Replies, Retweet, Curtir, Views, Abrir)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Respostas
                      _TweetStatButton(
                        icon: CupertinoIcons.chat_bubble,
                        text: item.formattedComments,
                        onTap: _openX,
                      ),
                      // Reposts
                      _TweetStatButton(
                        icon: CupertinoIcons.arrow_2_squarepath,
                        text: FeedItem(
                          id: '',
                          platform: SocialPlatform.x,
                          accountUsername: '',
                          authorName: '',
                          authorAvatarUrl: '',
                          publishedAt: DateTime.now(),
                          caption: '',
                          mediaUrls: [],
                          postUrl: '',
                          shares: sharesCount,
                        ).formattedShares,
                        color: isRetweeted ? const Color(0xFF00BA7C) : null,
                        onTap: _toggleRetweet,
                      ),
                      // Curtidas
                      _TweetStatButton(
                        icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        text: FeedItem(
                          id: '',
                          platform: SocialPlatform.x,
                          accountUsername: '',
                          authorName: '',
                          authorAvatarUrl: '',
                          publishedAt: DateTime.now(),
                          caption: '',
                          mediaUrls: [],
                          postUrl: '',
                          likes: likesCount,
                        ).formattedLikes,
                        color: isLiked ? const Color(0xFFF91880) : null,
                        onTap: _toggleLike,
                      ),
                      // Views
                      _TweetStatButton(
                        icon: CupertinoIcons.chart_bar_alt_fill,
                        text: item.formattedViews,
                        onTap: _openX,
                      ),
                      // Abrir no X
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        onPressed: _openX,
                        tooltip: 'Ver no X',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TweetStatButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback onTap;

  const _TweetStatButton({
    required this.icon,
    required this.text,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? defaultColor),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? defaultColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
