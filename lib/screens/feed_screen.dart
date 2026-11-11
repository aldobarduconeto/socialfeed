import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../models/feed_item.dart';
import '../models/story_item.dart';
import '../widgets/story_circle.dart';
import '../widgets/story_viewer_screen.dart';
import '../widgets/unified_post_card.dart';
import '../widgets/add_account_dialog.dart';
import '../services/storage_service.dart';

enum MediaTypeFilter {
  all('Tudo', CupertinoIcons.square_grid_2x2),
  videos('Vídeos', CupertinoIcons.play_circle_fill),
  photos('Fotos', CupertinoIcons.photo_fill),
  text('Texto', CupertinoIcons.text_quote);

  final String label;
  final IconData icon;
  const MediaTypeFilter(this.label, this.icon);
}

enum FeedSortOption {
  newest('Mais recentes', CupertinoIcons.time),
  mostLiked('Mais curtidos', CupertinoIcons.heart_fill),
  mostCommented('Mais comentados', CupertinoIcons.chat_bubble_2_fill);

  final String label;
  final IconData icon;
  const FeedSortOption(this.label, this.icon);
}

class FeedScreen extends StatefulWidget {
  final List<SocialAccount> accounts;
  final List<FeedItem> feedItems;
  final List<StoryItem> stories;
  final bool isLoading;
  final int unavailableAccounts;
  final double bottomPadding;
  final bool isCompact;
  final Future<void> Function() onRefresh;
  final Function(SocialAccount account) onAddAccount;
  final VoidCallback onNavigateToAccounts;

