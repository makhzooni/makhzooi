class AppConstants {
  // اسم التطبيق
  static const String appName = 'مخزوني';
  static const String appVersion = '1.0.0';

  // إعدادات قاعدة البيانات
  static const String dbName = 'inventory.db';
  static const int dbVersion = 1;

  // مجلدات التخزين
  static const String imagesFolder = 'inventory_images';
  static const String thumbnailsFolder = 'inventory_thumbnails';
  static const String backupFolder = 'inventory_backups';
  static const String exportsFolder = 'inventory_exports';

  // إعدادات الصور
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int thumbnailSize = 200;
  static const int imageQuality = 80;
  static const int thumbnailQuality = 70;

  // إعدادات البحث
  static const int searchDebounceMs = 500;
  static const int minSearchLength = 2;

  // إعدادات الإشعارات
  static const String notificationChannelId = 'inventory_alerts';
  static const String notificationChannelName = 'تنبيهات المخزون';
  static const String notificationChannelDesc = 'إشعارات نقص المخزون';
  static const int lowStockNotificationId = 1000;

  // حالات فارغة
  static const String emptyProducts = 'لا توجد منتجات بعد\nاضغط + لإضافة منتج جديد';
  static const String emptySearch = 'لا توجد نتائج للبحث';
  static const String emptyCategories = 'لا توجد تصنيفات\nاضغط + لإضافة تصنيف';

  // رسائل الخطأ
  static const String errorGeneral = 'حدث خطأ. يرجى المحاولة مرة أخرى';
  static const String errorDatabase = 'خطأ في قاعدة البيانات';
  static const String errorPermission = 'يرجى منح الصلاحيات اللازمة';
  static const String errorImage = 'فشل تحميل الصورة';

  // رسائل النجاح
  static const String successSave = 'تم الحفظ بنجاح';
  static const String successDelete = 'تم الحذف بنجاح';
  static const String successExport = 'تم تصدير البيانات بنجاح';
  static const String successBackup = 'تم إنشاء النسخة الاحتياطية بنجاح';
  static const String successRestore = 'تم استعادة البيانات بنجاح';

  // QR
  static const String qrPrefix = 'INVENTORY_DEVICE:';

  // المزامنة
  static const int syncTimeoutSeconds = 30;
  static const int syncPort = 8765;

  // ألوان الفئات الافتراضية
  static const List<String> defaultCategoryColors = [
    '#1565C0', '#2E7D32', '#E65100', '#6A1B9A',
    '#00838F', '#AD1457', '#37474F', '#F57F17',
  ];
}

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String productDetail = '/product/:id';
  static const String addProduct = '/product/add';
  static const String editProduct = '/product/edit/:id';
  static const String categories = '/categories';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String deviceLinking = '/device-linking';
  static const String imageSearch = '/image-search';
}
