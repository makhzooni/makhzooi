import '../services/notification_service.dart';
import '../../data/database/app_database.dart';

// Singleton لقاعدة البيانات
late AppDatabase appDatabase;

Future<void> initializeDependencies() async {
  // تهيئة قاعدة البيانات
  appDatabase = AppDatabase();

  // تهيئة الإشعارات
  await NotificationService.initialize();
}
