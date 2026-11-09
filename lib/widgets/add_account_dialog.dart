import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../services/social_service.dart';
import 'liquid_glass.dart';

class AddAccountDialog extends StatefulWidget {
  final Function(SocialAccount newAccount) onAccountAdded;

  const AddAccountDialog({
    super.key,
    required this.onAccountAdded,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  SocialPlatform selectedPlatform = SocialPlatform.instagram;
  final TextEditingController _usernameController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  SocialAccount? previewAccount;

  final Map<SocialPlatform, List<Map<String, String>>> popularSuggestions = {
    SocialPlatform.instagram: [
      {'user': 'cristiano', 'name': 'Cristiano Ronaldo', 'followers': '638M'},
      {'user': 'leomessi', 'name': 'Leo Messi', 'followers': '504M'},
      {'user': 'neymarjr', 'name': 'Neymar Jr', 'followers': '225M'},
      {'user': 'natgeo', 'name': 'National Geographic', 'followers': '284M'},
    ],
    SocialPlatform.tiktok: [
      {'user': 'khaby.lame', 'name': 'Khaby Lame', 'followers': '162M'},
      {'user': 'mrbeast', 'name': 'MrBeast', 'followers': '104M'},
      {'user': 'charlidamelio', 'name': 'Charli D’Amelio', 'followers': '155M'},
      {'user': 'zachking', 'name': 'Zach King', 'followers': '82M'},
    ],
    SocialPlatform.x: [
      {'user': 'elonmusk', 'name': 'Elon Musk', 'followers': '198M'},
      {'user': 'nasa', 'name': 'NASA', 'followers': '79M'},
      {'user': 'billgates', 'name': 'Bill Gates', 'followers': '64M'},
      {'user': 'barackobama', 'name': 'Barack Obama', 'followers': '131M'},
    ],
  };

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndPreview([String? presetUser]) async {
    if (isLoading) return;
    final username = presetUser ?? _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => errorMessage = 'Por favor, digite o @ de usuário.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      previewAccount = null;
    });

    try {
      final account = await SocialService.fetchAccountProfile(
        selectedPlatform,
        username,
      );
      if (!mounted) return;
      setState(() {
        previewAccount = account;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e is FormatException
            ? e.message
            : 'Não foi possível consultar a conta. Tente novamente.';
        isLoading = false;
      });
    }
  }

  void _confirmAdd() {
    if (previewAccount != null) {
      widget.onAccountAdded(previewAccount!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = popularSuggestions[selectedPlatform] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(28),
          blur: 26,
          opacity: isDark ? 0.15 : 0.85,
          tintColor: selectedPlatform.primaryColor,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TÍTULO VIDRADO
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: selectedPlatform.gradientColors),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: selectedPlatform.primaryColor
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        selectedPlatform.iconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Adicionar Conta',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SELETOR DE PLATAFORMA (Liquid Glass Pills)
                DropdownButtonFormField<SocialPlatform>(
                  initialValue: selectedPlatform,
                  decoration: const InputDecoration(labelText: 'Rede'),
                  items: [
                    for (final platform in SocialPlatform.values)
                      DropdownMenuItem(
                        value: platform,
                        child: Text(platform.displayName),
                      ),
                  ],
                  onChanged: isLoading
                      ? null
                      : (platform) {
                          if (platform == null) return;
                          setState(() {
                            selectedPlatform = platform;
                            previewAccount = null;
                            errorMessage = null;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // CAMPO DE BUSCA VIDRADO
                LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  blur: 14,
                  opacity: isDark ? 0.08 : 0.5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(CupertinoIcons.at, size: 18),
                      hintText: selectedPlatform == SocialPlatform.youtube
                          ? '@canal, link ou ID'
                          : 'Nome de usuário ou link',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(CupertinoIcons.search, size: 20),
                        onPressed: () => _fetchAndPreview(),
                      ),
                    ),
                    onSubmitted: (_) => _fetchAndPreview(),
                  ),
                ),
                const SizedBox(height: 10),

                if (isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],

                // PREVIEW DA CONTA ENCONTRADA EM LIQUID GLASS
                if (previewAccount != null) ...[
                  const SizedBox(height: 10),
                  LiquidGlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blur: 18,
                    tintColor: selectedPlatform.primaryColor,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: selectedPlatform.primaryColor
                              .withValues(alpha: 0.15),
                          backgroundImage: previewAccount!.avatarUrl.isNotEmpty
                              ? NetworkImage(previewAccount!.avatarUrl)
                              : null,
                          child: previewAccount!.avatarUrl.isEmpty
                              ? Text(previewAccount!.username[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      previewAccount!.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (previewAccount!.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 15,
                                      color: Color(0xFF3897F0),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                previewAccount!.handle,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${previewAccount!.followerLabel} · ${previewAccount!.visibilityLabel}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: selectedPlatform.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedPlatform.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.plus_circle_fill, size: 18),
                    label: const Text(
                      'Confirmar e Adicionar ao Feed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _confirmAdd,
                  ),
                ] else if (!isLoading) ...[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedPlatform.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _fetchAndPreview(),
                    child: const Text('Buscar Perfil Público'),
                  ),
                ],

                const SizedBox(height: 18),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 10),

                const Text(
                  'Ou adicione contas populares com 1 toque:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions.map((s) {
                    return LiquidGlassPill(
                      glowColor: selectedPlatform.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      onTap: () {
                        _usernameController.text = s['user']!;
                        _fetchAndPreview(s['user']);
                      },
                      child: Text(
                        '@${s['user']} (${s['followers']})',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
