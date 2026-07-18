import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/categories_dao.dart';
import '../database/tables/categories_table.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoriesDao _categoriesDao;

  CategoryRepositoryImpl(this._categoriesDao);

  @override
  Stream<List<Category>> watchAllCategories() {
    return _categoriesDao.watchAllCategories().map(
          (list) => list.map(_mapToEntity).toList(),
        );
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final results = await _categoriesDao.getAllCategories();
      final categories = <Category>[];
      for (final cat in results) {
        final count = await _categoriesDao.getProductCount(cat.id);
        categories.add(_mapToEntity(cat).copyWith(productCount: count));
      }
      return Right(categories);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final result = await _categoriesDao.getCategoryById(id);
      if (result == null) return Left(DatabaseFailure('التصنيف غير موجود'));
      return Right(_mapToEntity(result));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> saveCategory(Category category,
      {bool isNew = true}) async {
    try {
      final companion = CategoriesTableCompanion(
        id: Value(category.id),
        name: Value(category.name),
        color: Value(category.color),
        icon: Value(category.icon),
        createdAt: Value(category.createdAt),
      );
      if (isNew) {
        await _categoriesDao.insertCategory(companion);
      } else {
        await _categoriesDao.updateCategory(companion);
      }
      return Right(category.id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await _categoriesDao.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Category _mapToEntity(CategoriesTableData data) {
    return Category(
      id: data.id,
      name: data.name,
      color: data.color,
      icon: data.icon,
      createdAt: data.createdAt,
    );
  }
}
