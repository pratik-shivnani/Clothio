import 'package:drift/drift.dart';

class ClothingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imagePath => text()();
  TextColumn get croppedImagePath => text().nullable()();
  TextColumn get type => text()();
  TextColumn get subType => text().nullable()();
  TextColumn get dominantColors => text().withDefault(const Constant('[]'))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get occasions => text().withDefault(const Constant('[]'))();
  TextColumn get seasons => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bodyImagePath => text()();
  TextColumn get name => text().withDefault(const Constant('Default'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TryOnResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userProfileId => integer().references(UserProfiles, #id)();
  TextColumn get clothingItemIds => text()();
  TextColumn get resultImagePath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Outfits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get clothingItemIds => text()();
  TextColumn get occasion => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastWornAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
