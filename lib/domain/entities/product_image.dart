import 'package:equatable/equatable.dart';

class ProductImage extends Equatable {
  final int? id;
  final String productId;
  final String imagePath;
  final String? thumbnailPath;
  final int sortOrder;
  final DateTime createdAt;

  const ProductImage({
    this.id,
    required this.productId,
    required this.imagePath,
    this.thumbnailPath,
    required this.sortOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, productId, imagePath];
}
