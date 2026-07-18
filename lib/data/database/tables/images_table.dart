import 'package:drift/drift.dart';
import 'products_table.dart';

class ImagesTable extends Table {
  @override
  String get tableName => 'images';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId =>
      text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get imagePath => text()(); // المسار الكامل للصورة
  TextColumn get thumbnailPath => text().nullable()(); // مسار الصورة المصغرة
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
