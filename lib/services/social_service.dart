import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../models/feed_item.dart';

class SocialService {
  static final http.Client _client = http.Client();

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  static String normalizeUsername(String input) {
    final text = input.trim();
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    final host = uri?.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (const {
      'instagram.com',
      'tiktok.com',
      'x.com',
      'twitter.com',
      'youtube.com',
      'm.youtube.com'
    }.contains(host)) {
      if (host == 'youtube.com' || host == 'm.youtube.com') {
        final segments = uri!.pathSegments;
        if (segments.length >= 2 && segments.first == 'channel') {
          return segments[1];
        }
        return segments.firstOrNull?.startsWith('@') == true
            ? segments.first.substring(1)
            : '';
      }
      return uri!.pathSegments.firstOrNull?.replaceFirst(RegExp(r'^@'), '') ??
          '';
    }
    return text.replaceFirst(RegExp(r'^@'), '');
  }

  static Future<SocialAccount> fetchAccountProfile(
    SocialPlatform platform,
    String rawUsername,
  ) async {
    final username = normalizeUsername(rawUsername);
    final profile = await findPublicProfile(platform, username);
    if (profile != null) return profile;
    if (platform == SocialPlatform.youtube) {
      throw const FormatException('Canal público do YouTube não confirmado.');
    }
    return _buildFallbackProfile(
        platform, username, _accountId(platform, username));
  }

  static String _accountId(SocialPlatform platform, String username) =>
      'acc_${platform.name}_${username.toLowerCase()}';

  static Future<SocialAccount?> findPublicProfile(
    SocialPlatform platform,
    String username,
  ) {
    final id = _accountId(platform, username);
    return switch (platform) {
      SocialPlatform.x => _fetchXProfile(username, id),
      SocialPlatform.tiktok => _fetchTikTokProfile(username, id),
      SocialPlatform.instagram => _fetchInstagramProfile(username, id),
      SocialPlatform.youtube => _fetchYouTubeProfile(username, id),
    };
  }

  // --- SCRAPING / API X (TWITTER) ---
  static Future<SocialAccount?> _fetchXProfile(
      String username, String accountId) async {
    try {
      final html = await _readPublicPage(Uri.parse(
          'https://syndication.twitter.com/srv/timeline-profile/screen-name/$username'));
      final nameMatch =
          RegExp(r'class="Tweet-authorName"[^>]*>([^<]+)<').firstMatch(html);
      final avatarMatch =
          RegExp(r'src="([^"]*(?:twimg|abs\.twimg)[^"]*)"').firstMatch(html);
      final name = nameMatch?.group(1)?.trim();
      final avatar = avatarMatch?.group(1);

      final hasOwnPost = RegExp(
        '/${RegExp.escape(username)}/status/[0-9]+',
        caseSensitive: false,
      ).hasMatch(html);
      if (hasOwnPost) {
        return SocialAccount(
          id: accountId,
          platform: SocialPlatform.x,
          username: username,
          displayName: name ?? username,
          avatarUrl: avatar ?? '',
          bio: 'Perfil público no X',
        );
      }
    } catch (_) {}

    try {
      final html = await _readPublicPage(Uri.https('x.com', '/$username'));
      final metadata = _metadata(html);
      final title = metadata['og:title'];
      if (_titleMatchesHandle(title, username)) {
        return SocialAccount(
          id: accountId,
          platform: SocialPlatform.x,
          username: username,
          displayName: title!.split('(').first.trim(),
          avatarUrl: metadata['og:image'] ?? '',
        );
      }
    } catch (_) {}

    return null;
  }

