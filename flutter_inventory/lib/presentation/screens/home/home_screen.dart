import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/product.dart';
import '../../providers/products_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/empty_state.dart';
import 'widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مخزوني'),
        actions: [
          // تنبيه نقص المخزون
          lowStockAsync.when(
            data: (lowStock) => lowStock.isEmpty
                ? const SizedBox.shrink()
                : badges.Badge(
                    badgeContent: Text(
                      '${lowStock.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontFamily: 'Cairo'),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red),
                    child: IconButton(
                      icon: const Icon(Icons.warning_amber_rounded),
                      onPressed: () => _showLowStockDialog(context, lowStock),
                      tooltip: 'منتجات منخفضة المخزون',
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
            tooltip: 'بحث',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: Column(
        children: [
          // فلتر التصنيفات
          categoriesAsync.when(
            data: (categories) => categories.isEmpty
                ? const SizedBox.shrink()
                : _buildCategoryFilter(context, ref, categories, selectedCategory),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // قائمة المنتجات
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'لا توجد منتجات بعد',
                      subtitle: 'اضغط + لإضافة منتج جديد',
                      actionLabel: 'إضافة منتج',
                      onAction: () => context.push(AppRoutes.addProduct),
                    )
                  : _buildProductGrid(context, products),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'حدث خطأ',
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addProduct),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref,
      categories, String? selected) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selected == null;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                label: const Text('الكل', style: TextStyle(fontFamily: 'Cairo')),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(selectedCategoryFilterProvider.notifier).state = null,
              ),
            );
          }
          final cat = categories[index - 1];
          final isSelected = selected == cat.id;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(cat.name, style: const TextStyle(fontFamily: 'Cairo')),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(selectedCategoryFilterProvider.notifier)
                  .state = isSelected ? null : cat.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index])
              .animate()
              .fadeIn(delay: (index * 50).ms)
              .slideY(begin: 0.1);
        },
      ),
    );
  }

  void _showLowStockDialog(BuildContext context, List<Product> products) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('تنبيه نقص المخزون',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text('${p.quantity}',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                subtitle: Text('الحد الأدنى: ${p.lowStockThreshold}',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey.shade600)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/product/${p.id}');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
