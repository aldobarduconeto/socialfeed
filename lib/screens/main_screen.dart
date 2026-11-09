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

    final (savedAccounts, cachedFeed) = await (
      StorageService.loadAccounts(),
      StorageService.loadCachedFeed(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _accounts = savedAccounts;
      _feedItems = cachedFeed;
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
    await StorageService.addAccounts(accounts);
    final updated = await StorageService.loadAccounts();
    if (!mounted) return;
    setState(() => _accounts = updated);
    unawaited(_refreshContent());
  }

  Future<void> _addAccount(SocialAccount newAccount) async {
    await StorageService.addAccount(newAccount);
    final updated = await StorageService.loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seguindo @${newAccount.username} (${newAccount.platform.shortName}) no SocialFeed.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6C5CE7),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await _refreshContent();
  }

  Future<void> _removeAccount(String accountId) async {
    await StorageService.removeAccount(accountId);
    final updated = await StorageService.loadAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conta removida com sucesso.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await _refreshContent();
  }

  Future<void> _toggleAccount(String accountId) async {
    await StorageService.toggleAccountActive(accountId);
    final updated = await StorageService.loadAccounts();
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
    final useDrawer = width >= 600;
    final pinDrawer = width >= 1100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBody: !useDrawer,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AppBar(
                backgroundColor: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/icon/socialfeed.png',
                          width: 24, height: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SocialFeed',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF1E1E2F),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator(),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_clockwise),
                      tooltip: 'Atualizar feed unificado',
                      onPressed: () => _refreshContent(),
                    ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.plus_circle_fill),
                    tooltip: 'Adicionar conta',
                    color: const Color(0xFF6C5CE7),
                    onPressed: _showAddAccountDialog,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
        drawer: useDrawer && !pinDrawer ? _buildDrawer(modal: true) : null,
        body: SafeArea(
          bottom: useDrawer,
          child: Row(children: [
            if (pinDrawer)
              SizedBox(width: 248, child: _buildDrawer(modal: false)),
            Expanded(
                child: IndexedStack(
              index: _currentTab,
              children: [
                // 0. Feed Unificado Liquid Glass
                if (_visitedTabs.contains(0))
                  TickerMode(
                      enabled: _currentTab == 0,
                      child: FeedScreen(
                        accounts: _accounts,
                        feedItems: _feedItems,
                        stories: const [],
                        unavailableAccounts: _unavailableAccounts,
                        bottomPadding: useDrawer ? 24 : 100,
                        isLoading: _isLoading,
                        onRefresh: () => _refreshContent(),
                        onAddAccount: _addAccount,
                        onNavigateToAccounts: () => _selectTab(2),
                      ))
                else
                  const SizedBox.shrink(),
                // 1. Busca Invisível / Sem Rastros
                if (_visitedTabs.contains(1))
                  TickerMode(
                      enabled: _currentTab == 1,
                      child: AnonymousSearchScreen(
                        currentAccounts: _accounts,
                        onFollowAccounts: _followSearchResults,
                        bottomPadding: useDrawer ? 24 : 100,
                      ))
                else
                  const SizedBox.shrink(),
                // 2. Gerenciamento de Contas
                if (_visitedTabs.contains(2))
                  TickerMode(
                      enabled: _currentTab == 2,
                      child: AccountsScreen(
                        accounts: _accounts,
                        onAddAccount: _addAccount,
                        onRemoveAccount: _removeAccount,
                        onToggleAccount: _toggleAccount,
                        bottomPadding: useDrawer ? 24 : 100,
                      ))
                else
                  const SizedBox.shrink(),
                // 3. Ajustes
                if (_visitedTabs.contains(3))
                  TickerMode(
                      enabled: _currentTab == 3,
                      child: SettingsScreen(
                        currentTheme: widget.currentTheme,
                        onThemeChanged: widget.onThemeChanged,
                        onClearCache: _clearCache,
                        onResetDefaults: _resetDefaults,
                        bottomPadding: useDrawer ? 24 : 100,
                      ))
                else
                  const SizedBox.shrink(),
              ],
            )),
          ]),
        ),
        // Floating Liquid Glass Navigation Dock
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
      label: 'Pesquisa',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.person_2,
      selectedIcon: CupertinoIcons.person_2_fill,
      label: 'Contas',
    ),
    LiquidNavItem(
      icon: CupertinoIcons.settings,
      selectedIcon: CupertinoIcons.settings_solid,
      label: 'Ajustes',
    ),
  ];

  Widget _buildDrawer({required bool modal}) => NavigationDrawer(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          _selectTab(index);
          if (modal) _scaffoldKey.currentState?.closeDrawer();
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Text('Menu', style: Theme.of(context).textTheme.titleLarge),
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
