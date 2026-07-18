import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAllProducts();
  Stream<List<Product>> watchLowStockProducts();
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, List<Product>>> searchProducts(String query);
  Future<Either<Failure, List<Product>>> getProductsByCategory(String categoryId);
  Future<Either<Failure, String>> saveProduct(Product product, {bool isNew = true});
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, void>> updateQuantity(String id, int quantity);
  Future<Either<Failure, List<Product>>> getAllProducts();
}
