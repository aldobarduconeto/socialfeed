import 'package:flutter/material.dart';
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
        title: Text('Remover ${account.handle}?'),
        content: Text(
            'As publicações de ${account.platform.shortName} sairão do seu feed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onRemoveAccount(account.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = accounts.where((account) => account.isActive).length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: CustomScrollView(
          key: const PageStorageKey('accounts'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contas seguidas',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(accounts.isEmpty
                        ? 'Adicione um perfil ou canal para começar.'
                        : '$active de ${accounts.length} contas no feed'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _add(context),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Adicionar conta'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
              sliver: SliverList.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return Card.outlined(
                    key: ValueKey(account.id),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(account.platform.iconData),
                          title: Text(account.displayName),
                          subtitle: Text(
                            '${account.handle} · ${account.platform.shortName}\n'
                            '${account.visibilityLabel} · ${account.followerLabel}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover ${account.handle}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(context, account),
                          ),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Mostrar no feed'),
                          value: account.isActive,
                          onChanged: (_) => onToggleAccount(account.id),
                        ),
                      ],
                    ),
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
