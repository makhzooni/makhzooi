import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/export_service.dart';
import '../../providers/products_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final isDark = themeNotifier.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          // --- المظهر ---
          _SectionHeader(title: 'المظهر'),
          SwitchListTile(
            title: const Text('الوضع الليلي',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            subtitle: const Text('تبديل بين الفاتح والداكن',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),

          // --- البيانات ---
          _SectionHeader(title: 'البيانات'),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined, color: Colors.green),
            title: const Text('تصدير إلى Excel',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            subtitle: const Text('تصدير جميع المنتجات',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _exportExcel(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: Colors.blue),
            title: const Text('نسخ احتياطي',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            subtitle: const Text('حفظ نسخة من قاعدة البيانات',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showComingSoon(context, 'النسخ الاحتياطي'),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined, color: Colors.orange),
            title: const Text('استعادة البيانات',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            subtitle: const Text('استعادة من نسخة احتياطية',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showComingSoon(context, 'الاستعادة'),
          ),
          const Divider(),

          // --- الأجهزة ---
          _SectionHeader(title: 'الأجهزة'),
          ListTile(
            leading:
                const Icon(Icons.device_hub_outlined, color: Colors.purple),
            title: const Text('ربط الأجهزة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            subtitle: const Text('مزامنة البيانات مع أجهزة أخرى',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(AppRoutes.deviceLinking),
          ),
          const Divider(),

          // --- عن التطبيق ---
          _SectionHeader(title: 'عن التطبيق'),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('الإصدار',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            trailing: Text(AppConstants.appVersion,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF1565C0)),
            title: const Text(AppConstants.appName,
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            subtitle: const Text('نظام إدارة المخزون',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getAllProducts();

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message,
            style: const TextStyle(fontFamily: 'Cairo'))),
      ),
      (products) async {
        final path = await ExportService.exportToExcel(products);
        if (path != null && context.mounted) {
          await Share.shareXFiles([XFile(path)], text: 'ملف المخزون');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تصدير البيانات بنجاح',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - قريباً',
            style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
