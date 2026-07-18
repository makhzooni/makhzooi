import 'package:drift/drift.dart';
import 'categories_table.dart';

class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  TextColumn get categoryId =>
      text().nullable().references(CategoriesTable, #id)();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()(); // رقم المنتج
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
