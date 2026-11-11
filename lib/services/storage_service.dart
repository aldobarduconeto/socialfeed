import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../models/feed_item.dart';

class StorageService {
  static const String _accountsKey = 'sf_saved_accounts_v2';
  static const String _cachedFeedKey = 'sf_cached_feed_v4';
  static const String _seenStoriesKey = 'sf_seen_stories_v2';
  static const String _savedPostsKey = 'sf_saved_posts_v2';
  static const String _compactViewKey = 'sf_compact_view_v1';
  static const String _autoPlayKey = 'sf_autoplay_videos_v1';
  static const String _initializedKey = 'sf_accounts_initialized';

  // --- ACCOUNTS ---
  static Future<List<SocialAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final isInit = prefs.getBool(_initializedKey) ?? false;

    if (!isInit) {
      final defaultList = getStarterAccounts();
      await saveAccounts(defaultList);
      await prefs.setBool(_initializedKey, true);
      return defaultList;
    }

    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        final data = item as Map<String, dynamic>;
        if (Uri.tryParse(data['avatarUrl'] as String? ?? '')?.host ==
            'images.unsplash.com') {
          data['avatarUrl'] = '';
        }
        return SocialAccount.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAccounts(List<SocialAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = accounts.map((a) => a.toJson()).toList();
    await prefs.setString(_accountsKey, jsonEncode(jsonList));
  }

  static Future<List<SocialAccount>> addAccount(SocialAccount account) =>
      addAccounts([account]);

  static Future<List<SocialAccount>> addAccounts(
      List<SocialAccount> additions) async {
    final accounts = await loadAccounts();
    for (final account in additions) {
      final index = accounts.indexWhere(
        (saved) =>
            saved.platform == account.platform &&
            (saved.username.toLowerCase() == account.username.toLowerCase() ||
                (account.channelId != null &&
                    saved.channelId == account.channelId)),
      );
      if (index >= 0) {
        accounts[index] = account.copyWith(
            id: accounts[index].id, username: accounts[index].username);
      } else {
        accounts.insert(0, account);
      }
    }
    await saveAccounts(accounts);
    return accounts;
  }

  static Future<List<SocialAccount>> removeAccount(String accountId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);
    return accounts;
  }

  static Future<List<SocialAccount>> toggleAccountActive(
      String accountId) async {
    final accounts = await loadAccounts();
    final idx = accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      final current = accounts[idx];
      accounts[idx] = current.copyWith(isActive: !current.isActive);
      await saveAccounts(accounts);
    }
    return accounts;
  }

  // --- FEED CACHE ---
  static Future<List<FeedItem>> loadCachedFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedFeedKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => FeedItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCachedFeed(List<FeedItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = items.map((i) => i.toJson()).toList();
    await prefs.setString(_cachedFeedKey, jsonEncode(toSave));
  }

  // --- SAVED / BOOKMARKED POSTS ---
  static Future<List<FeedItem>> loadSavedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedPostsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => FeedItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePost(FeedItem item) async {
    final posts = await loadSavedPosts();
    final exists = posts.any(
      (p) => p.id == item.id && p.platform == item.platform,
    );
    if (!exists) {
      posts.insert(0, item);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _savedPostsKey,
        jsonEncode(posts.map((p) => p.toJson()).toList()),
      );
    }
  }

  static Future<void> removeSavedPost(String id, SocialPlatform platform) async {
    final posts = await loadSavedPosts();
    posts.removeWhere((p) => p.id == id && p.platform == platform);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedPostsKey,
      jsonEncode(posts.map((p) => p.toJson()).toList()),
    );
  }

  static Future<bool> isPostSaved(String id, SocialPlatform platform) async {
    final posts = await loadSavedPosts();
    return posts.any((p) => p.id == id && p.platform == platform);
  }

  static Future<bool> toggleSavePost(FeedItem item) async {
    final saved = await isPostSaved(item.id, item.platform);
    if (saved) {
      await removeSavedPost(item.id, item.platform);
      return false;
    } else {
      await savePost(item);
      return true;
    }
  }

  static Future<void> clearAllSavedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPostsKey);
  }

  // --- SEEN STORIES ---
  static Future<Set<String>> loadSeenStories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenStoriesKey) ?? [];
    return list.toSet();
  }

  static Future<void> markStoryAsSeen(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenStoriesKey) ?? [];
    if (!list.contains(storyId)) {
      list.add(storyId);
      await prefs.setStringList(_seenStoriesKey, list);
    }
  }

  // --- USER PREFERENCES ---
  static Future<bool> loadCompactView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactViewKey) ?? false;
  }

  static Future<void> saveCompactView(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactViewKey, enabled);
  }

  static Future<bool> loadAutoPlay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPlayKey) ?? true;
  }

  static Future<void> saveAutoPlay(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayKey, enabled);
  }

  // --- BACKUP & RESTORE ---
  static Future<String> exportBackupJson() async {
    final accounts = await loadAccounts();
    final savedPosts = await loadSavedPosts();
    final backup = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'savedPosts': savedPosts.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<int> importBackupJson(String rawJson) async {
    final Map<String, dynamic> data = jsonDecode(rawJson);
    var importedCount = 0;

    if (data['accounts'] is List) {
      final List<dynamic> accountsRaw = data['accounts'];
      final List<SocialAccount> parsed = [];
      for (final item in accountsRaw) {
        try {
          parsed.add(SocialAccount.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
      if (parsed.isNotEmpty) {
        await addAccounts(parsed);
        importedCount = parsed.length;
      }
    }

    if (data['savedPosts'] is List) {
      final List<dynamic> postsRaw = data['savedPosts'];
      for (final item in postsRaw) {
        try {
          final post = FeedItem.fromJson(item as Map<String, dynamic>);
          await savePost(post);
        } catch (_) {}
      }
    }

    return importedCount;
  }

  // --- STARTER ACCOUNTS ---
  static List<SocialAccount> getStarterAccounts() {
    return [
      SocialAccount(
        id: 'acc_ig_cristiano',
        platform: SocialPlatform.instagram,
        username: 'cristiano',
        displayName: 'Cristiano Ronaldo',
        avatarUrl:
            'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200&fit=crop&crop=faces',
        bio: 'SIUUU! Athlete, father & entrepreneur.',
        followers: 638000000,
        isVerified: true,
      ),
      SocialAccount(
        id: 'acc_x_elonmusk',
        platform: SocialPlatform.x,
        username: 'elonmusk',
        displayName: 'Elon Musk',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&fit=crop&crop=faces',
        bio: 'Technoking of Tesla, Chief Troll Officer at X.',
        followers: 198000000,
        isVerified: true,
      ),
      SocialAccount(
        id: 'acc_tt_khaby',
        platform: SocialPlatform.tiktok,
        username: 'khaby.lame',
        displayName: 'Khaby Lame',
        avatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&fit=crop&crop=faces',
        bio: 'Se vuoi ridere sei nel posto giusto 🤷‍♂️',
        followers: 162000000,
        isVerified: true,
      ),
      SocialAccount(
        id: 'acc_ig_natgeo',
        platform: SocialPlatform.instagram,
        username: 'natgeo',
        displayName: 'National Geographic',
        avatarUrl:
            'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=200&fit=crop',
        bio:
            'Experience the world through the eyes of National Geographic photographers.',
        followers: 284000000,
        isVerified: true,
      ),
    ];
  }
}
