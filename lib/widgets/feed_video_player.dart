import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';
import '../models/platform_type.dart';

class FeedVideoPlayer extends StatefulWidget {
  final Uri url;
  final SocialPlatform platform;
  final bool direct;
  final bool isInline;
  final VoidCallback? onClose;
  final VoidCallback? onReload;

  const FeedVideoPlayer({
    super.key,
    required this.url,
    required this.platform,
    this.direct = false,
    this.isInline = true,
    this.onClose,
    this.onReload,
  });

  static Uri? directSourceFor(FeedItem item) {
    final videoUrl = item.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final uri = Uri.tryParse(videoUrl);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty) {
        return uri;
      }
    }
    return null;
  }

  static Uri? sourceFor(FeedItem item) {
    switch (item.platform) {
      case SocialPlatform.youtube:
        var videoId = item.id;
        if (!RegExp(r'^[\w-]{11}$').hasMatch(videoId)) {
          final uri = Uri.tryParse(item.postUrl);
          if (uri != null) {
            videoId = uri.queryParameters['v'] ??
                (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '');
          }
        }
        if (!RegExp(r'^[\w-]{11}$').hasMatch(videoId)) return null;
        return Uri.https('www.youtube.com', '/embed/$videoId', {
          'playsinline': '1',
          'autoplay': '1',
        });

      case SocialPlatform.tiktok:
        var id = item.id;
        if (!RegExp(r'^\d{1,25}$').hasMatch(id)) {
          final match = RegExp(r'/video/(\d+)').firstMatch(item.postUrl);
          if (match != null) {
            id = match.group(1)!;
          }
        }
        if (RegExp(r'^\d{1,25}$').hasMatch(id)) {
          return Uri.https('www.tiktok.com', '/player/v1/$id', {
            'rel': '0',
            'autoplay': '1',
          });
        }
        return null;

      case SocialPlatform.instagram:
        final uri = Uri.tryParse(item.postUrl);
        final path = uri?.pathSegments ?? const <String>[];
        var type = 'p';
        var code = item.id;
        if (path.length >= 2 &&
            const {'p', 'reel', 'tv'}.contains(path.first)) {
          type = path.first == 'reel' ? 'reel' : 'p';
          code = path[1];
        }
        if (RegExp(r'^[\w-]+$').hasMatch(code)) {
          return Uri.https('www.instagram.com', '/$type/$code/embed/');
        }
        return null;

      case SocialPlatform.x:
        return null;
    }
  }

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  bool _loading = true;
  bool _failed = false;
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final supported = kIsWeb ||
        const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.windows,
        }.contains(defaultTargetPlatform);

    final url = widget.url;
    final direct = widget.direct;
    final source =
        const HtmlEscape(HtmlEscapeMode.attribute).convert(url.toString());

    Widget content;

    if (!supported) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Player integrado indisponível nesta plataforma.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else if (_failed) {
      content = Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle,
                  color: widget.platform.primaryColor, size: 30),
              const SizedBox(height: 8),
              const Text(
                'Não foi possível reproduzir no feed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() {
                      _failed = false;
                      _loading = true;
                      _attempt++;
                    }),
                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                    label: const Text('Recarregar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(widget.url,
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(CupertinoIcons.arrow_up_right, size: 14),
                    label: Text('Abrir no ${widget.platform.shortName}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          InAppWebView(
            key: ValueKey('${widget.url}_$_attempt'),
            initialData: direct
                ? InAppWebViewInitialData(
                    data: '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%;
      height: 100%;
      background: #000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
      background: #000;
      outline: none;
    }
  </style>
</head>
<body>
  <video id="player" controls autoplay playsinline loop preload="auto" src="$source" onerror="this.hidden=true;document.getElementById('err').style.display='flex'"></video>
  <div id="err" style="display:none;color:#fff;font-family:-apple-system,BlinkMacSystemFont,Roboto,sans-serif;font-size:13px;text-align:center;padding:16px;">
    Vídeo indisponível diretamente.
  </div>
</body>
</html>
''',
                  )
                : null,
            initialUrlRequest: direct
                ? null
                : URLRequest(
                    url: WebUri(url.toString()),
                    headers: !kIsWeb &&
                            widget.platform == SocialPlatform.youtube
                        ? {'Referer': 'https://com.example.socialfeed/'}
                        : null,
                  ),
            initialSettings: InAppWebViewSettings(
              allowsInlineMediaPlayback: true,
              mediaPlaybackRequiresUserGesture: false,
              iframeAllow:
                  'fullscreen; encrypted-media; picture-in-picture; autoplay',
              iframeAllowFullscreen: true,
              useShouldOverrideUrlLoading: true,
              supportMultipleWindows: false,
              transparentBackground: true,
            ),
            shouldOverrideUrlLoading: (_, action) async {
              if (!action.isForMainFrame) {
                return NavigationActionPolicy.ALLOW;
              }
              final target = action.request.url;
              if (target == null) return NavigationActionPolicy.ALLOW;

              final isInitialHost = target.host == url.host;
              final isAllowedHost = target.host.contains('instagram.com') ||
                  target.host.contains('tiktok.com') ||
                  target.host.contains('youtube.com') ||
                  target.host.contains('cdninstagram.com') ||
                  target.host.contains('tiktokcdn.com');

              if (isInitialHost &&
                  (target.path == url.path ||
                      target.path.contains('embed') ||
                      target.path.contains('player'))) {
                return NavigationActionPolicy.ALLOW;
              }

              if (action.hasGesture == true) {
                launchUrl(Uri.parse(target.toString()),
                    mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }

              return isAllowedHost
                  ? NavigationActionPolicy.ALLOW
                  : NavigationActionPolicy.CANCEL;
            },
            onCreateWindow: (_, __) async => false,
            onLoadStop: (_, __) {
              if (mounted) setState(() => _loading = false);
            },
            onReceivedHttpError: (_, request, response) {
              if (mounted && request.isForMainFrame == true) {
                setState(() => _failed = true);
              }
            },
            onReceivedError: (_, request, error) {
              if (mounted && request.isForMainFrame == true) {
                setState(() => _failed = true);
              }
            },
          ),

          // Barra superior de controle inline
          if (widget.isInline)
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.platform.iconData,
                            size: 13, color: widget.platform.primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          widget.platform.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (widget.onClose != null)
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          if (_loading && !kIsWeb)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                color: widget.platform.primaryColor,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      );
    }

    if (widget.isInline) {
      return Container(
        color: const Color(0xFF000000),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Vídeo · ${widget.platform.shortName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.platform == SocialPlatform.tiktok ? 520 : 960,
          ),
          child: content,
        ),
      ),
    );
  }
}
