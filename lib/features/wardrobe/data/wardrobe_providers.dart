import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/network/api_client.dart';

part 'wardrobe_providers.g.dart';

class ProcessedClothingResult {
  final File? croppedImage;
  final Map<String, dynamic>? classification;

  ProcessedClothingResult({this.croppedImage, this.classification});
}

@riverpod
Stream<List<ClothingItem>> clothingItems(ClothingItemsRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.clothingItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
}

@riverpod
Future<ProcessedClothingResult> processClothingImage(
  ProcessClothingImageRef ref,
  File imageFile,
) async {
  final api = ref.read(apiClientProvider);

  try {
    final bgRemovedBytes = await api.removeBackground(imageFile);
    final classification = await api.classifyClothing(imageFile);

    final appDir = await getApplicationDocumentsDirectory();
    final clothingDir = Directory(p.join(appDir.path, 'clothing'));
    if (!await clothingDir.exists()) {
      await clothingDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final croppedFile = File(p.join(clothingDir.path, 'cropped_$timestamp.png'));
    await croppedFile.writeAsBytes(bgRemovedBytes);

    return ProcessedClothingResult(
      croppedImage: croppedFile,
      classification: classification,
    );
  } catch (e) {
    throw Exception('Backend processing failed: $e');
  }
}

@riverpod
Future<void> saveClothingItem(
  SaveClothingItemRef ref, {
  required String imagePath,
  String? croppedImagePath,
  required Map<String, dynamic> classification,
}) async {
  final db = ref.read(appDatabaseProvider);

  await db.into(db.clothingItems).insert(ClothingItemsCompanion.insert(
    imagePath: imagePath,
    croppedImagePath: Value(croppedImagePath),
    type: (classification['type'] as String?) ?? 'Unknown',
    subType: Value(classification['sub_type'] as String?),
    dominantColors: Value(jsonEncode(classification['colors'] ?? [])),
    tags: Value(jsonEncode(classification['tags'] ?? [])),
    occasions: Value(jsonEncode(classification['occasions'] ?? [])),
    seasons: Value(jsonEncode(classification['seasons'] ?? [])),
  ));
}
