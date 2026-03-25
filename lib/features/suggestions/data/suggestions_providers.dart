import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/network/api_client.dart';

part 'suggestions_providers.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> outfitSuggestions(
  OutfitSuggestionsRef ref, {
  required String occasion,
}) async {
  final db = ref.read(appDatabaseProvider);
  final api = ref.read(apiClientProvider);

  final items = await db.select(db.clothingItems).get();

  if (items.isEmpty) return [];

  final wardrobeData = items.map((item) => {
    'id': item.id,
    'type': item.type,
    'sub_type': item.subType,
    'colors': jsonDecode(item.dominantColors),
    'tags': jsonDecode(item.tags),
    'occasions': jsonDecode(item.occasions),
    'seasons': jsonDecode(item.seasons),
    'image_path': item.croppedImagePath ?? item.imagePath,
  }).toList();

  try {
    return await api.getSuggestions(
      wardrobeItems: wardrobeData,
      occasion: occasion,
    );
  } catch (e) {
    // Fallback: return local basic suggestions if backend is down
    return _localSuggestions(wardrobeData, occasion);
  }
}

List<Map<String, dynamic>> _localSuggestions(
  List<Map<String, dynamic>> items,
  String occasion,
) {
  // Basic local suggestion: pair tops with bottoms
  final tops = items.where((i) {
    final type = (i['type'] as String).toLowerCase();
    return type.contains('shirt') ||
        type.contains('top') ||
        type.contains('blouse') ||
        type.contains('t-shirt');
  }).toList();

  final bottoms = items.where((i) {
    final type = (i['type'] as String).toLowerCase();
    return type.contains('pant') ||
        type.contains('jeans') ||
        type.contains('skirt') ||
        type.contains('shorts');
  }).toList();

  final suggestions = <Map<String, dynamic>>[];

  for (final top in tops.take(3)) {
    for (final bottom in bottoms.take(3)) {
      suggestions.add({
        'name': '${top['type']} + ${bottom['type']}',
        'items': [top, bottom],
        'score': 0.7,
        'reason': 'Basic pairing suggestion (backend offline)',
      });
    }
  }

  return suggestions.take(5).toList();
}
