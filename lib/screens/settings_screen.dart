import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../models/feed_item.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;
  final bool isCompactView;
  final ValueChanged<bool> onCompactViewChanged;
  final List<SocialAccount> accounts;
  final List<FeedItem> feedItems;
  final VoidCallback onClearCache;
  final VoidCallback onResetDefaults;
  final VoidCallback onBackupImported;
  final double bottomPadding;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.isCompactView,
    required this.onCompactViewChanged,
    required this.accounts,
    required this.feedItems,
    required this.onClearCache,
    required this.onResetDefaults,
    required this.onBackupImported,
    required this.bottomPadding,
  });

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restaurar contas iniciais?'),
        content: const Text(
          'Sua lista atual será substituída pelas contas sugeridas do SocialFeed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onResetDefaults();
  }

  Future<void> _exportBackup(BuildContext context) async {
    final jsonString = await StorageService.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal_fill,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Backup copiado para a área de transferência!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final textController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Importar backup de contas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o JSON de backup copiado anteriormente:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: '{\n  "version": "1.0",\n  "accounts": [...]\n}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (result == true && textController.text.trim().isNotEmpty) {
      try {
        final count =
            await StorageService.importBackupJson(textController.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count contas importadas com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          onBackupImported();
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato de JSON inválido. Verifique o conteúdo.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const modes = [
      (ThemeMode.system, 'Sistema', CupertinoIcons.device_phone_portrait),
      (ThemeMode.light, 'Claro', CupertinoIcons.sun_max_fill),
      (ThemeMode.dark, 'Escuro', CupertinoIcons.moon_stars_fill),
    ];

    // Cálculos de estatísticas do feed
    final activeAccounts = accounts.where((a) => a.isActive).length;
    final platformDistribution = <SocialPlatform, int>{};
    int totalLikes = 0;
    int totalComments = 0;

    for (final item in feedItems) {
      platformDistribution[item.platform] =
          (platformDistribution[item.platform] ?? 0) + 1;
      totalLikes += item.likes;
      totalComments += item.comments;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: const PageStorageKey('settings'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding + 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Ajustes & Insights',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 1: Dashboard de Insights e Métricas
            _SettingsSectionCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.chart_pie_fill,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Métricas do Seu Feed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatBox(
                          title: 'Perfis Ativos',
                          value: '$activeAccounts',
                          caption: 'de ${accounts.length} cadastrados',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          title: 'Publicações',
                          value: '${feedItems.length}',
                          caption: 'carregadas no feed',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          title: 'Curtidas Totais',
                          value: FeedItem.formatCompact(totalLikes),
                          caption: 'acumuladas',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    if (feedItems.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Distribuição por plataforma:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              for (final platform in SocialPlatform.values) ...[
                                if ((platformDistribution[platform] ?? 0) > 0)
                                  Expanded(
                                    flex: platformDistribution[platform]!,
                                    child: Container(
                                      color: platform.primaryColor,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          for (final platform in SocialPlatform.values) ...[
                            if ((platformDistribution[platform] ?? 0) > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: platform.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${platform.shortName}: ${platformDistribution[platform]}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Aparência e Preferências do Feed
            _SettingsSectionCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.paintbrush_fill,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Aparência',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final (index, (mode, label, icon))
                            in modes.indexed) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _ThemeOptionButton(
                              label: label,
                              icon: icon,
                              isSelected: currentTheme == mode,
                              isDark: isDark,
                              primary: colors.primary,
                              onTap: () => onThemeChanged(mode),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Visualização compacta',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Exibe cards menores para navegar mais rápido pelas publicações.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      value: isCompactView,
                      onChanged: onCompactViewChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Backup & Restauração
            _SettingsSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF635BFF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up_doc,
                        color: Color(0xFF635BFF),
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Exportar backup de contas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Gera um arquivo JSON de cópia das contas e salvos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    trailing:
                        const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                    onTap: () => _exportBackup(context),
                  ),
                  const Divider(indent: 60),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CEC9).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_down_doc,
                        color: Color(0xFF00CEC9),
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Importar backup',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Restaura ou mescla contas colando o texto JSON.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => _importBackup(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 4: Dados e Armazenamento
            _SettingsSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: Colors.orangeAccent,
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Limpar cache do feed',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Remove publicações salvas localmente e ressincroniza.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: onClearCache,
                  ),
                  const Divider(indent: 60),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Restaurar contas iniciais',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Redefine sua lista para os perfis sugeridos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => _reset(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 5: Sobre o aplicativo
            _SettingsSectionCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SocialFeed · v1.0.0',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reúne conteúdo público de perfis e canais do Instagram, TikTok, X e YouTube em uma linha do tempo limpa, cronológica, privada e sem algoritmos invasivos.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _SettingsSectionCard({
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12151E).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final bool isDark;

  const _StatBox({
    required this.title,
    required this.value,
    required this.caption,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B26) : const Color(0xFFF3F5FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              caption,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _ThemeOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.6)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? primary
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
