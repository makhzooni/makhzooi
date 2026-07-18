import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../../domain/entities/product.dart';

class ExportService {
  /// تصدير المنتجات إلى Excel
  static Future<String?> exportToExcel(List<Product> products) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = 'المنتجات';
      final sheet = excel[sheetName];

      // --- ترويسة الجدول ---
      final headers = [
        'اسم المنتج',
        'الوصف',
        'الكمية',
        'السعر',
        'التصنيف',
        'حد التنبيه',
        'تاريخ الإنشاء',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          fontSize: 12,
        );
      }

      // --- بيانات المنتجات ---
      final dateFormat = DateFormat('yyyy/MM/dd');
      for (int rowIndex = 0; rowIndex < products.length; rowIndex++) {
        final product = products[rowIndex];
        final row = rowIndex + 1;

        final bgColor = row % 2 == 0
            ? ExcelColor.fromHexString('#F5F7FA')
            : ExcelColor.fromHexString('#FFFFFF');

        final rowData = [
          product.name,
          product.description ?? '',
          product.quantity.toString(),
          product.price.toStringAsFixed(2),
          product.categoryName ?? 'غير مصنف',
          product.lowStockThreshold.toString(),
          dateFormat.format(product.createdAt),
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: row),
          );
          cell.value = TextCellValue(rowData[colIndex]);
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Right,
            backgroundColorHex: bgColor,
          );
        }
      }

      // --- ضبط عرض الأعمدة ---
      sheet.setColumnWidth(0, 30);
      sheet.setColumnWidth(1, 40);
      sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 20);
      sheet.setColumnWidth(5, 15);
      sheet.setColumnWidth(6, 20);

      // --- حفظ الملف ---
      Directory? dir;
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'inventory_$timestamp.xlsx';
      final filePath = p.join(dir.path, filename);

      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      await File(filePath).writeAsBytes(fileBytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }
}
