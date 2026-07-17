import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// التقاط صورة من الكاميرا
  static Future<String?> pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return null;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (photo == null) return null;
    return await _saveAndCompressImage(photo.path);
  }

  /// اختيار صورة من المعرض
  static Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (image == null) return null;
    return await _saveAndCompressImage(image.path);
  }

  /// اختيار صورة لبحث AI (بدون ضغط)
  static Future<File?> pickImageForSearch() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// التقاط صورة للبحث AI من الكاميرا
  static Future<File?> captureImageForSearch() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return null;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  /// حفظ وضغط الصورة
  static Future<String?> _saveAndCompressImage(String sourcePath) async {
    try {
      final dir = await _getImagesDirectory();
      final filename = '${_uuid.v4()}.jpg';
      final destPath = p.join(dir.path, filename);

      final bytes = await File(sourcePath).readAsBytes();
      final compressed = await compute(_compressImage, {
        'bytes': bytes,
        'maxWidth': AppConstants.maxImageWidth,
        'maxHeight': AppConstants.maxImageHeight,
        'quality': AppConstants.imageQuality,
      });

      await File(destPath).writeAsBytes(compressed);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  /// توليد صورة مصغرة
  static Future<String?> generateThumbnail(String imagePath) async {
    try {
      final dir = await _getThumbnailsDirectory();
      final filename = 'thumb_${p.basename(imagePath)}';
      final thumbPath = p.join(dir.path, filename);

      final bytes = await File(imagePath).readAsBytes();
      final thumbnail = await compute(_generateThumbnailBytes, {
        'bytes': bytes,
        'size': AppConstants.thumbnailSize,
        'quality': AppConstants.thumbnailQuality,
      });

      await File(thumbPath).writeAsBytes(thumbnail);
      return thumbPath;
    } catch (e) {
      return null;
    }
  }

  /// حذف صورة من التخزين
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// ضغط الصورة (في خيط منفصل)
  static Uint8List _compressImage(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final maxWidth = params['maxWidth'] as int;
    final maxHeight = params['maxHeight'] as int;
    final quality = params['quality'] as int;

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    if (image.width > maxWidth || image.height > maxHeight) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? maxWidth : null,
        height: image.height >= image.width ? maxHeight : null,
        maintainAspect: true,
      );
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// توليد الصورة المصغرة (في خيط منفصل)
  static Uint8List _generateThumbnailBytes(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final size = params['size'] as int;
    final quality = params['quality'] as int;

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final thumbnail = img.copyResizeCropSquare(image, size: size);
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
  }

  static Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, AppConstants.imagesFolder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> _getThumbnailsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, AppConstants.thumbnailsFolder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
