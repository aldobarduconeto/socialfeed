import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';
import '../services/storage_service.dart';
import '../widgets/unified_post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  final double bottomPadding;
  final VoidCallback onExploreFeed;

  const SavedPostsScreen({
    super.key,
    required this.bottomPadding,
    required this.onExploreFeed,
  });

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<FeedItem> _savedPosts = [];
  bool _isLoading = true;
  SocialPlatform? _selectedPlatform;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    setState(() => _isLoading = true);
    final posts = await StorageService.loadSavedPosts();
    if (mounted) {
      setState(() {
        _savedPosts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Limpar todos os salvos?'),
        content: const Text(
          'Todas as publicações salvas serão removidas dos seus favoritos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAllSavedPosts();
      await _loadSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvos limpos com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _savedPosts.where((item) {
      final matchesPlatform =
          _selectedPlatform == null || item.platform == _selectedPlatform;
      final matchesQuery = _searchQuery.isEmpty ||
          item.caption.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.accountUsername
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.authorName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesPlatform && matchesQuery;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: _loadSaved,
          color: colors.primary,
          child: CustomScrollView(
            key: const PageStorageKey('saved_posts'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header Card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF12151E).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CupertinoIcons.bookmark_fill,
                                size: 18,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Publicações Salvas',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_savedPosts.length} ${_savedPosts.length == 1 ? 'item salvo' : 'itens salvos'} para ler depois',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_savedPosts.isNotEmpty)
                              IconButton(
                                tooltip: 'Limpar todos',
                                icon: const Icon(
                                  CupertinoIcons.trash,
                                  size: 19,
                                  color: Colors.redAccent,
                                ),
                                onPressed: _clearAll,
                              ),
                          ],
                        ),
                        if (_savedPosts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF191D29)
                                  : const Color(0xFFF3F5FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  CupertinoIcons.search,
                                  size: 18,
                                ),
                                hintText: 'Buscar nos salvos...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Filtros de Plataforma
              if (_savedPosts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final platform in [
                            null,
                            ...SocialPlatform.values
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                showCheckmark: false,
                                avatar: Icon(
                                  platform?.iconData ??
                                      CupertinoIcons.square_grid_2x2_fill,
                                  size: 13,
                                  color: _selectedPlatform == platform
                                      ? Colors.white
                                      : (platform?.primaryColor ??
                                          colors.primary),
                                ),
                                label: Text(
                                  platform?.shortName ?? 'Todas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedPlatform == platform
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _selectedPlatform == platform
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                                selected: _selectedPlatform == platform,
                                selectedColor:
                                    platform?.primaryColor ?? colors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedPlatform = platform);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Conteúdo: Loading, Empty ou Lista
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CupertinoActivityIndicator(radius: 16)),
                )
              else if (_savedPosts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary.withValues(alpha: 0.10),
                            ),
                            child: Icon(
                              CupertinoIcons.bookmark,
                              size: 42,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Nenhuma publicação salva',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque no ícone de marcador em qualquer post do feed para guardar publicações importantes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                                CupertinoIcons.square_stack_3d_up,
                                size: 16),
                            label: const Text(
                              'Explorar o feed',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: widget.onExploreFeed,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.search,
                              size: 36, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhum item salvo encontrado para essa busca',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedPlatform = null;
                              });
                            },
                            child: const Text('Limpar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return UnifiedPostCard(
                        key: ValueKey(
                          ('saved', item.platform, item.accountUsername, item.id),
                        ),
                        item: item,
                        onSavedChanged: (isSaved) {
                          if (!isSaved) {
                            setState(() {
                              _savedPosts.removeWhere((p) =>
                                  p.id == item.id &&
                                  p.platform == item.platform);
                            });
                          }
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(height: widget.bottomPadding + 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
