import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAllCategories();
  Future<Either<Failure, List<Category>>> getAllCategories();
  Future<Either<Failure, Category>> getCategoryById(String id);
  Future<Either<Failure, String>> saveCategory(Category category, {bool isNew = true});
  Future<Either<Failure, void>> deleteCategory(String id);
}
