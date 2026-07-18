import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/product_image.dart';

abstract class ImageRepository {
  Future<Either<Failure, List<ProductImage>>> getImagesByProduct(String productId);
  Future<Either<Failure, ProductImage>> addImage(ProductImage image);
  Future<Either<Failure, void>> deleteImage(int imageId);
  Future<Either<Failure, void>> deleteAllProductImages(String productId);
  Future<Either<Failure, void>> reorderImages(List<int> imageIds);
}
