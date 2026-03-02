import 'package:drift/drift.dart';

enum AuditAction {
  created,
  statusChanged,
  edited,
  photoAdded,
  noteAdded,
  conflictResolved,
  synced,
}

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workOrderId => text()();
  TextColumn get action => textEnum<AuditAction>()();
  TextColumn get performedBy => text()();
  DateTimeColumn get performedAt => dateTime()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get note => text().nullable()();
}
