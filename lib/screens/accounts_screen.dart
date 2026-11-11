import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/social_account.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  final List<SocialAccount> accounts;
  final ValueChanged<SocialAccount> onAddAccount;
  final ValueChanged<String> onRemoveAccount;
  final ValueChanged<String> onToggleAccount;
  final double bottomPadding;

  const AccountsScreen({
    super.key,
    required this.accounts,
    required this.onAddAccount,
    required this.onRemoveAccount,
    required this.onToggleAccount,
    required this.bottomPadding,
  });

  void _add(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AddAccountDialog(onAccountAdded: onAddAccount),
    );
  }

  Future<void> _remove(BuildContext context, SocialAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover ${account.handle}?'),
        content: Text(
          'As publicações de ${account.platform.shortName} deixarão de aparecer no seu feed unificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onRemoveAccount(account.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final active = accounts.where((account) => account.isActive).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomScrollView(
          key: const PageStorageKey('accounts'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Container(
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contas seguidas',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              accounts.isEmpty
                                  ? 'Adicione um perfil ou canal para começar.'
                                  : '$active de ${accounts.length} perfis ativos no feed',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _add(context),
                        icon: const Icon(CupertinoIcons.person_add_solid,
                            size: 16),
                        label: const Text(
                          'Adicionar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (accounts.isEmpty)
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
                            CupertinoIcons.person_2,
                            size: 38,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma conta cadastrada',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Siga seus criadores favoritos do Instagram, TikTok, X e YouTube.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
                sliver: SliverList.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountCard(
                      key: ValueKey(account.id),
                      account: account,
                      isDark: isDark,
                      onToggle: () => onToggleAccount(account.id),
                      onRemove: () => _remove(context, account),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final SocialAccount account;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _AccountCard({
    super.key,
    required this.account,
    required this.isDark,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = account.platform.primaryColor;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: account.isActive ? 1.0 : 0.62,
      child: Container(
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
            // Avatar com anel gradiente
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: account.platform.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: isDark
                        ? const Color(0xFF1B1E2B)
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
                        color: brandColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brandColor,
                      border: Border.all(
                        color: isDark ? const Color(0xFF12151E) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      account.platform.iconData,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                          account.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: brandColor,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          account.platform.shortName,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: brandColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.handle} · ${account.followerLabel}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.visibilityLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Abrir perfil no ${account.platform.shortName}',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                CupertinoIcons.arrow_up_right_square,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              onPressed: () {
                final uri =
                    Uri.tryParse(account.platform.profileUrl(account.username));
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            Switch.adaptive(
              value: account.isActive,
              activeTrackColor: brandColor,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              tooltip: 'Remover ${account.handle}',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                CupertinoIcons.trash,
                size: 18,
                color: Colors.redAccent,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
