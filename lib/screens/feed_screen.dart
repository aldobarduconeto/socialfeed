import 'dart:ui';
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
    final isDark = theme.brightness == Brightness.dark;
    final accounts =
        widget.accounts.where((account) => account.isActive).toList();
    final selectedAccount = accounts
        .where((account) => account.id == _selectedAccountId)
        .firstOrNull;
    final hasFilters = selectedAccount != null || _selectedPlatform != null;

    final filteredFeed = widget.feedItems.where((item) {
      final matchesPlatform =
          _selectedPlatform == null || item.platform == _selectedPlatform;
      final matchesAccount = selectedAccount == null ||
          (item.platform == selectedAccount.platform &&
              item.accountUsername.toLowerCase() ==
                  selectedAccount.username.toLowerCase());
      return matchesPlatform && matchesAccount;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: const Color(0xFF6C5CE7),
          child: CustomScrollView(
            key: const PageStorageKey('unified-feed'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Barra Superior de Stories / Criadores
              SliverToBoxAdapter(
                child: _buildStoriesTray(context, accounts, isDark),
              ),

              // Barra de Filtros de Plataforma (Estilo Cápsulas Sociais)
              SliverToBoxAdapter(
                child: _buildPlatformFilterBar(
                    context, selectedAccount, isDark, filteredFeed.length),
              ),

              // Chip de Filtro Ativo por Perfil
              if (selectedAccount != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selectedAccount.platform.primaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedAccount.platform.primaryColor
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 8,
                                foregroundImage:
                                    selectedAccount.avatarUrl.isNotEmpty
                                        ? NetworkImage(selectedAccount.avatarUrl)
                                        : null,
                                child: Text(
                                  selectedAccount.username[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '@${selectedAccount.username} · ${selectedAccount.platform.shortName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selectedAccount.platform.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _resetFilters,
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 14,
                                  color: selectedAccount.platform.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Ver todas',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Aviso discreto de contas pendentes
              if (!widget.isLoading && widget.unavailableAccounts > 0)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E212D).withValues(alpha: 0.6)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.info,
                            size: 16, color: Color(0xFF6C5CE7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.unavailableAccounts} contas não responderam na última atualização.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToAccounts,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Gerenciar',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Estado de Carregamento
              if (widget.isLoading && widget.feedItems.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(radius: 18),
                        SizedBox(height: 16),
                        Text(
                          'Sincronizando feeds do TikTok, Instagram e X...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
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
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6C5CE7)
                                  .withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              CupertinoIcons.square_stack_3d_up,
                              size: 42,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma publicação por aqui',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            accounts.isEmpty
                                ? 'Siga contas do TikTok, Instagram ou X para montar seu feed personalizado.'
                                : hasFilters
                                    ? 'Nenhuma publicação encontrada para os filtros selecionados.'
                                    : widget.unavailableAccounts > 0
                                        ? 'Os perfis não responderam no momento. Tente atualizar o feed.'
                                        : 'Ainda não há novas publicações dos perfis ativos.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                      return UnifiedPostCard(
                        key: ValueKey(
                            (item.platform, item.accountUsername, item.id)),
                        item: item,
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
      BuildContext context, List<SocialAccount> accounts, bool isDark) {
    return Container(
      height: 112,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 1 +
            (widget.stories.isNotEmpty
                ? widget.stories.length
                : accounts.length),
        itemBuilder: (context, index) {
          // Primeiro item: Botão "Você / Adicionar"
          if (index == 0) {
            return GestureDetector(
              onTap: _showAddAccountDialog,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1B1E2B)
                                : const Color(0xFFE8ECF5),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/icon/socialfeed.png',
                                width: 28,
                                height: 28,
                                errorBuilder: (_, __, ___) => const Icon(
                                  CupertinoIcons.person_crop_circle,
                                  size: 32,
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F1117)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.plus,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const SizedBox(
                      width: 72,
                      child: Text(
                        'Adicionar',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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

          // Ou criadores seguidos com anel gradiente da sua rede social
          final account = accounts[index - 1];
          final isSelected = _selectedAccountId == account.id;

          return GestureDetector(
            onTap: () => _toggleAccountFilter(account),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.6),
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
                                    .withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: account.platform.primaryColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF0F1117)
                            : const Color(0xFFF8F9FD),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            foregroundImage: account.avatarUrl.isNotEmpty
                                ? NetworkImage(account.avatarUrl)
                                : null,
                            child: account.avatarUrl.isEmpty
                                ? Text(
                                    account.username.isNotEmpty
                                        ? account.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: account.platform.primaryColor,
                                    ),
                                  )
                                : null,
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
                                      ? const Color(0xFF0F1117)
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
                    width: 72,
                    child: Text(
                      '@${account.username}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? account.platform.primaryColor : null,
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
  Widget _buildPlatformFilterBar(BuildContext context,
      SocialAccount? selectedAccount, bool isDark, int postCount) {
    final platforms = <SocialPlatform?>[null, ...SocialPlatform.values];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final platform in platforms) ...[
              _buildFilterPill(
                label: platform?.shortName ?? 'Todas',
                isSelected: _selectedPlatform == platform,
                icon: platform?.iconData ?? CupertinoIcons.sparkles,
                brandColor: platform?.primaryColor ?? const Color(0xFF6C5CE7),
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
    required bool isSelected,
    required IconData icon,
    required Color brandColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor
              : (isDark
                  ? const Color(0xFF191C26).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? brandColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
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
          ],
        ),
      ),
    );
  }
}