  // --- SCRAPING / API TIKTOK ---
  static Future<SocialAccount?> _fetchTikTokProfile(
      String username, String accountId) async {
    // 1. Tentar oEmbed oficial do TikTok
    try {
      final uri = Uri.https('www.tiktok.com', '/oembed', {
        'url': SocialPlatform.tiktok.profileUrl(username),
      });
      final data = jsonDecode(await _readPublicPage(uri));
      final authorName = data['author_name'] as String?;
      if (authorName != null && authorName.isNotEmpty) {
        return SocialAccount(
          id: accountId,
          platform: SocialPlatform.tiktok,
          username: username,
          displayName: authorName,
          avatarUrl: '',
          bio: 'Criador no TikTok',
        );
      }
    } catch (_) {}

    // 2. Tentar requisitar página web do TikTok para extrair OpenGraph
    try {
      final html =
          await _readPublicPage(Uri.parse('https://www.tiktok.com/@$username'));
      final metadata = _metadata(html);
      final title = metadata['og:title'];
      final image = metadata['og:image'];
      final desc = metadata['og:description'];

      if (title == null ||
          !RegExp('(?:^|[^a-z0-9_.])@${RegExp.escape(username)}(?![a-z0-9_.])',
                  caseSensitive: false)
              .hasMatch(title)) {
        return null;
      }

      final displayName =
          title.split('(')[0].replaceAll('on TikTok', '').trim();

      return SocialAccount(
        id: accountId,
        platform: SocialPlatform.tiktok,
        username: username,
        displayName: displayName.isNotEmpty ? displayName : username,
        avatarUrl: image ?? '',
        bio: desc ?? 'Criador no TikTok',
      );
    } catch (_) {}

    return null;
  }

  // Public web endpoint used by Instagram's own website. It can require login.
  static Future<Map<String, dynamic>?> _instagramWebProfile(
    String username, {
    http.Client? client,
  }) async {
    try {
      final uri = Uri.https('www.instagram.com',
          '/api/v1/users/web_profile_info/', {'username': username});
      final payload = jsonDecode(await _readPublicPage(uri, client: client));
      final user = payload['data']?['user'];
      if (user is Map<String, dynamic> &&
          user['username']?.toString().toLowerCase() ==
              username.toLowerCase()) {
        return user;
      }
    } catch (_) {}
    return null;
  }

  static SocialAccount _instagramAccount(
      Map<String, dynamic> user, String username, String accountId) {
    final followers = user['edge_followed_by'];
    final private = user['is_private'];
    return SocialAccount(
      id: accountId,
      platform: SocialPlatform.instagram,
      username: username,
      displayName: (user['full_name'] as String?)?.trim().isNotEmpty == true
          ? user['full_name'] as String
          : username,
      avatarUrl: user['profile_pic_url'] as String? ?? '',
      bio: user['biography'] as String? ?? '',
      followers: ((followers is Map
              ? followers['count']
              : user['follower_count']) as num?)
          ?.toInt(),
      isPrivate: private is bool ? private : null,
      isVerified: user['is_verified'] == true,
    );
  }

  static Future<SocialAccount?> _fetchInstagramProfile(
      String username, String accountId) async {
    final user = await _instagramWebProfile(username);
    if (user != null) return _instagramAccount(user, username, accountId);

    try {
      final html = await _readPublicPage(
          Uri.parse(SocialPlatform.instagram.profileUrl(username)));
      final user = _instagramUserInPage(html, username);
      if (user != null) return _instagramAccount(user, username, accountId);
      try {
        final profile =
            Uri.parse(SocialPlatform.instagram.profileUrl(username));
        final embed = await _readPublicPage(
            profile.replace(path: '${profile.path}embed/'));
        final embeddedUser = _instagramUserInPage(embed, username);
        if (embeddedUser != null) {
          return _instagramAccount(embeddedUser, username, accountId);
        }
      } catch (_) {
        // Profile metadata can still be available when embedding is disabled.
      }
      final metadata = _metadata(html);
      final title = metadata['og:title'];
      if (!_titleMatchesHandle(title, username)) return null;
      final desc = metadata['og:description'];
      final count = RegExp(r'([\d.,]+\s*[kKmM]?)\s+(?:followers|seguidores)\b',
              caseSensitive: false)
          .firstMatch(desc ?? '')
          ?.group(1);
      final name = title!.split('(').first.trim();
      return SocialAccount(
        id: accountId,
        platform: SocialPlatform.instagram,
        username: username,
        displayName: name.isEmpty ? username : name,
        avatarUrl: metadata['og:image'] ?? '',
        bio: desc ?? '',
        followers: count == null ? null : _parseFollowerString(count),
      );
    } catch (_) {
      return null;
    }
  }

