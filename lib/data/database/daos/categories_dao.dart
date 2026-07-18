import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';
import '../tables/products_table.dart';

part 'categories_dao.g.dart';

class CategoryWithCount {
  final CategoriesTableData category;
  final int productCount;
  CategoryWithCount({required this.category, required this.productCount});
}

@DriftAccessor(tables: [CategoriesTable, ProductsTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<CategoriesTableData>> watchAllCategories() {
    return (select(categoriesTable)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<List<CategoriesTableData>> getAllCategories() {
    return (select(categoriesTable)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<CategoriesTableData?> getCategoryById(String id) {
    return (select(categoriesTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertCategory(CategoriesTableCompanion category) async {
    await into(categoriesTable).insertOnConflictUpdate(category);
  }

  Future<void> updateCategory(CategoriesTableCompanion category) async {
    await (update(categoriesTable)
          ..where((c) => c.id.equals(category.id.value)))
        .write(category);
  }

  Future<void> deleteCategory(String id) async {
    await (delete(categoriesTable)..where((c) => c.id.equals(id))).go();
  }

  /// عدد المنتجات لكل تصنيف
  Future<int> getProductCount(String categoryId) async {
    final count = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([count])
      ..where(productsTable.categoryId.equals(categoryId) &
          productsTable.isActive.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
