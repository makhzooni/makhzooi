import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/product.dart';
import '../../providers/products_provider.dart';
import '../../widgets/product_image_widget.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final theme = Theme.of(context);

    return Scaffold(
      body: productAsync.when(
        loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('خطأ')),
          body: Center(child: Text(e.toString())),
        ),
        data: (product) {
          if (product == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('المنتج غير موجود')),
            );
          }
          return _buildDetail(context, ref, product, theme);
        },
      ),
    );
  }

  Widget _buildDetail(
      BuildContext context, WidgetRef ref, Product product, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // شريط التطبيق مع الصورة
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: product.images.isNotEmpty
                ? PageView.builder(
                    itemCount: product.images.length,
                    itemBuilder: (ctx, i) => ProductImageWidget(
                      imagePath: product.images[i].imagePath,
                      fit: BoxFit.cover,
                    ),
                  )
                : ProductImageWidget(
                    imagePath: product.thumbnailPath,
                    fit: BoxFit.cover,
                  ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/product/edit/$productId'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // اسم المنتج والحالة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (product.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.isOutOfStock
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      child: Text(
                        product.isOutOfStock ? 'نفد المخزون' : 'مخزون منخفض',
                        style: TextStyle(
                          color: product.isOutOfStock
                              ? Colors.red
                              : Colors.orange,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ).animate().fadeIn(),

              if (product.categoryName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        product.categoryName!,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // بطاقات الإحصائيات
              Row(
                children: [
                  _StatCard(
                    label: 'السعر',
                    value: '${product.price.toStringAsFixed(2)} ر.س',
                    icon: Icons.monetization_on_outlined,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'الكمية',
                    value: '${product.quantity}',
                    icon: Icons.inventory_2_outlined,
                    color: product.isLowStock ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'حد التنبيه',
                    value: '${product.lowStockThreshold}',
                    icon: Icons.notifications_outlined,
                    color: Colors.orange,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // تعديل الكمية
              _QuantityEditor(product: product, ref: ref),

              const SizedBox(height: 20),

              // الوصف
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                Text('الوصف',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    product.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // بيانات إضافية
              if (product.sku != null || product.barcode != null)
                _InfoSection(product: product),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final repo = ref.read(productRepositoryProvider);
      await repo.deleteProduct(productId);
      if (context.mounted) context.pop();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                )),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _QuantityEditor extends StatefulWidget {
  final Product product;
  final WidgetRef ref;
  const _QuantityEditor({required this.product, required this.ref});

  @override
  State<_QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<_QuantityEditor> {
  late int _qty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.product.quantity;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = widget.ref.read(productRepositoryProvider);
    await repo.updateQuantity(widget.product.id, _qty);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الكمية', style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تعديل الكمية',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _qty > 0 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '$_qty',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 16),
              _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      onPressed: _qty != widget.product.quantity ? _save : null,
                      child: const Text('حفظ',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Product product;
  const _InfoSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('معلومات إضافية',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (product.sku != null)
                _InfoRow(label: 'رقم المنتج (SKU)', value: product.sku!),
              if (product.barcode != null)
                _InfoRow(label: 'الباركود', value: product.barcode!),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey.shade600,
                  fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
