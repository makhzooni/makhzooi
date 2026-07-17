import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/image_service.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_image.dart';
import '../../providers/products_provider.dart';
import '../../providers/categories_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/images_table.dart';
import '../../../core/di/injection.dart';
import 'package:drift/drift.dart' hide Column;

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  final _skuController = TextEditingController();

  String? _selectedCategoryId;
  List<String> _imagePaths = [];
  bool _isLoading = false;
  bool _isEdit = false;
  Product? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEdit = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getProductById(widget.productId!);
    result.fold((_) {}, (product) {
      _existingProduct = product;
      _nameController.text = product.name;
      _descController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _qtyController.text = product.quantity.toString();
      _thresholdController.text = product.lowStockThreshold.toString();
      _skuController.text = product.sku ?? '';
      _selectedCategoryId = product.categoryId;
      _imagePaths = product.images.map((i) => i.imagePath).toList();
      setState(() {});
    });
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    String? path;
    if (choice == 'camera') {
      path = await ImageService.pickFromCamera();
    } else if (choice == 'gallery') {
      path = await ImageService.pickFromGallery();
    }

    if (path != null) {
      setState(() => _imagePaths.add(path!));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final id = _isEdit ? widget.productId! : uuid.v4();

      // توليد صورة مصغرة للصورة الأولى
      String? thumbnailPath;
      if (_imagePaths.isNotEmpty) {
        thumbnailPath = await ImageService.generateThumbnail(_imagePaths.first);
      }

      final product = Product(
        id: id,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        quantity: int.tryParse(_qtyController.text) ?? 0,
        price: double.tryParse(_priceController.text) ?? 0,
        categoryId: _selectedCategoryId,
        thumbnailPath: thumbnailPath ?? _existingProduct?.thumbnailPath,
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        createdAt: _existingProduct?.createdAt ?? now,
        updatedAt: now,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: true,
      );

      final repo = ref.read(productRepositoryProvider);
      await repo.saveProduct(product, isNew: !_isEdit);

      // حفظ الصور في قاعدة البيانات
      if (!_isEdit) {
        for (int i = 0; i < _imagePaths.length; i++) {
          final thumb = await ImageService.generateThumbnail(_imagePaths[i]);
          await appDatabase.imagesDao.insertImage(
            ImagesTableCompanion.insert(
              productId: id,
              imagePath: _imagePaths[i],
              thumbnailPath: Value(thumb),
              sortOrder: Value(i),
              createdAt: now,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- صور المنتج ---
            _SectionTitle(title: 'صور المنتج'),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // زر إضافة صورة
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsetsDirectional.only(end: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.primary.withOpacity(0.05),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: theme.colorScheme.primary, size: 30),
                          const SizedBox(height: 4),
                          Text('إضافة صورة',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  // الصور المضافة
                  ..._imagePaths.asMap().entries.map((entry) {
                    final i = entry.key;
                    final path = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsetsDirectional.only(end: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imagePaths.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- البيانات الأساسية ---
            _SectionTitle(title: 'البيانات الأساسية'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج *',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'اسم المنتج مطلوب' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            // --- التصنيف ---
            categoriesAsync.when(
              data: (cats) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('بدون تصنيف',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  ...cats.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name,
                            style: const TextStyle(fontFamily: 'Cairo')),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // --- السعر والكمية ---
            _SectionTitle(title: 'السعر والمخزون'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      suffixText: 'ر.س',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (int.tryParse(v ?? '') == null) ? 'رقم غير صالح' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _thresholdController,
              decoration: const InputDecoration(
                labelText: 'حد تنبيه نقص الكمية',
                prefixIcon: Icon(Icons.notifications_active_outlined),
                helperText: 'سيصلك إشعار عند الوصول لهذا الرقم',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // --- بيانات إضافية ---
            _SectionTitle(title: 'بيانات إضافية (اختياري)'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'رقم المنتج (SKU)',
                prefixIcon: Icon(Icons.qr_code_outlined),
              ),
            ),

            const SizedBox(height: 32),

            // --- زر الحفظ ---
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading
                      ? 'جارٍ الحفظ...'
                      : (_isEdit ? 'حفظ التعديلات' : 'إضافة المنتج'),
                  style: const TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _thresholdController.dispose();
    _skuController.dispose();
    super.dispose();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
