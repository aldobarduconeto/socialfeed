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

class FeedScreen extends StatefulWidget {
  final List<SocialAccount> accounts;
  final List<FeedItem> feedItems;
  final List<StoryItem> stories;
  final bool isLoading;
  final int unavailableAccounts;
  final double bottomPadding;
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
    required this.onRefresh,
    required this.onAddAccount,
    required this.onNavigateToAccounts,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  SocialPlatform? _selectedPlatform;
  String? _selectedAccountId;

  void _openStory(int index) {
    if (widget.stories.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: widget.stories,
          initialIndex: index,
          onStorySeen: (id) async {
            await StorageService.markStoryAsSeen(id);
            setState(() {
              final s = widget.stories.firstWhere(
                (st) => st.id == id,
                orElse: () => widget.stories[0],
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
    final hasFilters = selectedAccount != null || _selectedPlatform != null;

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
      if (matchesPlatform && matchesAccount) {
        filteredFeed.add(item);
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: colors.primary,
          child: CustomScrollView(
            key: const PageStorageKey('unified-feed'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Barra Superior de Criadores Seguidos
              SliverToBoxAdapter(
                child: _buildStoriesTray(context, accounts, isDark, colors),
              ),

              // Barra de Filtros de Plataforma (Cápsulas com contadores)
              SliverToBoxAdapter(
                child: _buildPlatformFilterBar(
                  context,
                  selectedAccount,
                  isDark,
                  colors,
                  platformCounts,
                  widget.feedItems.length,
                ),
              ),

              // Chip de Filtro Ativo por Perfil
              if (selectedAccount != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedAccount.platform.primaryColor
                            .withValues(alpha: isDark ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedAccount.platform.primaryColor
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedAccount.platform.iconData,
                            size: 13,
                            color: selectedAccount.platform.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtrando por @${selectedAccount.username} (${filteredFeed.length})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: selectedAccount.platform.primaryColor,
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
                                  color: selectedAccount.platform.primaryColor,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToAccounts,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                    ? 'Não há publicações para o filtro selecionado no momento.'
                                    : widget.unavailableAccounts > 0
                                        ? 'Os perfis não responderam agora. Tente atualizar o feed.'
                                        : 'Ainda não há novas publicações dos perfis ativos.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
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
                                      ? CupertinoIcons.arrow_counterclockwise
                                      : CupertinoIcons.arrow_clockwise,
                              size: 16,
                            ),
                            label: Text(
                              accounts.isEmpty
                                  ? 'Adicionar perfil'
                                  : hasFilters
                                      ? 'Limpar filtros'
                                      : 'Atualizar feed',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Lista de Posts do Feed Social
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredFeed[index];
                      return RepaintBoundary(
                        child: UnifiedPostCard(
                          key: ValueKey(
                              (item.platform, item.accountUsername, item.id)),
                          item: item,
                        ),
                      );
                    },
                    childCount: filteredFeed.length,
                  ),
                ),

              // Espaçamento inferior para acomodar a dock flutuante de navegação
              SliverToBoxAdapter(
                child: SizedBox(height: widget.bottomPadding + 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de Stories e Criadores Seguidos na parte superior
  Widget _buildStoriesTray(
    BuildContext context,
    List<SocialAccount> accounts,
    bool isDark,
    ColorScheme colors,
  ) {
    return Container(
      height: 104,
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 1 +
            (widget.stories.isNotEmpty
                ? widget.stories.length
                : accounts.length),
        itemBuilder: (context, index) {
          // Primeiro item: Botão "Adicionar"
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
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF151822)
                                : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.person_add,
                              size: 24,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -1,
                          right: -1,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF090B10)
                                    : const Color(0xFFF6F7FB),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.plus,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        'Novo',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
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

          // Itens de Stories reais (se disponíveis)
          if (widget.stories.isNotEmpty) {
            final storyIndex = index - 1;
            final story = widget.stories[storyIndex];
            return StoryCircle(
              story: story,
              onTap: () => _openStory(storyIndex),
            );
          }

          // Criadores seguidos com anel gradiente da sua rede social
          final account = accounts[index - 1];
          final isSelected = _selectedAccountId == account.id;

          return GestureDetector(
            onTap: () => _toggleAccountFilter(account),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(2.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: account.platform.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: account.platform.primaryColor
                                    .withValues(alpha: 0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
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
                            radius: 26.5,
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
                                fontSize: 15,
                                color: account.platform.primaryColor,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: account.platform.primaryColor,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF090B10)
                                      : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                account.platform.iconData,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      account.username,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
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

  /// Barra de Filtro de Plataformas (Estilo Cápsulas / Pills)
  Widget _buildPlatformFilterBar(
    BuildContext context,
    SocialAccount? selectedAccount,
    bool isDark,
    ColorScheme colors,
    Map<SocialPlatform, int> counts,
    int totalCount,
  ) {
    final platforms = <SocialPlatform?>[null, ...SocialPlatform.values];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final platform in platforms) ...[
              _buildFilterPill(
                label: platform?.shortName ?? 'Todas',
                count: platform == null ? totalCount : (counts[platform] ?? 0),
                isSelected: _selectedPlatform == platform,
                icon: platform?.iconData ?? CupertinoIcons.square_grid_2x2_fill,
                brandColor: platform?.primaryColor ?? colors.primary,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedPlatform = platform;
                    if (platform != null &&
                        selectedAccount?.platform != platform) {
                      _selectedAccountId = null;
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor
              : (isDark
                  ? const Color(0xFF141720).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? brandColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
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
}
