import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.productCount = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  List<Object?> get props => [id, name, color];
}
