import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';
import 'feed_video_player.dart';

class UnifiedPostCard extends StatefulWidget {
  final FeedItem item;

  const UnifiedPostCard({super.key, required this.item});

  @override
  State<UnifiedPostCard> createState() => _UnifiedPostCardState();
}

class _UnifiedPostCardState extends State<UnifiedPostCard>
    with SingleTickerProviderStateMixin {
  int _imageIndex = 0;
  late PageController _pages;
  bool _isPlaying = false;
  bool _isLiked = false;
  late int _likesCount;
  bool _isSaved = false;
  bool _isCaptionExpanded = false;

  // Double-tap heart animation
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  bool _showHeartAnim = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController(keepPage: false);
    _isLiked = widget.item.isLiked;
    _likesCount = widget.item.likes;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_heartAnimController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeartAnim = false);
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapLike() {
    HapticFeedback.lightImpact();
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _likesCount++;
        widget.item.isLiked = true;
      });
    }
    setState(() => _showHeartAnim = true);
    _heartAnimController.forward(from: 0.0);
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLiked = !_isLiked;
      widget.item.isLiked = _isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount = (_likesCount > 0) ? _likesCount - 1 : 0;
      }
    });
  }

  void _goToImage(int index) {
    if (!_pages.hasClients ||
        index < 0 ||
        index >= widget.item.mediaUrls.length) return;
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().toUtc().difference(dateTime.toUtc());
    if (diff.isNegative) return 'agora';
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} sem';
    return '${dateTime.day}/${dateTime.month}';
  }

  void _showPostOptions(BuildContext context) {
    final item = widget.item;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF181B26).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.arrow_up_right_square),
                  title: Text('Abrir no ${item.platform.displayName}'),
                  subtitle: Text(item.postUrl,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(ctx);
                    final uri = Uri.tryParse(item.postUrl);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.doc_on_clipboard),
                  title: const Text('Copiar link da publicação'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: item.postUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copiado com sucesso!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    _isSaved
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    color: _isSaved ? item.platform.primaryColor : null,
                  ),
                  title: Text(_isSaved
                      ? 'Remover dos salvos'
                      : 'Salvar publicação no SocialFeed'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _isSaved = !_isSaved);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = item.mediaUrls;

    final directUrl = FeedVideoPlayer.directSourceFor(item);
    final playerUrl = directUrl ?? FeedVideoPlayer.sourceFor(item);
    final hasVideo = playerUrl != null ||
        item.platform == SocialPlatform.tiktok ||
        item.type == FeedItemType.reel ||
        item.type == FeedItemType.video ||
        (item.videoUrl != null && item.videoUrl!.isNotEmpty);

    final isVerticalVideo = item.platform == SocialPlatform.tiktok ||
        item.type == FeedItemType.reel;

    final timeAgo = _formatTimeAgo(item.publishedAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF13151D).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Avatar com borda gradiente, Nome, Handle, Tempo e Ações
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                // Avatar com anel de gradiente da rede social
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: item.platform.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: isDark
                            ? const Color(0xFF1E212D)
                            : const Color(0xFFE8ECF4),
                        foregroundImage: item.authorAvatarUrl.isNotEmpty
                            ? NetworkImage(item.authorAvatarUrl)
                            : null,
                        child: item.authorAvatarUrl.isEmpty
                            ? Text(
                                item.accountUsername.isNotEmpty
                                    ? item.accountUsername[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: item.platform.primaryColor,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Micro badge da plataforma no canto inferior
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF13151D) : Colors.white,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.platform.primaryColor,
                          ),
                          child: Icon(
                            item.platform.iconData,
                            size: 8.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 13.5,
                            color: item.platform.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        [
                          item.authorHandle,
                          if (timeAgo.isNotEmpty) timeAgo,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge elegante da plataforma
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: item.platform.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.platform.primaryColor.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.platform.iconData,
                        size: 11,
                        color: item.platform.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.platform.shortName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.platform.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),

                // Botão de opções
                IconButton(
                  icon: const Icon(CupertinoIcons.ellipsis, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showPostOptions(context),
                ),
              ],
            ),
          ),

          // Área Principal de Mídia (Vídeo Inline ou Foto/Carrossel)
          if (hasVideo)
            _buildVideoMediaSection(
              context: context,
              playerUrl: playerUrl,
              directUrl: directUrl,
              isVertical: isVerticalVideo,
              media: media,
            )
          else if (media.isNotEmpty)
            _buildPhotoMediaSection(
              context: context,
              media: media,
            )
          else if (item.caption.isNotEmpty)
            // Post somente em texto (estilo X/Threads)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SelectableText(
                item.caption,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ),

          // Barra de Ações Sociais (Curtir, Comentar, Compartilhar, Play no Feed, Salvar)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 4),
            child: Row(
              children: [
                // Curtir
                GestureDetector(
                  onTap: _toggleLike,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: _isLiked ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            _isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: _isLiked
                                ? const Color(0xFFFF2D55)
                                : (isDark ? Colors.white70 : Colors.black87),
                            size: 24,
                          ),
                        ),
                        if (_likesCount > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            FeedItem.formatCompact(_likesCount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isLiked
                                  ? const Color(0xFFFF2D55)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Comentários
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 22,
                      ),
                      if (item.comments > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          item.formattedComments,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Compartilhar / Copiar Link
                IconButton(
                  tooltip: 'Compartilhar publicação',
                  icon: Icon(
                    CupertinoIcons.paperplane,
                    color: isDark ? Colors.white70 : Colors.black87,
                    size: 21,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: item.postUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Link de @${item.accountUsername} copiado!'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),

                // Botão de controle rápido para o vídeo inline
                if (hasVideo && playerUrl != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isPlaying = !_isPlaying);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isPlaying
                            ? item.platform.primaryColor
                                .withValues(alpha: 0.16)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isPlaying
                              ? item.platform.primaryColor
                                  .withValues(alpha: 0.35)
                              : Colors.transparent,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying
                                ? CupertinoIcons.xmark_circle_fill
                                : CupertinoIcons.play_arrow_solid,
                            size: 13,
                            color: _isPlaying
                                ? item.platform.primaryColor
                                : (isDark ? Colors.white : Colors.black),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isPlaying ? 'Fechar vídeo' : 'Play no feed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isPlaying
                                  ? item.platform.primaryColor
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Salvar publicação
                IconButton(
                  tooltip: _isSaved ? 'Remover dos salvos' : 'Salvar',
                  icon: Icon(
                    _isSaved
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    color: _isSaved
                        ? item.platform.primaryColor
                        : (isDark ? Colors.white70 : Colors.black87),
                    size: 21,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isSaved = !_isSaved);
                  },
                ),
              ],
            ),
          ),

          // Seção de Informações: Curtidas e Legenda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_likesCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '${FeedItem.formatCompact(_likesCount)} curtidas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),

                // Legenda com username em destaque e expansão inteligente
                if (item.caption.isNotEmpty && (hasVideo || media.isNotEmpty)) ...[
                  GestureDetector(
                    onTap: item.caption.length > 90
                        ? () => setState(
                            () => _isCaptionExpanded = !_isCaptionExpanded)
                        : null,
                    child: RichText(
                      maxLines: _isCaptionExpanded ? 50 : 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.authorHandle} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: item.caption),
                        ],
                      ),
                    ),
                  ),
                  if (item.caption.length > 90)
                    GestureDetector(
                      onTap: () => setState(
                          () => _isCaptionExpanded = !_isCaptionExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _isCaptionExpanded ? 'menos' : 'mais',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                ],

                // Indicador de Áudio Original / Trilha Sonora (TikTok / Reels)
                if (item.soundTrack != null ||
                    item.platform == SocialPlatform.tiktok ||
                    item.type == FeedItemType.reel) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.music_note_2,
                        size: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.soundTrack ??
                              'Áudio original · ${item.authorName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o reprodutor de vídeo inline ou a capa com botão de Play
  Widget _buildVideoMediaSection({
    required BuildContext context,
    required Uri? playerUrl,
    required Uri? directUrl,
    required bool isVertical,
    required List<String> media,
  }) {
    final item = widget.item;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Aspect ratio ideal para feeds sociais
    final double aspectRatio = isVertical ? (9 / 14) : (16 / 9);

    if (_isPlaying && playerUrl != null) {
      return Container(
        color: Colors.black,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 280,
            maxHeight: 520,
          ),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: FeedVideoPlayer(
              key: ValueKey('player_${item.id}_${item.platform.name}'),
              url: playerUrl,
              platform: item.platform,
              direct: directUrl != null,
              isInline: true,
              onClose: () => setState(() => _isPlaying = false),
            ),
          ),
        ),
      );
    }

    // Capa de vídeo com botão de Play no feed e double-tap like
    final coverUrl = media.isNotEmpty ? media.first : null;

    return GestureDetector(
      onDoubleTap: _triggerDoubleTapLike,
      onTap: () {
        if (playerUrl != null) {
          HapticFeedback.lightImpact();
          setState(() => _isPlaying = true);
        }
      },
      child: Container(
        color: isDark ? const Color(0xFF0A0C12) : const Color(0xFF1E212D),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 260,
            maxHeight: 520,
          ),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagem de capa ou placeholder estilizado
                if (coverUrl != null && coverUrl.isNotEmpty)
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderMedia(item),
                  )
                else
                  _buildPlaceholderMedia(item),

                // Gradiente escuro sutil para contraste dos controles
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.7, 1.0],
                    ),
                  ),
                ),

                // Tag da Mídia no canto superior esquerdo
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.platform == SocialPlatform.tiktok
                                  ? CupertinoIcons.play_circle_fill
                                  : CupertinoIcons.videocam_fill,
                              size: 13,
                              color: item.platform.primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.platform == SocialPlatform.tiktok
                                  ? 'TikTok'
                                  : item.type == FeedItemType.reel
                                      ? 'Reel'
                                      : 'Vídeo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Botão Central de Play no Feed (Estilo Social Media)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.45),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.platform.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  CupertinoIcons.play_fill,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.play_arrow,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Assistir no feed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Animação de Coração em Double-Tap
                if (_showHeartAnim) _buildHeartOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a seção de fotos ou carrossel de imagens
  Widget _buildPhotoMediaSection({
    required BuildContext context,
    required List<String> media,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onDoubleTap: _triggerDoubleTapLike,
      child: AspectRatio(
        aspectRatio: 4 / 5, // Proporção padrão do feed do Instagram
        child: ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  key: ObjectKey(_pages),
                  controller: _pages,
                  itemCount: media.length,
                  onPageChanged: (index) => setState(() => _imageIndex = index),
                  itemBuilder: (context, index) => Image.network(
                    media[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Imagem indisponível'),
                    ),
                  ),
                ),
              ),

              // Botões laterais de navegação no desktop/tablet
              if (media.length > 1) ...[
                if (_imageIndex > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filledTonal(
                        tooltip: 'Imagem anterior',
                        onPressed: () => _goToImage(_imageIndex - 1),
                        icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                      ),
                    ),
                  ),
                if (_imageIndex < media.length - 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filledTonal(
                        tooltip: 'Próxima imagem',
                        onPressed: () => _goToImage(_imageIndex + 1),
                        icon: const Icon(CupertinoIcons.chevron_right, size: 18),
                      ),
                    ),
                  ),
              ],

              // Indicador flutuante "1/3" no canto superior direito
              if (media.length > 1)
                Positioned(
                  right: 12,
                  top: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Text(
                          '${_imageIndex + 1}/${media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Pontos de paginação (Dots) na base da imagem
              if (media.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < media.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imageIndex == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: _imageIndex == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                ),

              // Animação de Coração em Double-Tap
              if (_showHeartAnim) _buildHeartOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder de capa estilizado quando a imagem de vídeo ainda não carregou
  Widget _buildPlaceholderMedia(FeedItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.platform.primaryColor.withValues(alpha: 0.35),
            const Color(0xFF0E1118),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.platform.iconData,
              size: 48,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              '@${item.accountUsername}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animação de explosão de coração central no double-tap
  Widget _buildHeartOverlay() {
    return Center(
      child: FadeTransition(
        opacity: _heartOpacity,
        child: ScaleTransition(
          scale: _heartScale,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x66FF2D55),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.heart_fill,
              color: Color(0xFFFF2D55),
              size: 96,
            ),
          ),
        ),
      ),
    );
  }
}
