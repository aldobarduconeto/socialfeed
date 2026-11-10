import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_type.dart';
import '../models/social_account.dart';
import '../models/feed_item.dart';

class StorageService {
  static const String _accountsKey = 'sf_saved_accounts_v2';
  static const String _cachedFeedKey = 'sf_cached_feed_v4';
  static const String _seenStoriesKey = 'sf_seen_stories_v2';
  static const String _initializedKey = 'sf_accounts_initialized';

  static Future<List<SocialAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final isInit = prefs.getBool(_initializedKey) ?? false;

    if (!isInit) {
      // First run: provide curated starter accounts
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
    } catch (e) {
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