  const FeedScreen({
    super.key,
    required this.accounts,
    required this.feedItems,
    required this.stories,
    required this.isLoading,
    required this.unavailableAccounts,
    required this.bottomPadding,
    this.isCompact = false,
    required this.onRefresh,
    required this.onAddAccount,
    required this.onNavigateToAccounts,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  SocialPlatform? _selectedPlatform;
  String? _selectedAccountId;
  MediaTypeFilter _mediaFilter = MediaTypeFilter.all;
  FeedSortOption _sortOption = FeedSortOption.newest;
  String _searchQuery = '';
  bool _showSearchBar = false;
  bool _showScrollToTop = false;
  Set<String> _seenStoryIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSeenStories();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 400;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  Future<void> _loadSeenStories() async {
    final seen = await StorageService.loadSeenStories();
    if (mounted) setState(() => _seenStoryIds = seen);
  }

  void _scrollToTop() {
    HapticFeedback.selectionClick();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  List<StoryItem> _buildDynamicStories(List<SocialAccount> activeAccounts) {
    if (widget.stories.isNotEmpty) return widget.stories;

    final stories = <StoryItem>[];
    for (final account in activeAccounts) {
      final latestPostWithMedia = widget.feedItems.where((item) {
        return item.platform == account.platform &&
            item.accountUsername.toLowerCase() ==
                account.username.toLowerCase() &&
            item.mediaUrls.isNotEmpty;
      }).firstOrNull;

      if (latestPostWithMedia != null) {
        final storyId = 'story_${account.id}_${latestPostWithMedia.id}';
        stories.add(
          StoryItem(
            id: storyId,
            platform: account.platform,
            accountUsername: account.username,
            authorName: account.displayName,
            authorAvatarUrl: account.avatarUrl,
            mediaUrl: latestPostWithMedia.mediaUrls.first,
            caption: latestPostWithMedia.caption.isNotEmpty
                ? latestPostWithMedia.caption
                : null,
            createdAt: latestPostWithMedia.publishedAt,
            storyUrl: latestPostWithMedia.postUrl,
            isSeen: _seenStoryIds.contains(storyId),
          ),
        );
      }
    }
    return stories;
  }

  void _openStory(int index, List<StoryItem> stories) {
    if (stories.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: stories,
          initialIndex: index,
          onStorySeen: (id) async {
            await StorageService.markStoryAsSeen(id);
            setState(() {
              _seenStoryIds.add(id);
              final s = stories.firstWhere(
                (st) => st.id == id,
                orElse: () => stories[0],
              );
              s.isSeen = true;
            });
          },
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AddAccountDialog(
        onAccountAdded: widget.onAddAccount,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedPlatform = null;
      _selectedAccountId = null;
      _mediaFilter = MediaTypeFilter.all;
      _searchQuery = '';
      _searchController.clear();
      _showSearchBar = false;
    });
  }

  void _toggleAccountFilter(SocialAccount account) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAccountId == account.id) {
        _selectedAccountId = null;
      } else {
        _selectedAccountId = account.id;
        _selectedPlatform = account.platform;
      }
    });
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Ordenar publicações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                for (final option in FeedSortOption.values)
                  ListTile(
                    leading: Icon(
                      option.icon,
                      color: _sortOption == option
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: _sortOption == option
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _sortOption == option
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: _sortOption == option
                        ? Icon(
                            CupertinoIcons.checkmark,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      setState(() => _sortOption = option);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accounts =
        widget.accounts.where((account) => account.isActive).toList();
    final selectedAccount = accounts
        .where((account) => account.id == _selectedAccountId)
        .firstOrNull;
    final hasFilters = selectedAccount != null ||
        _selectedPlatform != null ||
        _mediaFilter != MediaTypeFilter.all ||
        _searchQuery.isNotEmpty;

    final dynamicStories = _buildDynamicStories(accounts);

    // Filtragem e ordenação
    final platformCounts = <SocialPlatform, int>{};
    final filteredFeed = <FeedItem>[];
    final selectedUsernameLower = selectedAccount?.username.toLowerCase();

    for (final item in widget.feedItems) {
      platformCounts[item.platform] = (platformCounts[item.platform] ?? 0) + 1;

      final matchesPlatform =
          _selectedPlatform == null || item.platform == _selectedPlatform;
      final matchesAccount = selectedAccount == null ||
          (item.platform == selectedAccount.platform &&
              item.accountUsername.toLowerCase() == selectedUsernameLower);

      final isVideo = item.platform == SocialPlatform.tiktok ||
          item.platform == SocialPlatform.youtube ||
          item.type == FeedItemType.reel ||
          item.type == FeedItemType.video ||
          (item.videoUrl != null && item.videoUrl!.isNotEmpty);
      final isPhoto = item.mediaUrls.isNotEmpty && !isVideo;
      final isTextOnly = item.mediaUrls.isEmpty && !isVideo;

      final matchesMedia = switch (_mediaFilter) {
        MediaTypeFilter.all => true,
        MediaTypeFilter.videos => isVideo,
        MediaTypeFilter.photos => isPhoto,
        MediaTypeFilter.text => isTextOnly,
      };

      final matchesQuery = _searchQuery.isEmpty ||
          item.caption.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.accountUsername
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.authorName.toLowerCase().contains(_searchQuery.toLowerCase());

      if (matchesPlatform && matchesAccount && matchesMedia && matchesQuery) {
        filteredFeed.add(item);
      }
    }

    // Ordenação
    switch (_sortOption) {
      case FeedSortOption.newest:
        filteredFeed.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case FeedSortOption.mostLiked:
        filteredFeed.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case FeedSortOption.mostCommented:
        filteredFeed.sort((a, b) => b.comments.compareTo(a.comments));
        break;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: colors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                key: const PageStorageKey('unified-feed'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Barra Superior de Stories / Criadores
                  SliverToBoxAdapter(
                    child: _buildStoriesTray(
                      context: context,
                      accounts: accounts,
                      stories: dynamicStories,
                      isDark: isDark,
                      colors: colors,
                    ),
                  ),

                  // Barra de Busca e Filtros
                  SliverToBoxAdapter(
                    child: _buildControlsBar(
                      context: context,
                      isDark: isDark,
                      colors: colors,
                      counts: platformCounts,
                      totalCount: widget.feedItems.length,
                    ),
                  ),

                  // Chip de Filtro Ativo
                  if (hasFilters)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primary
                                .withValues(alpha: isDark ? 0.14 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.slider_horizontal_3,
                                size: 13,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filtro ativo: ${selectedAccount != null ? '@${selectedAccount.username} · ' : ''}${_selectedPlatform != null ? '${_selectedPlatform!.shortName} · ' : ''}${_mediaFilter != MediaTypeFilter.all ? '${_mediaFilter.label} · ' : ''}${_searchQuery.isNotEmpty ? '"$_searchQuery" · ' : ''}(${filteredFeed.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _resetFilters,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  child: Text(
                                    'Limpar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Aviso discreto de contas pendentes
                  if (!widget.isLoading && widget.unavailableAccounts > 0)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF151822)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.info_circle,
                                size: 16, color: colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.unavailableAccounts} ${widget.unavailableAccounts == 1 ? 'perfil não respondeu' : 'perfis não responderam'} na última sincronização.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onNavigateToAccounts,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text(
                                'Ver contas',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Estado de Carregamento
                  if (widget.isLoading && widget.feedItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(radius: 16),
                            const SizedBox(height: 16),
                            Text(
                              'Sincronizando publicações...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instagram · TikTok · X · YouTube',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Estado Vazio
                  else if (filteredFeed.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary.withValues(alpha: 0.10),
                                ),
                                child: Icon(
                                  CupertinoIcons.square_stack_3d_up,
                                  size: 38,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma publicação encontrada',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                accounts.isEmpty
                                    ? 'Adicione perfis do Instagram, TikTok, X ou YouTube para acompanhar tudo em um só lugar.'
                                    : hasFilters
                                        ? 'Não há publicações para os filtros ou busca selecionada.'
                                        : 'Ainda não há novas publicações dos perfis ativos.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: accounts.isEmpty
                                    ? widget.accounts.isEmpty
                                        ? _showAddAccountDialog
                                        : widget.onNavigateToAccounts
                                    : hasFilters
                                        ? _resetFilters
                                        : widget.onRefresh,
                                icon: Icon(
                                  accounts.isEmpty
                                      ? CupertinoIcons.plus
                                      : hasFilters
                                          ? CupertinoIcons
                                              .arrow_counterclockwise
                                          : CupertinoIcons.arrow_clockwise,
                                  size: 16,
                                ),
                                label: Text(
                                  accounts.isEmpty
                                      ? 'Adicionar perfil'
                                      : hasFilters
                                          ? 'Limpar filtros'
                                          : 'Atualizar feed',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Lista de Posts do Feed
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredFeed[index];
                          return RepaintBoundary(
                            child: UnifiedPostCard(
                              key: ValueKey(
                                (item.platform, item.accountUsername, item.id),
                              ),
                              item: item,
                              isCompact: widget.isCompact,
                            ),
                          );
                        },
                        childCount: filteredFeed.length,
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: widget.bottomPadding + 24),
                  ),
                ],
              ),
            ),

            // Botão Flutuante Voltar ao Topo
            if (_showScrollToTop)
              Positioned(
                bottom: widget.bottomPadding + 14,
                right: 18,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, val, child) => Transform.scale(
                    scale: val,
                    child: Opacity(opacity: val, child: child),
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'scroll_to_top',
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    onPressed: _scrollToTop,
                    icon: const Icon(CupertinoIcons.arrow_up, size: 16),
                    label: const Text(
                      'Topo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Barra de Stories e Criadores Seguidos
  Widget _buildStoriesTray({
    required BuildContext context,
    required List<SocialAccount> accounts,
    required List<StoryItem> stories,
    required bool isDark,
    required ColorScheme colors,
  }) {
    final storyAccounts = <String, StoryItem>{};
    for (final s in stories) {
      storyAccounts['${s.platform.name}_${s.accountUsername.toLowerCase()}'] = s;
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 1 + accounts.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _showAddAccountDialog,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF141720)
                                : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.plus,
                              size: 20,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 62,
                      child: Text(
                        'Seguir',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final account = accounts[index - 1];
          final storyKey =
              '${account.platform.name}_${account.username.toLowerCase()}';
          final story = storyAccounts[storyKey];
          final isSelected = _selectedAccountId == account.id;

          return GestureDetector(
            onTap: () {
              if (story != null) {
                final storyIdx = stories.indexOf(story);
                if (storyIdx >= 0) {
                  _openStory(storyIdx, stories);
                  return;
                }
              }
              _toggleAccountFilter(account);
            },
            onLongPress: () => _toggleAccountFilter(account),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(2.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (story != null && !story.isSeen) || isSelected
                          ? LinearGradient(
                              colors: account.platform.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: story != null && story.isSeen
                          ? (isDark ? Colors.white24 : Colors.black12)
                          : Colors.transparent,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF090B10)
                            : const Color(0xFFF6F7FB),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: isDark
                                ? const Color(0xFF171A24)
                                : const Color(0xFFECEFF7),
                            foregroundImage: account.avatarUrl.isNotEmpty
                                ? NetworkImage(account.avatarUrl)
                                : null,
                            child: Text(
                              account.username.isNotEmpty
                                  ? account.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: account.platform.primaryColor,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: account.platform.primaryColor,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF090B10)
                                      : Colors.white,
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                account.platform.iconData,
                                size: 7.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 62,
                    child: Text(
                      account.username,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? account.platform.primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Barra de Controles: Busca limpa, Filtros em fita única e Ordenação rápida
  Widget _buildControlsBar({
    required BuildContext context,
    required bool isDark,
    required ColorScheme colors,
    required Map<SocialPlatform, int> counts,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        children: [
          // Campo de Busca Moderno e Integrado
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141720)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(CupertinoIcons.search, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Filtrar feed, legenda ou @criador...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                IconButton(
                  tooltip: 'Ordenar publicações',
                  icon: Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    size: 16,
                    color: _sortOption != FeedSortOption.newest
                        ? colors.primary
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: _showSortSheet,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Fita Única de Filtros (Redes Sociais + Tipos de Mídia)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Redes
                for (final platform in [null, ...SocialPlatform.values]) ...[
                  _buildFilterPill(
                    label: platform?.shortName ?? 'Todas',
                    count: platform == null
                        ? totalCount
                        : (counts[platform] ?? 0),
                    isSelected: _selectedPlatform == platform,
                    icon: platform?.iconData ??
                        CupertinoIcons.square_grid_2x2_fill,
                    brandColor: platform?.primaryColor ?? colors.primary,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedPlatform = platform;
                        if (platform != null && _selectedAccountId != null) {
                          final selected = widget.accounts
                              .where((a) => a.id == _selectedAccountId)
                              .firstOrNull;
                          if (selected?.platform != platform) {
                            _selectedAccountId = null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                ],

                // Separador sutil
                Container(
                  height: 18,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(width: 4),

                // Tipos de Mídia
                for (final filter in MediaTypeFilter.values) ...[
                  _buildMediaPill(
                    filter: filter,
                    isSelected: _mediaFilter == filter,
                    colors: colors,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mediaFilter = filter);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required IconData icon,
    required Color brandColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor
              : (isDark
                  ? const Color(0xFF141720).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? brandColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPill({
    required MediaTypeFilter filter,
    required bool isSelected,
    required ColorScheme colors,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
                  ? const Color(0xFF141720).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 11.5,
              color: isSelected
                  ? colors.primary
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 5),
            Text(
              filter.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colors.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
