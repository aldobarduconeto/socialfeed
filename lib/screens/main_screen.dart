import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/social_account.dart';
import '../models/platform_type.dart';
import '../models/feed_item.dart';
import '../services/storage_service.dart';
import '../services/social_service.dart';
import 'feed_screen.dart';
import 'anonymous_search_screen.dart';
import 'saved_posts_screen.dart';
import 'accounts_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTab = 0;
  final _visitedTabs = <int>{0};
  bool _isLoading = false;
  bool _isCompactView = false;

  List<SocialAccount> _accounts = [];
  List<FeedItem> _feedItems = [];
  int _refreshGeneration = 0;
  int _unavailableAccounts = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final (savedAccounts, cachedFeed, compact) = await (
      StorageService.loadAccounts(),
      StorageService.loadCachedFeed(),
      StorageService.loadCompactView(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _accounts = savedAccounts;
      _feedItems = cachedFeed;
      _isCompactView = compact;
    });
    await _refreshContent();
  }

  Future<void> _refreshContent() async {
    if (!mounted) return;
    final generation = ++_refreshGeneration;
    final accounts = _accounts.where((account) => account.isActive).toList();
    final cached = _feedItems;
    setState(() => _isLoading = true);

    final cachedByAccount = <(SocialPlatform, String), List<FeedItem>>{};
    for (final item in cached) {
      final key = (item.platform, item.accountUsername.toLowerCase());
      (cachedByAccount[key] ??= []).add(item);
    }

    final feed = <FeedItem>[];
    final profiles = <String, SocialAccount>{};
    var unavailable = 0;
    const batchSize = 3;
    for (var offset = 0; offset < accounts.length; offset += batchSize) {
      final batch = accounts.skip(offset).take(batchSize);
      final results = await Future.wait(batch.map((account) async {
        final metadata = account.platform == SocialPlatform.instagram
            ? SocialService.findPublicProfile(
                account.platform, account.username)
            : Future<SocialAccount?>.value();
        List<FeedItem>? items;
        try {
          items = await SocialService.fetchAccountFeed(account);
        } catch (_) {}
        return (items, await metadata);
      }));
      if (!mounted || generation != _refreshGeneration) return;
      for (var index = 0; index < results.length; index++) {
        final account = accounts[offset + index];
        final (items, profile) = results[index];
        if (profile != null) profiles[account.id] = profile;
        if (items == null) {
          unavailable++;
          final key = (account.platform, account.username.toLowerCase());
          feed.addAll(cachedByAccount[key] ?? const []);
        } else {
          feed.addAll(items);
        }
      }
    }
    feed.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    setState(() {
      _feedItems = feed;
      _accounts = [
        for (final account in _accounts)
          if (profiles[account.id] case final profile?)
            profile.copyWith(
              id: account.id,
              addedAt: account.addedAt,
              isActive: account.isActive,
              followers: profile.followers ?? account.followers,
              isPrivate: profile.isPrivate ?? account.isPrivate,
            )
          else
            account,
      ];
      _unavailableAccounts = unavailable;
      _isLoading = false;
    });
    await StorageService.saveCachedFeed(feed);
  }

  Future<void> _followSearchResults(List<SocialAccount> accounts) async {
    final updated = await StorageService.addAccounts(accounts);
    if (!mounted) return;
    setState(() => _accounts = updated);
    unawaited(_refreshContent());
  }

  Future<void> _addAccount(SocialAccount newAccount) async {
    final updated = await StorageService.addAccount(newAccount);
    if (!mounted) return;
    setState(() {
      _accounts = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seguindo @${newAccount.username} (${newAccount.platform.shortName})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF635BFF),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await _refreshContent();
  }

  Future<void> _removeAccount(String accountId) async {
    final updated = await StorageService.removeAccount(accountId);
    if (!mounted) return;
    setState(() {
      _accounts = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conta removida do seu feed.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await _refreshContent();
  }

  Future<void> _toggleAccount(String accountId) async {
    final updated = await StorageService.toggleAccountActive(accountId);
    if (!mounted) return;
    setState(() {
      _accounts = updated;
    });
    await _refreshContent();
  }

  Future<void> _clearCache() async {
    await StorageService.saveCachedFeed([]);
    setState(() {
      _feedItems = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache limpo com sucesso!'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    await _refreshContent();
  }

  Future<void> _resetDefaults() async {
    final starters = StorageService.getStarterAccounts();
    await StorageService.saveAccounts(starters);
    setState(() {
      _accounts = starters;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contas padrão restauradas com sucesso!'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    await _refreshContent();
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AddAccountDialog(onAccountAdded: _addAccount),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _currentTab = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = width >= 640;
    final pinDrawer = width >= 1040;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeCount = _accounts.where((a) => a.isActive).length;

    return LiquidBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBody: !useDrawer,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF090B10).withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.78),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: pinDrawer ? 24 : 16,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF635BFF), Color(0xFF8B80FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF635BFF)
                                  .withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset(
                            'assets/icon/socialfeed.png',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.square_stack_3d_up_fill,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SocialFeed',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          letterSpacing: -0.5,
                          color:
                              isDark ? Colors.white : const Color(0xFF111420),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (activeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$activeCount ${activeCount == 1 ? 'ativo' : 'ativos'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CupertinoActivityIndicator(radius: 7.5),
                            ),
                            if (width >= 420) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Sincronizando',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      IconButton(
                        icon:
                            const Icon(CupertinoIcons.arrow_clockwise, size: 19),
                        tooltip: 'Atualizar feed',
                        onPressed: _refreshContent,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              colors.primary.withValues(alpha: 0.12),
                          foregroundColor: colors.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showAddAccountDialog,
                        icon: const Icon(CupertinoIcons.add, size: 15),
                        label: const Text(
                          'Seguindo',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        drawer: useDrawer && !pinDrawer ? _buildDrawer(modal: true) : null,
        body: SafeArea(
          bottom: useDrawer,
          child: Row(
            children: [
              if (pinDrawer)
                SizedBox(
                  width: 244,
                  child: _buildSidebar(isDark: isDark, colors: colors),
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    // 0. Feed Unificado
                    if (_visitedTabs.contains(0))
                      TickerMode(
                        enabled: _currentTab == 0,
                        child: FeedScreen(
                          accounts: _accounts,
                          feedItems: _feedItems,
                          stories: const [],
                          unavailableAccounts: _unavailableAccounts,
                          bottomPadding: useDrawer ? 24 : 100,
                          isCompact: _isCompactView,
                          isLoading: _isLoading,
                          onRefresh: _refreshContent,
                          onAddAccount: _addAccount,
                          onNavigateToAccounts: () => _selectTab(3),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // 1. Busca de Perfis
                    if (_visitedTabs.contains(1))
                      TickerMode(
                        enabled: _currentTab == 1,
                        child: AnonymousSearchScreen(
                          currentAccounts: _accounts,
                          onFollowAccounts: _followSearchResults,
                          bottomPadding: useDrawer ? 24 : 100,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // 2. Publicações Salvas
                    if (_visitedTabs.contains(2))
                      TickerMode(
                        enabled: _currentTab == 2,
                        child: SavedPostsScreen(
                          bottomPadding: useDrawer ? 24 : 100,
                          onExploreFeed: () => _selectTab(0),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // 3. Gerenciamento de Contas
                    if (_visitedTabs.contains(3))
                      TickerMode(
                        enabled: _currentTab == 3,
                        child: AccountsScreen(
                          accounts: _accounts,
                          onAddAccount: _addAccount,
                          onRemoveAccount: _removeAccount,
                          onToggleAccount: _toggleAccount,
                          bottomPadding: useDrawer ? 24 : 100,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // 4. Ajustes & Insights
                    if (_visitedTabs.contains(4))
                      TickerMode(
                        enabled: _currentTab == 4,
                        child: SettingsScreen(
                          currentTheme: widget.currentTheme,
                          onThemeChanged: widget.onThemeChanged,
                          isCompactView: _isCompactView,
                          onCompactViewChanged: (val) {
                            setState(() => _isCompactView = val);
                            StorageService.saveCompactView(val);
                          },
                          accounts: _accounts,
                          feedItems: _feedItems,
                          onClearCache: _clearCache,
                          onResetDefaults: _resetDefaults,
                          onBackupImported: _loadInitialData,
                          bottomPadding: useDrawer ? 24 : 100,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: useDrawer
            ? null
            : LiquidGlassNavigationBar(
                selectedIndex: _currentTab,
                onItemSelected: _selectTab,
                items: _destinations,
              ),
      ),
    );
  }

  static const _destinations = [
    LiquidNavItem(
      icon: CupertinoIcons.square_stack_3d_up,
      selectedIcon: CupertinoIcons.square_stack_3d_up_fill,
      label: 'Feed',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.search,
      selectedIcon: CupertinoIcons.search,
      label: 'Explorar',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.bookmark,
      selectedIcon: CupertinoIcons.bookmark_fill,
      label: 'Salvos',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.person_2,
      selectedIcon: CupertinoIcons.person_2_fill,
      label: 'Contas',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.slider_horizontal_3,
      selectedIcon: CupertinoIcons.slider_horizontal_3,
      label: 'Ajustes',
    ),
  ];

  Widget _buildSidebar({required bool isDark, required ColorScheme colors}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1017).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.65),
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              'NAVEGAÇÃO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final (index, dest) in _destinations.indexed) ...[
            _SidebarItem(
              item: dest,
              isSelected: _currentTab == index,
              badge: index == 3 && _accounts.isNotEmpty
                  ? '${_accounts.length}'
                  : null,
              onTap: () => _selectTab(index),
            ),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.sparkles,
                        size: 15, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Feed Unificado',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Acompanhe Instagram, TikTok, X e YouTube sem algoritmos.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer({required bool modal}) => NavigationDrawer(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          _selectTab(index);
          if (modal) _scaffoldKey.currentState?.closeDrawer();
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: Text(
              'SocialFeed',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final destination in _destinations)
            NavigationDrawerDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
      );
}

class _SidebarItem extends StatelessWidget {
  final LiquidNavItem item;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? colors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 19,
                color: isSelected
                    ? colors.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colors.primary
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : (isDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
