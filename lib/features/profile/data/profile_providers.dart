import 'dart:io';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/network/api_client.dart';

part 'profile_providers.g.dart';

class WardrobeStats {
  final int totalItems;
  final int categories;
  final int favoriteOutfits;

  WardrobeStats({
    required this.totalItems,
    required this.categories,
    required this.favoriteOutfits,
  });
}

@riverpod
Stream<UserProfile?> userProfile(UserProfileRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.userProfiles)..limit(1))
      .watchSingleOrNull();
}

@riverpod
Future<void> saveBodyPhoto(SaveBodyPhotoRef ref, File photo) async {
  final db = ref.read(appDatabaseProvider);

  final existing = await (db.select(db.userProfiles)..limit(1)).getSingleOrNull();

  if (existing != null) {
    await (db.update(db.userProfiles)..where((t) => t.id.equals(existing.id)))
        .write(UserProfilesCompanion(bodyImagePath: Value(photo.path)));
  } else {
    await db.into(db.userProfiles).insert(
      UserProfilesCompanion.insert(bodyImagePath: photo.path),
    );
  }
}

@riverpod
Future<WardrobeStats> wardrobeStats(WardrobeStatsRef ref) async {
  final db = ref.read(appDatabaseProvider);

  final items = await db.select(db.clothingItems).get();
  final outfits = await (db.select(db.outfits)
        ..where((t) => t.isFavorite.equals(true)))
      .get();

  final categories = items.map((i) => i.type).toSet().length;

  return WardrobeStats(
    totalItems: items.length,
    categories: categories,
    favoriteOutfits: outfits.length,
  );
}

@riverpod
Future<bool> backendHealth(BackendHealthRef ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final result = await api.healthCheck();
    return result['status'] == 'ok';
  } catch (_) {
    return false;
  }
}
