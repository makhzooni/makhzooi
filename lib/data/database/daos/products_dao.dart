import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/categories_table.dart';
import '../tables/images_table.dart';

part 'products_dao.g.dart';

class ProductWithCategory {
  final ProductsTableData product;
  final CategoriesTableData? category;
  final List<ImagesTableData> images;

  ProductWithCategory({
    required this.product,
    this.category,
    this.images = const [],
  });
}

@DriftAccessor(tables: [ProductsTable, CategoriesTable, ImagesTable])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// مشاهدة جميع المنتجات مع تصنيفاتها
  Stream<List<ProductWithCategory>> watchAllProducts() {
    final query = (select(productsTable)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .join([
      leftOuterJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(productsTable.categoryId),
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      final products = <ProductWithCategory>[];
      for (final row in rows) {
        final product = row.readTable(productsTable);
        final category = row.readTableOrNull(categoriesTable);
        final images = await (select(imagesTable)
              ..where((i) => i.productId.equals(product.id))
              ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
            .get();
        products.add(ProductWithCategory(
          product: product,
          category: category,
          images: images,
        ));
      }
      return products;
    });
  }

  /// منتجات منخفضة المخزون
  Stream<List<ProductsTableData>> watchLowStockProducts() {
    return (select(productsTable)
          ..where((p) =>
              p.isActive.equals(true) &
              p.quantity.isSmallerOrEqual(p.lowStockThreshold)))
        .watch();
  }

  /// البحث في المنتجات
  Future<List<ProductWithCategory>> searchProducts(String query) async {
    final q = '%$query%';
    final rows = await (select(productsTable)
          ..where((p) =>
              p.isActive.equals(true) &
              (p.name.like(q) | p.description.like(q) | p.sku.like(q)))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .join([
      leftOuterJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(productsTable.categoryId),
      ),
    ]).get();

    final products = <ProductWithCategory>[];
    for (final row in rows) {
      final product = row.readTable(productsTable);
      final category = row.readTableOrNull(categoriesTable);
      products.add(ProductWithCategory(
        product: product,
        category: category,
      ));
    }
    return products;
  }

  /// منتج بالـ ID
  Future<ProductWithCategory?> getProductById(String id) async {
    final rows = await (select(productsTable)
          ..where((p) => p.id.equals(id)))
        .join([
      leftOuterJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(productsTable.categoryId),
      ),
    ]).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    final product = row.readTable(productsTable);
    final category = row.readTableOrNull(categoriesTable);
    final images = await (select(imagesTable)
          ..where((i) => i.productId.equals(id))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .get();

    return ProductWithCategory(
      product: product,
      category: category,
      images: images,
    );
  }

  /// إضافة منتج
  Future<void> insertProduct(ProductsTableCompanion product) async {
    await into(productsTable).insertOnConflictUpdate(product);
  }

  /// تحديث منتج
  Future<void> updateProduct(ProductsTableCompanion product) async {
    await (update(productsTable)
          ..where((p) => p.id.equals(product.id.value)))
        .write(product);
  }

  /// حذف منتج (ناعم - تعطيل)
  Future<void> softDeleteProduct(String id) async {
    await (update(productsTable)..where((p) => p.id.equals(id))).write(
      ProductsTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// تحديث الكمية
  Future<void> updateQuantity(String id, int quantity) async {
    await (update(productsTable)..where((p) => p.id.equals(id))).write(
      ProductsTableCompanion(
        quantity: Value(quantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// جميع المنتجات للتصدير
  Future<List<ProductWithCategory>> getAllProducts() async {
    final rows = await (select(productsTable)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .join([
      leftOuterJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(productsTable.categoryId),
      ),
    ]).get();

    return rows
        .map((row) => ProductWithCategory(
              product: row.readTable(productsTable),
              category: row.readTableOrNull(categoriesTable),
            ))
        .toList();
  }
}
