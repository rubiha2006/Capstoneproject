import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'community_form.dart';

class DatabaseHelper {
  static const _boxName = 'communityPostsBox';
  static Box<CommunityPost>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CommunityPostAdapter());
    }

    if (_box == null) {
      try {
        // For mobile platforms
        final appDir = await path_provider.getApplicationDocumentsDirectory();
        Hive.init(appDir.path);
      } catch (e) {
        // For web platforms
        Hive.initFlutter();
      }
      _box = await Hive.openBox<CommunityPost>(_boxName);
    }
  }

  static Future<void> insertPost(CommunityPost post) async {
    await _box?.put(post.id, post);
  }

  static Future<List<CommunityPost>> getPosts() async {
    return _box?.values.toList() ?? [];
  }

  static Future<List<CommunityPost>> searchPosts(String query) async {
    final allPosts = _box?.values.toList() ?? [];
    return allPosts
        .where(
          (post) =>
              post.plantName.toLowerCase().contains(query.toLowerCase()) ||
              post.disease.toLowerCase().contains(query.toLowerCase()) ||
              post.userName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  static Future<void> deletePost(String id) async {
    await _box?.delete(id);
  }

  static Future<void> close() async {
    await _box?.close();
  }
}
