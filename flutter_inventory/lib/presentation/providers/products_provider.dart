import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/injection.dart';
import '../../data/database/daos/products_dao.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

// Provider لـ DAO
final productsDaoProvider = Provider<ProductsDao>((ref) {
  return appDatabase.productsDao;
});

// Provider للـ Repository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dao = ref.watch(productsDaoProvider);
  return ProductRepositoryImpl(dao);
});

// Stream لجميع المنتجات
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllProducts();
});

// Stream للمنتجات منخفضة المخزون
final lowStockProductsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchLowStockProducts();
});

// Provider للبحث
final searchQueryProvider = StateProvider<String>((ref) => '');

// نتائج البحث
final searchResultsProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.searchProducts(query);
  return result.fold((_) => [], (products) => products);
});

// منتج واحد
final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getProductById(id);
  return result.fold((_) => null, (product) => product);
});

// فلتر التصنيف
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

// المنتجات المفلترة
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsStreamProvider);
  final category = ref.watch(selectedCategoryFilterProvider);

  return products.when(
    data: (list) {
      if (category == null) return AsyncValue.data(list);
      return AsyncValue.data(
          list.where((p) => p.categoryId == category).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
