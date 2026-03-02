import 'package:drift/drift.dart';

enum WorkOrderStatus { newOrder, inProgress, completed, verified }

@DataClassName('WorkOrderRow')
class WorkOrders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<WorkOrderStatus>()();
  TextColumn get assignedTo => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get locationLabel => text().nullable()();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(true))();
  IntColumn get localVersion => integer().withDefault(const Constant(1))();
  IntColumn get serverVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
