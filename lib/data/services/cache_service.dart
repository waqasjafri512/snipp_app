import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String feedBoxName = 'feed_cache';
  static const String chatBoxName = 'chat_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(feedBoxName);
    await Hive.openBox(chatBoxName);
  }

  // Cache feed data
  Future<void> cacheFeed(List<dynamic> feed) async {
    try {
      final box = Hive.box(feedBoxName);
      await box.put('dares_list', feed);
    } catch (e) {
      print('Error caching feed: $e');
    }
  }

  // Get cached feed
  List<dynamic> getCachedFeed() {
    try {
      final box = Hive.box(feedBoxName);
      return box.get('dares_list', defaultValue: []) as List;
    } catch (e) {
      print('Error retrieving feed cache: $e');
      return [];
    }
  }

  // Cache conversation list
  Future<void> cacheConversations(List<dynamic> conversations) async {
    try {
      final box = Hive.box(chatBoxName);
      await box.put('conversations_list', conversations);
    } catch (e) {
      print('Error caching conversations: $e');
    }
  }

  // Get cached conversations
  List<dynamic> getCachedConversations() {
    try {
      final box = Hive.box(chatBoxName);
      return box.get('conversations_list', defaultValue: []) as List;
    } catch (e) {
      print('Error retrieving conversations cache: $e');
      return [];
    }
  }

  // Clear all caches
  Future<void> clearAll() async {
    try {
      await Hive.box(feedBoxName).clear();
      await Hive.box(chatBoxName).clear();
    } catch (e) {
      print('Error clearing Hive caches: $e');
    }
  }
}