  static final _channelIdPattern = RegExp(r'^UC[\w-]{22}$');
  static const _atom = 'http://www.w3.org/2005/Atom';
  static const _youtube = 'http://www.youtube.com/xml/schemas/2015';
  static const _media = 'http://search.yahoo.com/mrss/';

  static Map<String, dynamic> _youtubePageData(String html) {
    final json = RegExp(r'var ytInitialData\s*=\s*(\{[\s\S]*?\});\s*</script>')
        .firstMatch(html)
        ?.group(1);
    if (json == null) return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static Future<String> _youtubeVideosPage(String username,
      {http.Client? client}) {
    final profile = Uri.parse(SocialPlatform.youtube.profileUrl(username));
    return _readPublicPage(profile.replace(path: '${profile.path}/videos'),
        client: client);
  }

  static List<FeedItem> _youtubePageVideos(SocialAccount account, String html) {
    final data = _youtubePageData(html);
    final tabs = data['contents']?['twoColumnBrowseResultsRenderer']?['tabs'];
    if (tabs is! List)
      throw const FormatException(
          'A aba pública de vídeos não está disponível.');
    final selected = tabs
        .whereType<Map>()
        .map((tab) => tab['tabRenderer'])
        .whereType<Map>()
        .where((tab) => tab['selected'] == true)
        .firstOrNull;
    final grid = selected?['content']?['richGridRenderer']?['contents'];
    if (grid is! List) return [];

    final posts = <String, FeedItem>{};
    for (final item in grid.whereType<Map>()) {
      final content = item['richItemRenderer']?['content'];
      final lockup = content?['lockupViewModel'];
      final video = content?['videoRenderer'];
      final id = lockup?['contentId'] ?? video?['videoId'];
      if (id is! String ||
          !RegExp(r'^[\w-]{11}$').hasMatch(id) ||
          (lockup != null &&
              lockup['contentType'] != 'LOCKUP_CONTENT_TYPE_VIDEO')) {
        continue;
      }
      final title = lockup?['metadata']?['lockupMetadataViewModel']?['title']
              ?['content'] ??
          ((video?['title']?['runs'] as List?)?.firstOrNull as Map?)?['text'];
      posts.putIfAbsent(
          id,
          () => FeedItem(
                id: id,
                platform: SocialPlatform.youtube,
                accountUsername: account.username,
                authorName: account.displayName,
                authorAvatarUrl: account.avatarUrl,
                publishedAt:
                    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                caption: title is String ? title : '',
                mediaUrls: ['https://i.ytimg.com/vi/$id/hqdefault.jpg'],
                postUrl: Uri.https('www.youtube.com', '/watch', {'v': id})
                    .toString(),
                type: FeedItemType.video,
              ));
    }
    return posts.values.toList();
  }

  static Future<String> _resolveChannelId(String username,
      {http.Client? client}) async {
    if (_channelIdPattern.hasMatch(username)) return username;
    final html = await _youtubeVideosPage(username, client: client);
    final id = _metadata(html)['channelId'] ??
        RegExp(r'"externalId"\s*:\s*"(UC[\w-]{22})"')
            .firstMatch(html)
            ?.group(1);
    if (id == null || !_channelIdPattern.hasMatch(id)) {
      throw const FormatException('Canal público não confirmado.');
    }
    return id;
  }

  static Future<XmlElement> _channelFeed(String id,
      {http.Client? client}) async {
    final url =
        Uri.https('www.youtube.com', '/feeds/videos.xml', {'channel_id': id});
    final document =
        XmlDocument.parse(await _readPublicPage(url, client: client));
    if (document.rootElement.name.local != 'feed') {
      throw const FormatException('Feed do YouTube inválido.');
    }
    return document.rootElement;
  }

  static Future<SocialAccount?> _fetchYouTubeProfile(
      String username, String accountId) async {
    try {
      final id = await _resolveChannelId(username);
      String? title;
      try {
        final feed = await _channelFeed(id);
        title = feed.getElement('title', namespace: _atom)?.innerText.trim();
      } catch (_) {
        final html = await _youtubeVideosPage(username);
        final data = _youtubePageData(html);
        final metadata = data['metadata']?['channelMetadataRenderer'];
        title = metadata?['title'] as String? ?? _metadata(html)['og:title'];
        if (title == null || title.isEmpty || title == 'YouTube') rethrow;
      }
      return SocialAccount(
        id: accountId,
        platform: SocialPlatform.youtube,
        username: username,
        displayName: title == null || title.isEmpty ? username : title,
        avatarUrl: '',
        channelId: id,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<FeedItem>> _fetchYouTubeFeed(SocialAccount account,
      {http.Client? client}) async {
    final channel = account.channelId ??
        await _resolveChannelId(account.username, client: client);
    final XmlElement feed;
    try {
      feed = await _channelFeed(channel, client: client);
    } catch (_) {
      final html = await _youtubeVideosPage(account.username, client: client);
      return _youtubePageVideos(account, html);
    }
    final posts = <FeedItem>[];
    for (final entry in feed.findElements('entry', namespace: _atom)) {
      final id = entry.getElement('videoId', namespace: _youtube)?.innerText;
      final date = DateTime.tryParse(
          entry.getElement('published', namespace: _atom)?.innerText ?? '');
      if (id == null || !RegExp(r'^[\w-]{11}$').hasMatch(id) || date == null) {
        continue;
      }
      final title =
          entry.getElement('title', namespace: _atom)?.innerText ?? '';
      final media = entry.getElement('group', namespace: _media);
      final image = media
          ?.getElement('thumbnail', namespace: _media)
          ?.getAttribute('url');
      posts.add(FeedItem(
        id: id,
        platform: SocialPlatform.youtube,
        accountUsername: account.username,
        authorName: account.displayName,
        authorAvatarUrl: account.avatarUrl,
        publishedAt: date,
        caption: title,
        mediaUrls: [
          if (image != null && Uri.tryParse(image)?.scheme == 'https') image
        ],
        postUrl: Uri.https('www.youtube.com', '/watch', {'v': id}).toString(),
        type: FeedItemType.video,
      ));
    }
    return posts;
  }

  static Future<List<FeedItem>> fetchAccountFeed(
    SocialAccount account, {
    http.Client? client,
  }) async {
    if (account.platform == SocialPlatform.youtube) {
      return _fetchYouTubeFeed(account, client: client);
    }
    if (account.platform == SocialPlatform.instagram) {
      final user = await _instagramWebProfile(account.username, client: client);
      if (user?['is_private'] == true) return [];
      if (user != null) {
        final profile = _instagramAccount(user, account.username, account.id);
        final timeline = user['edge_owner_to_timeline_media'];
        final edges = timeline is Map ? timeline['edges'] : null;
        if (edges is List) {
          final posts = <String, FeedItem>{};
          for (final edge in edges) {
            final node = edge is Map ? edge['node'] : null;
            if (node is! Map<String, dynamic>) continue;
            final post = _embeddedPost(profile, node);
            if (post != null) posts.putIfAbsent(post.id, () => post);
          }
          if (posts.values.any((post) => post.mediaUrls.isNotEmpty) ||
              timeline['count'] == 0) {
            return posts.values.toList();
          }
        }
      }
    }
    final profile = Uri.parse(account.platform.profileUrl(account.username));
    final source = account.platform == SocialPlatform.x
        ? Uri.https('syndication.twitter.com',
            '/srv/timeline-profile/screen-name/${account.username}')
        : profile;
    final sources = [
      source,
      if (account.platform == SocialPlatform.instagram)
        profile.replace(path: '${profile.path}embed/'),
      if (account.platform == SocialPlatform.tiktok)
        Uri.https(profile.host, '/embed/@${account.username}'),
      if (account.platform == SocialPlatform.x) profile,
    ];
    final structured = <String, FeedItem>{};
    final username = RegExp.escape(account.username);
    final path = switch (account.platform) {
      SocialPlatform.instagram => r'^/(?:p|reel)/([\w-]+)/?$',
      SocialPlatform.tiktok => '^/@$username/video/([0-9]{1,20})/?\$',
      SocialPlatform.x => '^/$username/status/([0-9]{1,20})/?\$',
      SocialPlatform.youtube => throw StateError('Use o feed de canais.'),
    };
    final hosts = switch (account.platform) {
      SocialPlatform.instagram => {'instagram.com', 'www.instagram.com'},
      SocialPlatform.tiktok => {'tiktok.com', 'www.tiktok.com'},
      SocialPlatform.youtube => const <String>{},
      SocialPlatform.x => {
          'x.com',
          'www.x.com',
          'twitter.com',
          'www.twitter.com'
        },
    };
    final postPath = RegExp(path, caseSensitive: false);
    final posts = <String, Uri>{};
    final links =
        RegExp(r'''\bhref\s*=\s*["']([^"']+)["']''', caseSensitive: false);
    for (final uri in sources) {
      final String html;
      try {
        html = await _readPublicPage(uri, client: client);
      } catch (_) {
        continue;
      }
      if (account.platform == SocialPlatform.instagram) {
        final user = _instagramUserInPage(html, account.username);
        if (user?['is_private'] == true) return [];
      }
      if (account.platform != SocialPlatform.x) {
        for (final post in _embeddedPosts(account, html)) {
          final previous = structured[post.id];
          if (previous == null ||
              post.mediaUrls.length > previous.mediaUrls.length) {
            structured[post.id] = post;
          }
        }
      }
      for (final link in links.allMatches(html)) {
        final reference = Uri.tryParse(link.group(1)!);
        if (reference == null) continue;
        final uri = profile.resolveUri(reference);
        if (uri.scheme != 'https' || !hosts.contains(uri.host)) continue;
        final match = postPath.firstMatch(uri.path);
        if (match != null) {
          posts.putIfAbsent(
              match.group(1)!, () => profile.replace(path: uri.path));
        }
      }
      if (account.platform == SocialPlatform.instagram) {
        if (structured.values.any((post) => post.mediaUrls.isNotEmpty)) break;
      } else if (posts.isNotEmpty || structured.isNotEmpty) {
        break;
      }
    }

    if (posts.isEmpty && structured.isEmpty) {
      throw StateError('O perfil oficial nao forneceu publicacoes acessiveis.');
    }
    final entries = posts.entries
        .where((entry) => !structured.containsKey(entry.key))
        .toList();
    final items = structured.values.toList();
    const batchSize = 6;
    for (var offset = 0; offset < entries.length; offset += batchSize) {
      final batch = entries.skip(offset).take(batchSize);
      items.addAll(await Future.wait(batch.map((entry) =>
          _loadPublicPost(account, entry.key, entry.value, client))));
    }
    return items;
  }

  static Iterable<Map<String, dynamic>> _embeddedObjects(String html) sync* {
    final scripts =
        RegExp(r'<script\b([^>]*)>([\s\S]*?)</script>', caseSensitive: false);
    for (final script in scripts.allMatches(html)) {
      final attributes = script.group(1)!;
      final body = script.group(2)!;
      final serverPayload = (body.contains('display_url') ||
              body.contains('image_versions2'))
          ? RegExp(r's\.handle\((\{[\s\S]*?\})\);').firstMatch(body)?.group(1)
          : null;
      if (serverPayload == null &&
          (!attributes.contains('application/json') &&
              !attributes.contains('application/ld+json') &&
              !attributes.contains('SIGI_STATE') &&
              !attributes.contains('__UNIVERSAL_DATA_FOR_REHYDRATION__'))) {
        continue;
      }
      final Object? payload;
      try {
        payload = jsonDecode(serverPayload ?? body);
      } on FormatException {
        continue;
      }
      final pending = <Object?>[payload];
      while (pending.isNotEmpty) {
        final value = pending.removeLast();
        if (value is List) {
          pending.addAll(value.reversed);
        }
        if (value is String &&
            value.startsWith('{') &&
            (value.contains('shortcode_media') ||
                value.contains('display_url') ||
                value.contains('image_versions2'))) {
          try {
            pending.add(jsonDecode(value));
          } on FormatException {
            // Ignore strings that are not serialized data.
          }
        }
        if (value is! Map<String, dynamic>) continue;
        pending.addAll(value.values.toList().reversed);
        yield value;
      }
    }
  }

  static Map<String, dynamic>? _instagramUserInPage(
          String html, String username) =>
      _embeddedObjects(html)
          .where((user) =>
              user['username']?.toString().toLowerCase() ==
                  username.toLowerCase() &&
              (user['is_private'] is bool ||
                  user.containsKey('edge_owner_to_timeline_media') ||
                  user.containsKey('follower_count') ||
                  user.containsKey('edge_followed_by')))
          .firstOrNull;

  static Iterable<FeedItem> _embeddedPosts(
      SocialAccount account, String html) sync* {
    final user = account.platform == SocialPlatform.instagram
        ? _instagramUserInPage(html, account.username)
        : null;
    if (user?['is_private'] == true) return;
    final timeline = user?['edge_owner_to_timeline_media'];
    final edges = timeline is Map ? timeline['edges'] : null;
    if (edges is List) {
      for (final edge in edges) {
        final node = edge is Map ? edge['node'] : null;
        if (node is! Map<String, dynamic>) continue;
        final post = _embeddedPost(account, node);
        if (post != null) yield post;
      }
    }

    for (final value in _embeddedObjects(html)) {
      final author = value['author'];
      final owner = value['owner'] ?? value['user'];
      final handle = account.platform == SocialPlatform.tiktok
          ? (author is Map ? author['uniqueId'] : author)
          : (owner is Map ? owner['username'] : null);
      if (handle?.toString().toLowerCase() != account.username.toLowerCase()) {
        continue;
      }
      final post = _embeddedPost(account, value);
      if (post != null) yield post;
    }
  }

  static String? _instagramImage(Map value) {
    final versions = value['image_versions2'];
    final candidates =
        versions is Map ? versions['candidates'] : value['display_resources'];
    final urls = [
      value['display_url'],
      if (candidates is List)
        for (final item in candidates)
          if (item is Map) item['url'] ?? item['src'],
      value['thumbnail_src'],
    ];
    return urls
        .whereType<String>()
        .where((url) => Uri.tryParse(url)?.scheme == 'https')
        .firstOrNull;
  }

  static List<String> _instagramPhotos(Map<String, dynamic> value) {
    final connection = value['edge_sidecar_to_children'];
    final edges = connection is Map ? connection['edges'] : null;
    final carousel = value['carousel_media'];
    final children = [
      if (edges is List)
        for (final edge in edges)
          if (edge is Map) edge['node'],
      if (carousel is List) ...carousel,
    ];
    final photos = children
        .whereType<Map>()
        .map(_instagramImage)
        .whereType<String>()
        .toSet();
    final cover = _instagramImage(value);
    if (photos.isEmpty && cover != null) photos.add(cover);
    return photos.toList();
  }

  static FeedItem? _embeddedPost(
      SocialAccount account, Map<String, dynamic> value) {
    final profile = Uri.parse(account.platform.profileUrl(account.username));
    final video = value['video'];
    final isTikTok = account.platform == SocialPlatform.tiktok;
    final id = (isTikTok ? value['id'] : value['shortcode'] ?? value['code'])
        ?.toString();
    if (id == null ||
        !(isTikTok ? RegExp(r'^\d{1,20}$') : RegExp(r'^[\w-]+$'))
            .hasMatch(id)) {
      return null;
    }
    if (isTikTok && video is! Map) return null;
    final reel = value['product_type'] == 'clips';
    final isVideo =
        isTikTok || value['is_video'] == true || value['media_type'] == 2;
    final path = isTikTok
        ? '/@${account.username}/video/$id'
        : '/${reel ? 'reel' : 'p'}/$id/';
    final image = video is Map ? video['cover'] ?? video['originCover'] : null;
    final captionConnection = value['edge_media_to_caption'];
    final captionEdges =
        captionConnection is Map ? captionConnection['edges'] : null;
    final firstCaption = captionEdges is List ? captionEdges.firstOrNull : null;
    final captionNode = firstCaption is Map ? firstCaption['node'] : null;
    final rawCaption = isTikTok
        ? value['desc']
        : value['caption'] ?? (captionNode is Map ? captionNode['text'] : null);
    final caption = rawCaption is Map ? rawCaption['text'] : rawCaption;
    final media = isTikTok
        ? [if (image is String && Uri.tryParse(image)?.scheme == 'https') image]
        : _instagramPhotos(value);
    if (media.isEmpty && (caption is! String || caption.isEmpty)) return null;
    final directVideo = isTikTok && video is Map
        ? video['playAddr'] ?? video['downloadAddr']
        : value['video_url'];
    final time =
        value['createTime'] ?? value['taken_at_timestamp'] ?? value['taken_at'];
    final seconds = int.tryParse(time?.toString() ?? '') ?? 0;
    return FeedItem(
      id: id,
      platform: account.platform,
      accountUsername: account.username,
      authorName: account.displayName,
      authorAvatarUrl: account.avatarUrl,
      caption: caption is String ? caption : '',
      mediaUrls: media,
      videoUrl:
          directVideo is String && Uri.tryParse(directVideo)?.scheme == 'https'
              ? directVideo
              : null,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
          seconds > 0 && seconds < 10000000000 ? seconds * 1000 : 0,
          isUtc: true),
      postUrl: profile.replace(path: path).toString(),
      type: reel
          ? FeedItemType.reel
          : isVideo
              ? FeedItemType.video
              : FeedItemType.post,
    );
  }

  static final _pageCache = <Uri, (DateTime, String)>{};
  static final _pendingPages = <Uri, Future<String>>{};

  static Future<String> _readPublicPage(Uri uri, {http.Client? client}) async {
    if (client != null) return _downloadPage(uri, client);
    final cached = _pageCache[uri];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(seconds: 45)) {
      return cached.$2;
    }
    return _pendingPages.putIfAbsent(uri, () async {
      try {
        final body = await _downloadPage(uri, _client);
        final maxSize =
            uri.host == 'www.youtube.com' && uri.path.endsWith('/videos')
                ? 2 * 1024 * 1024
                : 1024 * 1024;
        if (body.length <= maxSize) {
          _pageCache.remove(uri);
          if (_pageCache.length >= 24) _pageCache.remove(_pageCache.keys.first);
          _pageCache[uri] = (DateTime.now(), body);
        }
        return body;
      } finally {
        _pendingPages.remove(uri);
      }
    });
  }

  static Future<String> _downloadPage(Uri uri, http.Client client) async {
    final response = await client.get(uri, headers: {
      for (final header in _webHeaders.entries)
        if (uri.host != 'www.instagram.com' || header.key != 'User-Agent')
          header.key: header.value,
      if (uri.host == 'www.instagram.com' &&
          uri.path == '/api/v1/users/web_profile_info/') ...{
        'x-ig-app-id': '936619743392459',
        'accept': 'application/json',
      },
    }).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  static Future<FeedItem> _loadPublicPost(
      SocialAccount account, String id, Uri url, http.Client? client) async {
    String? caption;
    String? image;
    DateTime? publishedAt;
    String? videoUrl;
    try {
      switch (account.platform) {
        case SocialPlatform.tiktok:
          final data = jsonDecode(await _readPublicPage(
              Uri.https('www.tiktok.com', '/oembed', {'url': url.toString()}),
              client: client));
          caption = data['title'] as String?;
          image = data['thumbnail_url'] as String?;
        case SocialPlatform.x:
          final data = jsonDecode(await _readPublicPage(
              Uri.https('publish.twitter.com', '/oembed',
                  {'url': url.toString(), 'omit_script': 'true'}),
              client: client));
          final paragraph = RegExp(r'<p\b[^>]*>([\s\S]*?)</p>')
              .firstMatch(data['html'] as String);
          caption = paragraph
              ?.group(1)
              ?.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
              .replaceAll(RegExp(r'<[^>]+>'), '');
        case SocialPlatform.youtube:
          break;
        case SocialPlatform.instagram:
          final html = await _readPublicPage(url, client: client);
          final metadata = _metadata(html);
          caption = metadata['og:description'];
          image = metadata['og:image'];
          videoUrl = metadata['og:video:secure_url'] ?? metadata['og:video'];
          publishedAt =
              DateTime.tryParse(metadata['article:published_time'] ?? '');
      }
    } catch (_) {
      // Keep the permalink if the preview is unavailable.
    }

    final numericId = BigInt.tryParse(id);
    if (numericId != null && account.platform == SocialPlatform.x) {
      publishedAt = DateTime.fromMillisecondsSinceEpoch(
          (numericId >> 22).toInt() + 1288834974657,
          isUtc: true);
    }

    return FeedItem(
      id: id,
      platform: account.platform,
      accountUsername: account.username,
      authorName: account.displayName,
      authorAvatarUrl: account.avatarUrl,
      publishedAt:
          publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      caption: (caption ?? '')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&'),
      mediaUrls: Uri.tryParse(image ?? '')?.scheme == 'https' ? [image!] : [],
      postUrl: url.toString(),
      videoUrl:
          Uri.tryParse(videoUrl ?? '')?.scheme == 'https' ? videoUrl : null,
      type: account.platform == SocialPlatform.tiktok
          ? FeedItemType.video
          : (url.path.startsWith('/reel/') || videoUrl != null)
              ? FeedItemType.reel
              : FeedItemType.post,
    );
  }

  static bool _titleMatchesHandle(String? title, String username) =>
      title != null &&
      RegExp(
        '(?:^|[^a-z0-9_.])@${RegExp.escape(username)}(?![a-z0-9_.])',
        caseSensitive: false,
      ).hasMatch(title);

  static Map<String, String> _metadata(String html) {
    final metadata = <String, String>{};
    final attribute = RegExp(r"""([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')""");
    for (final match
        in RegExp(r'<meta\b[^>]*>', caseSensitive: false).allMatches(html)) {
      final attributes = {
        for (final part in attribute.allMatches(match.group(0)!))
          part.group(1)!.toLowerCase(): part.group(2) ?? part.group(3)!,
      };
      final key = attributes['property'] ??
          attributes['name'] ??
          attributes['itemprop'];
      final value = attributes['content'];
      if (key != null && value != null)
        metadata.putIfAbsent(
            key,
            () => value.replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'),
                    (match) {
                  final entity = match.group(1)!;
                  final hex = entity.startsWith('x');
                  final code = int.tryParse(hex ? entity.substring(1) : entity,
                      radix: hex ? 16 : 10);
                  return code != null && code <= 0x10ffff
                      ? String.fromCharCode(code)
                      : match.group(0)!;
                }).replaceAll('&amp;', '&'));
    }
    return metadata;
  }

  static SocialAccount _buildFallbackProfile(
    SocialPlatform platform,
    String username,
    String accountId,
  ) {
    final formattedName = username
        .split('.')
        .map((part) =>
            part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : '')
        .join(' ');

    return SocialAccount(
      id: accountId,
      platform: platform,
      username: username,
      displayName: formattedName.isNotEmpty ? formattedName : username,
      avatarUrl: '',
      bio: 'Conta de ${platform.displayName} adicionada ao SocialFeed.',
    );
  }

  static int? _parseFollowerString(String input) {
    final value = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final suffix = value.endsWith('m') || value.endsWith('k')
        ? value[value.length - 1]
        : null;
    if (suffix == null) {
      return int.tryParse(value.replaceAll(RegExp(r'[.,]'), ''));
    }
    final amount = double.tryParse(
        value.substring(0, value.length - 1).replaceAll(',', '.'));
    return amount == null
        ? null
        : (amount * (suffix == 'm' ? 1000000 : 1000)).round();
  }
}
