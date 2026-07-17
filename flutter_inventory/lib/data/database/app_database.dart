import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/products_table.dart';
import 'tables/categories_table.dart';
import 'tables/images_table.dart';
import 'tables/linked_devices_table.dart';
import 'daos/products_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/images_dao.dart';
import 'daos/devices_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ProductsTable,
    CategoriesTable,
    ImagesTable,
    LinkedDevicesTable,
  ],
  daos: [
    ProductsDao,
    CategoriesDao,
    ImagesDao,
    DevicesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // إدراج تصنيفات افتراضية
          await _insertDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          // ترحيل المخطط عند الترقية
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  Future<void> _insertDefaultCategories() async {
    final defaults = [
      CategoriesTableCompanion.insert(
        id: 'cat_electronics',
        name: 'إلكترونيات',
        color: '#1565C0',
        icon: 'devices',
        createdAt: DateTime.now(),
      ),
      CategoriesTableCompanion.insert(
        id: 'cat_clothing',
        name: 'ملابس',
        color: '#2E7D32',
        icon: 'checkroom',
        createdAt: DateTime.now(),
      ),
      CategoriesTableCompanion.insert(
        id: 'cat_food',
        name: 'مواد غذائية',
        color: '#E65100',
        icon: 'restaurant',
        createdAt: DateTime.now(),
      ),
      CategoriesTableCompanion.insert(
        id: 'cat_tools',
        name: 'أدوات',
        color: '#37474F',
        icon: 'build',
        createdAt: DateTime.now(),
      ),
      CategoriesTableCompanion.insert(
        id: 'cat_other',
        name: 'أخرى',
        color: '#6A1B9A',
        icon: 'category',
        createdAt: DateTime.now(),
      ),
    ];
    for (final category in defaults) {
      await into(categoriesTable).insertOnConflictUpdate(category);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventory.db'));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}
