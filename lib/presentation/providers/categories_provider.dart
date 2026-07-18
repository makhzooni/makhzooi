import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection.dart';
import '../../data/database/daos/categories_dao.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return appDatabase.categoriesDao;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return CategoryRepositoryImpl(dao);
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
});

final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getAllCategories();
  return result.fold((_) => [], (cats) => cats);
});
