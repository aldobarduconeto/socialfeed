import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';
import '../widgets/unified_post_card.dart';

class VideosScreen extends StatelessWidget {
  final List<FeedItem> allItems;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddAccount;

  const VideosScreen({
    super.key,
    required this.allItems,
    required this.onRefresh,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    final videoItems = allItems.where((i) {
      return i.platform == SocialPlatform.tiktok ||
          i.type == FeedItemType.video ||
          i.type == FeedItemType.reel ||
          (i.videoUrl != null && i.videoUrl!.isNotEmpty);
    }).toList();

    if (videoItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF6C5CE7),
        child: ListView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  CupertinoIcons.play_rectangle_fill,
                  size: 56,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum Vídeo Disponível',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Conecte contas do TikTok ou perfis do Instagram com Reels para reproduzir vídeos diretamente no feed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(CupertinoIcons.plus),
                label: const Text('Adicionar Conta do TikTok/Instagram'),
                onPressed: onAddAccount,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: const Color(0xFF6C5CE7),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            itemCount: videoItems.length,
            itemBuilder: (context, index) {
              final item = videoItems[index];
              return UnifiedPostCard(
                key: ValueKey(('video', item.platform, item.id)),
                item: item,
              );
            },
          ),
        ),
      ),
    );
  }
}
