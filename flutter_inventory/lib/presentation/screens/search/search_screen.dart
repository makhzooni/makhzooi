import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/image_service.dart';
import '../../../domain/entities/product.dart';
import '../../providers/products_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_image_widget.dart';

// Debounce provider
final _debouncedQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  File? _selectedImage;
  bool _imageSearching = false;
  List<Product> _imageResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _controller.text == _controller.text) {
        ref.read(_debouncedQueryProvider.notifier).state = _controller.text;
      }
    });
  }

  Future<void> _imageSearch({bool fromCamera = false}) async {
    File? file;
    if (fromCamera) {
      file = await ImageService.captureImageForSearch();
    } else {
      file = await ImageService.pickImageForSearch();
    }
    if (file == null) return;

    setState(() {
      _selectedImage = file;
      _imageSearching = true;
      _imageResults = [];
    });

    try {
      // محاكاة بحث AI بالصورة
      // في التطبيق الحقيقي: ترسل الصورة لـ Google Vision API وتحصل على كلمات مفتاحية
      await Future.delayed(const Duration(seconds: 2));

      // تنفيذ بحث نصي بناءً على نتائج AI
      // هذا مثال - يجب ربطه بـ Google Vision أو أي API مشابه
      final allProductsAsync = ref.read(productsStreamProvider);
      allProductsAsync.whenData((products) {
        // في الواقع: تطابق الكلمات المفتاحية من Vision API مع المنتجات
        setState(() => _imageResults = products.take(5).toList());
      });
    } finally {
      if (mounted) setState(() => _imageSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(_debouncedQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'بحث نصي'),
            Tab(icon: Icon(Icons.image_search), text: 'بحث بالصورة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- بحث نصي ---
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              ref.read(_debouncedQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: query.length < 2
                    ? EmptyState(
                        icon: Icons.search,
                        title: 'اكتب للبحث',
                        subtitle: 'أدخل كلمتين على الأقل للبحث',
                      )
                    : resultsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => EmptyState(
                          icon: Icons.error_outline,
                          title: 'حدث خطأ',
                        ),
                        data: (results) => results.isEmpty
                            ? EmptyState(
                                icon: Icons.search_off,
                                title: 'لا توجد نتائج',
                                subtitle: 'جرب كلمات بحث أخرى',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, i) => _SearchResultTile(
                                  product: results[i],
                                ).animate().fadeIn(delay: (i * 40).ms),
                              ),
                      ),
              ),
            ],
          ),

          // --- بحث بالصورة ---
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // منطقة الصورة
                    GestureDetector(
                      onTap: () => _imageSearch(),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.primary.withOpacity(0.05),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_selectedImage!,
                                    fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'اضغط لاختيار صورة للبحث',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _imageSearch(),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('من المعرض',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _imageSearch(fromCamera: true),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('من الكاميرا',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_imageSearching)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جارٍ تحليل الصورة...',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                )
              else if (_imageResults.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'نتائج مشابهة (${_imageResults.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _imageResults.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _SearchResultTile(
                            product: _imageResults[i],
                          ).animate().fadeIn(delay: (i * 50).ms),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_selectedImage != null && !_imageSearching)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.image_search,
                    title: 'لا توجد منتجات مشابهة',
                    subtitle: 'جرب صورة أخرى',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class _SearchResultTile extends StatelessWidget {
  final Product product;
  const _SearchResultTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => context.push('/product/${product.id}'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ProductImageWidget(
            imagePath: product.thumbnailPath,
            width: 56,
            height: 56,
          ),
        ),
        title: Text(product.name,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.categoryName != null)
              Text(product.categoryName!,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: theme.colorScheme.primary)),
            Text('الكمية: ${product.quantity}',
                style:
                    const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
          ],
        ),
        trailing: Text(
          '${product.price.toStringAsFixed(0)} ر.س',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
