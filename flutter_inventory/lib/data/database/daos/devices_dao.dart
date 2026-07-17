import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/linked_devices_table.dart';

part 'devices_dao.g.dart';

@DriftAccessor(tables: [LinkedDevicesTable])
class DevicesDao extends DatabaseAccessor<AppDatabase> with _$DevicesDaoMixin {
  DevicesDao(super.db);

  Stream<List<LinkedDevicesTableData>> watchAllDevices() {
    return (select(linkedDevicesTable)
          ..where((d) => d.isActive.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.linkedAt)]))
        .watch();
  }

  Future<List<LinkedDevicesTableData>> getAllDevices() {
    return (select(linkedDevicesTable)
          ..where((d) => d.isActive.equals(true)))
        .get();
  }

  Future<void> insertDevice(LinkedDevicesTableCompanion device) async {
    await into(linkedDevicesTable).insertOnConflictUpdate(device);
  }

  Future<void> updateDevice(LinkedDevicesTableCompanion device) async {
    await (update(linkedDevicesTable)
          ..where((d) => d.id.equals(device.id.value)))
        .write(device);
  }

  Future<void> deleteDevice(String id) async {
    await (update(linkedDevicesTable)..where((d) => d.id.equals(id))).write(
      const LinkedDevicesTableCompanion(isActive: Value(false)),
    );
  }

  Future<void> updateLastSync(String id) async {
    await (update(linkedDevicesTable)..where((d) => d.id.equals(id))).write(
      LinkedDevicesTableCompanion(lastSyncAt: Value(DateTime.now())),
    );
  }
}
