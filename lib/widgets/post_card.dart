import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';

class PostCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onLikeToggled;

  const PostCard({
    super.key,
    required this.item,
    this.onLikeToggled,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likesCount;
  int currentImageIndex = 0;
  bool showHeartAnim = false;
  late AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    isLiked = widget.item.isLiked;
    likesCount = widget.item.likes;
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
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

  void _onDoubleTap() {
    if (!isLiked) {
      _toggleLike();
    }
    setState(() => showHeartAnim = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => showHeartAnim = false);
    });
  }

  Future<void> _openPost() async {
    final uri = Uri.parse(widget.item.postUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCommentsModal() {
    final textController = TextEditingController();
    final localComments = [
      {'user': 'mariasilva', 'text': 'Sensacional! Adorei esse conteúdo 🔥👏'},
      {'user': 'dev_lucas', 'text': 'Incrível demais, parabéns pelo trabalho!'},
      {'user': 'carol.vibes', 'text': 'Que foto linda! Onde foi isso? 😍'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: 480,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comentários',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: localComments.length,
                    itemBuilder: (context, idx) {
                      final c = localComments[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            c['user']![0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          c['user']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(c['text']!),
                        trailing: const Icon(CupertinoIcons.heart, size: 16),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            hintText: 'Adicione um comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: () {
                          if (textController.text.trim().isNotEmpty) {
                            setModalState(() {
                              localComments.add({
                                'user': 'você',
                                'text': textController.text.trim(),
                              });
                              textController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return DateFormat('dd MMM').format(dt);
    } else if (diff.inDays > 0) {
      return 'há ${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return 'há ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'há ${diff.inMinutes}m';
    }
    return 'agora mesmo';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: item.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(item.authorAvatarUrl)
                      : null,
                  child: item.authorAvatarUrl.isEmpty
                      ? Text(item.accountUsername[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: item.platform.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.platform.shortName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.authorHandle} • ${_formatTimeAgo(item.publishedAt)}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.ellipsis, size: 18),
                  onPressed: _openPost,
                  tooltip: 'Abrir publicação original',
                ),
              ],
            ),
          ),

          // Mídia / Imagem
          if (item.mediaUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: _onDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: PageView.builder(
                      itemCount: item.mediaUrls.length,
                      onPageChanged: (idx) =>
                          setState(() => currentImageIndex = idx),
                      itemBuilder: (ctx, idx) => Image.network(
                        item.mediaUrls[idx],
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),

                  // Indicador de Carrossel de múltiplas fotos
                  if (item.mediaUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentImageIndex + 1}/${item.mediaUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Animação de Coração no Double Tap
                  if (showHeartAnim)
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.3).animate(
                        CurvedAnimation(
                          parent: _heartAnimController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        color: Colors.white,
                        size: 90,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black54),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Ações (Like, Comentar, Compartilhar, Abrir link)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.chat_bubble),
                  onPressed: _showCommentsModal,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.share),
                  onPressed: _openPost,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openPost,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Ver no Insta', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Contagem de curtidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$likesCount curtidas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // Legenda
          if (item.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: '${item.accountUsername} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: item.caption),
                  ],
                ),
              ),
            ),

          // Botão ver comentários
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: GestureDetector(
              onTap: _showCommentsModal,
              child: Text(
                'Ver todos os ${item.comments > 0 ? item.comments : 3} comentários',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
