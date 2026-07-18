import 'package:equatable/equatable.dart';
import 'product_image.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final double price;
  final String? categoryId;
  final String? categoryName;
  final String? thumbnailPath;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? barcode;
  final String? sku;
  final bool isActive;
  final List<ProductImage> images;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.thumbnailPath,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.sku,
    this.isActive = true,
    this.images = const [],
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity == 0;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    double? price,
    String? categoryId,
    String? categoryName,
    String? thumbnailPath,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? barcode,
    String? sku,
    bool? isActive,
    List<ProductImage>? images,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [id, name, quantity, price, categoryId, updatedAt];
}
