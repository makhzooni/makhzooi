import 'dart:io';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImageWidget({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(theme);
    }

    final file = File(imagePath!);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
            );
          }
          return _buildPlaceholder(theme);
        },
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.primary.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: (height ?? 60) * 0.4,
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}
