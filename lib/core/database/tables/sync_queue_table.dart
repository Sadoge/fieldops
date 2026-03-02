import 'package:drift/drift.dart';

enum SyncOperation { create, update, delete }

enum SyncItemStatus { pending, inFlight, failed, completed }

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => textEnum<SyncOperation>()();
  TextColumn get status =>
      textEnum<SyncItemStatus>()
          .withDefault(const Constant('pending'))();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
