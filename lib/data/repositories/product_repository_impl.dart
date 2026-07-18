import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_image.dart';
import '../../domain/repositories/product_repository.dart';
import '../database/app_database.dart';
import '../database/daos/products_dao.dart';
import '../database/tables/products_table.dart';
import 'package:drift/drift.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductsDao _productsDao;

  ProductRepositoryImpl(this._productsDao);

  @override
  Stream<List<Product>> watchAllProducts() {
    return _productsDao.watchAllProducts().map(
          (list) => list.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<List<Product>> watchLowStockProducts() {
    return _productsDao.watchLowStockProducts().map(
          (list) => list
              .map((p) => Product(
                    id: p.id,
                    name: p.name,
                    quantity: p.quantity,
                    price: p.price,
                    lowStockThreshold: p.lowStockThreshold,
                    createdAt: p.createdAt,
                    updatedAt: p.updatedAt,
                    isActive: p.isActive,
                  ))
              .toList(),
        );
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final result = await _productsDao.getProductById(id);
      if (result == null) {
        return Left(DatabaseFailure('المنتج غير موجود'));
      }
      return Right(_mapToEntity(result));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      final results = await _productsDao.searchProducts(query);
      return Right(results.map(_mapToEntity).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
      String categoryId) async {
    try {
      final all = await _productsDao.getAllProducts();
      final filtered = all
          .where((p) => p.product.categoryId == categoryId)
          .map(_mapToEntity)
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> saveProduct(Product product,
      {bool isNew = true}) async {
    try {
      final companion = ProductsTableCompanion(
        id: Value(product.id),
        name: Value(product.name),
        description: Value(product.description),
        quantity: Value(product.quantity),
        price: Value(product.price),
        categoryId: Value(product.categoryId),
        thumbnailPath: Value(product.thumbnailPath),
        lowStockThreshold: Value(product.lowStockThreshold),
        createdAt: Value(product.createdAt),
        updatedAt: Value(DateTime.now()),
        barcode: Value(product.barcode),
        sku: Value(product.sku),
        isActive: Value(product.isActive),
      );

      if (isNew) {
        await _productsDao.insertProduct(companion);
      } else {
        await _productsDao.updateProduct(companion);
      }

      // تحقق من نقص المخزون وأرسل إشعار
      if (product.isLowStock) {
        await NotificationService.showLowStockNotification(
          productName: product.name,
          quantity: product.quantity,
          threshold: product.lowStockThreshold,
        );
      }

      return Right(product.id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _productsDao.softDeleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateQuantity(String id, int quantity) async {
    try {
      await _productsDao.updateQuantity(id, quantity);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    try {
      final results = await _productsDao.getAllProducts();
      return Right(results.map(_mapToEntity).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Product _mapToEntity(ProductWithCategory data) {
    return Product(
      id: data.product.id,
      name: data.product.name,
      description: data.product.description,
      quantity: data.product.quantity,
      price: data.product.price,
      categoryId: data.product.categoryId,
      categoryName: data.category?.name,
      thumbnailPath: data.product.thumbnailPath,
      lowStockThreshold: data.product.lowStockThreshold,
      createdAt: data.product.createdAt,
      updatedAt: data.product.updatedAt,
      barcode: data.product.barcode,
      sku: data.product.sku,
      isActive: data.product.isActive,
      images: data.images
          .map((img) => ProductImage(
                id: img.id,
                productId: img.productId,
                imagePath: img.imagePath,
                thumbnailPath: img.thumbnailPath,
                sortOrder: img.sortOrder,
                createdAt: img.createdAt,
              ))
          .toList(),
    );
  }
}
