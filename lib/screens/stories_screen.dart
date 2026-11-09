import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/story_item.dart';
import '../widgets/story_viewer_screen.dart';
import '../services/storage_service.dart';

class StoriesScreen extends StatefulWidget {
  final List<StoryItem> stories;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddAccount;

  const StoriesScreen({
    super.key,
    required this.stories,
    required this.onRefresh,
    required this.onAddAccount,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  void _openStory(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: widget.stories,
          initialIndex: index,
          onStorySeen: (id) async {
            await StorageService.markStoryAsSeen(id);
            setState(() {
              final s = widget.stories.firstWhere((st) => st.id == id, orElse: () => widget.stories[0]);
              s.isSeen = true;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Icon(
                CupertinoIcons.circle_grid_3x3,
                size: 70,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum Story Disponível',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Adicione contas do Instagram ou TikTok para visualizar stories públicos atualizados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                icon: const Icon(CupertinoIcons.plus),
                label: const Text('Adicionar Conta'),
                onPressed: widget.onAddAccount,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return GestureDetector(
            onTap: () => _openStory(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      story.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: story.isSeen ? Colors.grey : story.platform.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: story.authorAvatarUrl.isNotEmpty
                              ? NetworkImage(story.authorAvatarUrl)
                              : null,
                          child: story.authorAvatarUrl.isEmpty
                              ? Text(story.accountUsername[0].toUpperCase())
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: story.platform.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          story.platform.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            story.authorHandle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                          if (story.caption != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              story.caption!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
