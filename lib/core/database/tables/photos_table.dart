import 'package:drift/drift.dart';

import 'work_orders_table.dart';

@DataClassName('PhotoRow')
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get workOrderId =>
      text().references(WorkOrders, #id, onDelete: KeyAction.cascade)();
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get capturedBy => text()();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
