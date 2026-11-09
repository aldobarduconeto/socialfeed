import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onClearCache;
  final VoidCallback onResetDefaults;
  final double bottomPadding;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.onClearCache,
    required this.onResetDefaults,
    required this.bottomPadding,
  });

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar contas iniciais?'),
        content: const Text(
            'Sua lista atual será substituída pelas contas sugeridas do SocialFeed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onResetDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const modes = {
      ThemeMode.system: 'Sistema',
      ThemeMode.light: 'Claro',
      ThemeMode.dark: 'Escuro',
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: const PageStorageKey('settings'),
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding),
          children: [
            Text('Ajustes', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aparência', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final option in modes.entries)
                          ChoiceChip(
                            label: Text(option.value),
                            selected: currentTheme == option.key,
                            onSelected: (_) => onThemeChanged(option.key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card.outlined(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Limpar cache do feed'),
                    subtitle: const Text(
                        'Apaga as publicações armazenadas e atualiza o feed.'),
                    onTap: onClearCache,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restaurar contas iniciais'),
                    subtitle:
                        const Text('Substitui a lista de contas seguidas.'),
                    onTap: () => _reset(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Card.outlined(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Sobre o SocialFeed'),
                subtitle: Text(
                    'O app reúne conteúdo público de perfis e canais que você adiciona.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
