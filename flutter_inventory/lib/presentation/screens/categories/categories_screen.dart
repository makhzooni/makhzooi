import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/category.dart';
import '../../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (categories) => categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 70,
                        color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(AppConstants.emptyCategories,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey.shade500)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  return _CategoryTile(category: categories[i])
                      .animate()
                      .fadeIn(delay: (i * 50).ms)
                      .slideX(begin: -0.05);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('تصنيف جديد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref,
      [Category? existing]) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    String selectedColor =
        existing?.color ?? AppConstants.defaultCategoryColors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            existing == null ? 'تصنيف جديد' : 'تعديل التصنيف',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم التصنيف *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('اللون:',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.defaultCategoryColors.map((color) {
                  final c = Color(
                    int.parse(color.replaceFirst('#', '0xFF')),
                  );
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Colors.black54, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final repo = ref.read(categoryRepositoryProvider);
                const uuid = Uuid();
                final category = Category(
                  id: existing?.id ?? uuid.v4(),
                  name: nameController.text.trim(),
                  color: selectedColor,
                  icon: 'category',
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                await repo.saveCategory(category, isNew: existing == null);
                ref.invalidate(categoriesListProvider);
              },
              child: Text(
                existing == null ? 'إضافة' : 'حفظ',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(
        int.parse(category.color.replaceFirst('#', '0xFF')));
    return Card(
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.category_outlined, color: color, size: 24),
        ),
        title: Text(category.name,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        subtitle: Text('${category.productCount} منتج',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.grey.shade600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: color),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف التصنيف',
                        style: TextStyle(fontFamily: 'Cairo')),
                    content: const Text(
                        'هل تريد حذف هذا التصنيف؟ لن تُحذف المنتجات المرتبطة به.',
                        style: TextStyle(fontFamily: 'Cairo')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final repo = ref.read(categoryRepositoryProvider);
                  await repo.deleteCategory(category.id);
                  ref.invalidate(categoriesListProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
