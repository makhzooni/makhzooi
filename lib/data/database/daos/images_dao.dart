import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/images_table.dart';

part 'images_dao.g.dart';

@DriftAccessor(tables: [ImagesTable])
class ImagesDao extends DatabaseAccessor<AppDatabase> with _$ImagesDaoMixin {
  ImagesDao(super.db);

  Future<List<ImagesTableData>> getImagesByProduct(String productId) {
    return (select(imagesTable)
          ..where((i) => i.productId.equals(productId))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .get();
  }

  Future<ImagesTableData> insertImage(ImagesTableCompanion image) async {
    final rowId = await into(imagesTable).insert(image);
    return (select(imagesTable)
          ..where((i) => i.id.equals(rowId)))
        .getSingle();
  }

  Future<void> deleteImage(int id) async {
    await (delete(imagesTable)..where((i) => i.id.equals(id))).go();
  }

  Future<void> deleteAllProductImages(String productId) async {
    await (delete(imagesTable)
          ..where((i) => i.productId.equals(productId)))
        .go();
  }

  Future<void> updateSortOrder(int id, int sortOrder) async {
    await (update(imagesTable)..where((i) => i.id.equals(id))).write(
      ImagesTableCompanion(sortOrder: Value(sortOrder)),
    );
  }
}
