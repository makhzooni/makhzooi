import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/product.dart';
import '../../../widgets/product_image_widget.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = product.isLowStock;
    final isOut = product.isOutOfStock;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Stack(
              children: [
                ProductImageWidget(
                  imagePath: product.thumbnailPath ?? product.images.firstOrNull?.thumbnailPath,
                  height: 130,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                ),
                // شارة حالة المخزون
                if (isOut || isLow)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOut ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOut ? 'نفد' : 'منخفض',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // معلومات المنتج
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // التصنيف
                    if (product.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.categoryName!,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Cairo',
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const Spacer(),

                    // السعر والكمية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: isOut
                                  ? Colors.red
                                  : isLow
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: isOut
                                    ? Colors.red
                                    : isLow
                                        ? Colors.orange
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
