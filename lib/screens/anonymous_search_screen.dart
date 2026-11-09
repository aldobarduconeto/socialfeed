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
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(username)) {
      setState(() {
        _message = 'Digite um @ ou cole o link de um perfil.';
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
                    title: Text(candidate.displayName),
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
    final busy = _searching || _following;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          key: const PageStorageKey('search'),
          padding: EdgeInsets.fromLTRB(20, 24, 20, widget.bottomPadding),
          children: [
            Text('Pesquisar perfis', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Instagram, TikTok, X e YouTube',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !busy,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.alternate_email),
                labelText: 'Nome de usuário ou link',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Pesquisar nas redes',
                  onPressed: busy ? null : _search,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            if (_searching) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                  semanticsLabel: 'Consultando as redes'),
            ],
            if (_message case final message?) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
            if (_searchedUsername case final username?) ...[
              const SizedBox(height: 16),
              Text('Resultados para @$username',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final platform in SocialPlatform.values)
                _platformResult(platform, username, busy),
            ],
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child:
                          Text('Recentes', style: theme.textTheme.titleSmall)),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove(_recentSearchesKey);
                            if (mounted) setState(() => _recentSearches = []);
                          },
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final username in _recentSearches)
                    ActionChip(
                      label: Text('@$username'),
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

  Widget _platformResult(SocialPlatform platform, String username, bool busy) {
    final account =
        _results.where((result) => result.platform == platform).firstOrNull;
    return Card.outlined(
      child: ListTile(
        leading: Icon(platform.iconData),
        title: Text(account?.displayName ?? platform.displayName),
        subtitle: Text(account == null
            ? '@$username · Consulta inconclusiva'
            : '${account.handle} · ${platform.shortName}\n${account.visibilityLabel} · ${account.followerLabel}'),
        trailing: account == null
            ? null
            : _isFollowing(account)
                ? const Text('Seguindo')
                : OutlinedButton(
                    onPressed: busy ? null : () => _follow(account),
                    child: const Text('Seguir'),
                  ),
      ),
    );
  }
}
