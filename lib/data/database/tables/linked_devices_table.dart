import 'package:drift/drift.dart';

class LinkedDevicesTable extends Table {
  @override
  String get tableName => 'linked_devices';

  TextColumn get id => text()(); // device_id
  TextColumn get deviceName => text()();
  TextColumn get token => text()();
  TextColumn get ipAddress => text().nullable()();
  IntColumn get port => integer().nullable()();
  DateTimeColumn get linkedAt => dateTime()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
