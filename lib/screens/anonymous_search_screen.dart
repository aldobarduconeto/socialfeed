import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../services/social_service.dart';

class AnonymousSearchScreen extends StatefulWidget {
  final Future<void> Function(List<SocialAccount>) onFollowAccounts;
  final List<SocialAccount> currentAccounts;
  final double bottomPadding;

  const AnonymousSearchScreen({
    super.key,
    required this.onFollowAccounts,
    required this.currentAccounts,
    required this.bottomPadding,
  });

  @override
  State<AnonymousSearchScreen> createState() => _AnonymousSearchScreenState();
}

class _AnonymousSearchScreenState extends State<AnonymousSearchScreen> {
  static const _recentSearchesKey = 'sf_anonymous_recent_searches_v1';
  static final _validUsernameRegex = RegExp(r'^[a-zA-Z0-9_.-]+$');
  final _controller = TextEditingController();
  List<String> _recentSearches = [];
  List<SocialAccount> _results = [];
  bool _searching = false;
  bool _following = false;
  String? _message;
  String? _searchedUsername;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted && !_searching) {
      setState(() =>
          _recentSearches = prefs.getStringList(_recentSearchesKey) ?? []);
    }
  }

  Future<void> _search() async {
    if (_searching || _following) return;
    final username = SocialService.normalizeUsername(_controller.text);
    if (!_validUsernameRegex.hasMatch(username)) {
      setState(() {
        _message = 'Digite um @ de usuário válido ou cole o link de um perfil.';
        _results = [];
        _searchedUsername = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _message = null;
      _searchedUsername = null;
      _results = [];
    });

    final results = await Future.wait(SocialPlatform.values.map(
      (platform) => SocialService.findPublicProfile(platform, username),
    ));
    if (!mounted) return;
    final profiles = [
      for (var index = 0; index < SocialPlatform.values.length; index++)
        results[index] ??
            widget.currentAccounts
                .where(
                  (account) =>
                      account.platform == SocialPlatform.values[index] &&
                      account.username.toLowerCase() == username.toLowerCase(),
                )
                .firstOrNull,
    ].whereType<SocialAccount>().toList();
    final recent = [
      username,
      ..._recentSearches
          .where((entry) => entry.toLowerCase() != username.toLowerCase()),
    ].take(8).toList();
    setState(() {
      _results = profiles;
      _searchedUsername = username;
      _recentSearches = recent;
      _searching = false;
      _message = profiles.isEmpty
          ? 'Não foi possível confirmar um perfil público para @$username.'
          : null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, recent);
  }

  bool _isFollowing(SocialAccount account) => widget.currentAccounts.any(
        (saved) =>
            saved.isActive &&
            saved.platform == account.platform &&
            (saved.username.toLowerCase() == account.username.toLowerCase() ||
                (account.channelId != null &&
                    saved.channelId == account.channelId)),
      );

  Future<void> _follow(SocialAccount account) async {
    setState(() => _following = true);
    try {
      await widget.onFollowAccounts([account]);
      if (!mounted) return;
      final others = _results
          .where(
            (candidate) =>
                candidate.platform != account.platform &&
                !_isFollowing(candidate),
          )
          .toList();
      if (others.isEmpty) return;

      final selected = <SocialAccount>{};
      final additional = await showDialog<List<SocialAccount>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Seguir em outras redes?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Encontramos ${account.handle} em outras redes. O mesmo @ pode pertencer a outra pessoa.'),
                const SizedBox(height: 12),
                for (final candidate in others)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      candidate.platform.iconData,
                      color: candidate.platform.primaryColor,
                    ),
                    title: Text(
                      candidate.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(candidate.platform.shortName),
                    value: selected.contains(candidate),
                    onChanged: (checked) => updateDialog(() {
                      if (checked == true) {
                        selected.add(candidate);
                      } else {
                        selected.remove(candidate);
                      }
                    }),
                  ),
              ],
            ),
            scrollable: true,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, selected.toList()),
                child: const Text('Seguir selecionados'),
              ),
            ],
          ),
        ),
      );
      if (mounted && additional != null) {
        await widget.onFollowAccounts(additional);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar os perfis.')),
        );
      }
    } finally {
      if (mounted) setState(() => _following = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final busy = _searching || _following;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: const PageStorageKey('search'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(16, 20, 16, widget.bottomPadding + 16),
          children: [
            // Card de Busca Principal
            Container(
              padding: const EdgeInsets.all(20),
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
                          CupertinoIcons.search,
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
                              'Explorar Perfis',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Busque simultaneamente no Instagram, TikTok, X e YouTube',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF191D29)
                          : const Color(0xFFF3F5FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      enabled: !busy,
                      autocorrect: false,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          CupertinoIcons.at,
                          size: 18,
                          color: colors.primary,
                        ),
                        hintText: 'Digite o @usuario ou cole o link do perfil',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: busy ? null : _search,
                            child: const Text(
                              'Buscar',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_searching) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: colors.primary,
                        semanticsLabel: 'Consultando as redes',
                      ),
                    ),
                  ],
                  if (_message case final message?) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.info_circle,
                              size: 16, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Resultados por plataforma
            if (_searchedUsername case final username?) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Resultados para @$username',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final platform in SocialPlatform.values) ...[
                _platformResult(platform, username, busy, isDark),
                const SizedBox(height: 10),
              ],
            ],

            // Buscas recentes
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buscas recentes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove(_recentSearchesKey);
                              if (mounted) setState(() => _recentSearches = []);
                            },
                      child:
                          const Text('Limpar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final username in _recentSearches)
                    ActionChip(
                      avatar: Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: Text(
                        '@$username',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: busy
                          ? null
                          : () {
                              _controller.text = username;
                              _search();
                            },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _platformResult(
    SocialPlatform platform,
    String username,
    bool busy,
    bool isDark,
  ) {
    final account =
        _results.where((result) => result.platform == platform).firstOrNull;
    final following = account != null && _isFollowing(account);
    final brandColor = platform.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12151E).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.12),
            ),
            child: account != null && account.avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      account.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        platform.iconData,
                        color: brandColor,
                        size: 20,
                      ),
                    ),
                  )
                : Icon(platform.iconData, color: brandColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account?.displayName ?? platform.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        platform.shortName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  account == null
                      ? '@$username · Perfil público não confirmado'
                      : '${account.handle} · ${account.visibilityLabel} · ${account.followerLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (account != null) ...[
            const SizedBox(width: 10),
            if (following)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt,
                        size: 14, color: brandColor),
                    const SizedBox(width: 4),
                    Text(
                      'Seguindo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: brandColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: brandColor.withValues(alpha: 0.14),
                  foregroundColor: brandColor,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: busy ? null : () => _follow(account),
                child: const Text(
                  'Seguir',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
