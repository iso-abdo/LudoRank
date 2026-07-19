import 'package:drift/drift.dart';

class Players extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get nickname => text().nullable()();

  TextColumn get avatar => text().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}