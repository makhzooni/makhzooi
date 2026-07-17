import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'خطأ في قاعدة البيانات'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'تم رفض الصلاحية'])
      : super(message);
}

class ImageFailure extends Failure {
  const ImageFailure([String message = 'خطأ في معالجة الصورة'])
      : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'خطأ في الاتصال بالشبكة'])
      : super(message);
}

class ExportFailure extends Failure {
  const ExportFailure([String message = 'خطأ في تصدير البيانات'])
      : super(message);
}

class SyncFailure extends Failure {
  const SyncFailure([String message = 'خطأ في المزامنة'])
      : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'حدث خطأ غير متوقع'])
      : super(message);
}
