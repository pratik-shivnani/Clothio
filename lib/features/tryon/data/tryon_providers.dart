import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/network/api_client.dart';

part 'tryon_providers.g.dart';

@riverpod
Future<File> performTryOn(
  PerformTryOnRef ref, {
  required File bodyImage,
  required int clothingItemId,
}) async {
  final db = ref.read(appDatabaseProvider);
  final api = ref.read(apiClientProvider);

  final item = await (db.select(db.clothingItems)
        ..where((t) => t.id.equals(clothingItemId)))
      .getSingle();

  final clothingFile = File(item.croppedImagePath ?? item.imagePath);

  final resultBytes = await api.tryOn(
    bodyImage: bodyImage,
    clothingImage: clothingFile,
  );

  final appDir = await getApplicationDocumentsDirectory();
  final tryOnDir = Directory(p.join(appDir.path, 'tryon_results'));
  if (!await tryOnDir.exists()) {
    await tryOnDir.create(recursive: true);
  }

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final resultFile = File(p.join(tryOnDir.path, 'tryon_$timestamp.png'));
  await resultFile.writeAsBytes(resultBytes);

  // Save to DB
  await db.into(db.tryOnResults).insert(TryOnResultsCompanion.insert(
    userProfileId: 1, // Default profile for now
    clothingItemIds: '[$clothingItemId]',
    resultImagePath: resultFile.path,
  ));

  return resultFile;
}
