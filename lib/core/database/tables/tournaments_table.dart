import 'package:drift/drift.dart';

class Tournaments extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get rounds => integer()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}