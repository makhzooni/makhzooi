import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/tables/linked_devices_table.dart';
import 'package:drift/drift.dart' hide Column;

class DeviceLinkingScreen extends ConsumerStatefulWidget {
  const DeviceLinkingScreen({super.key});

  @override
  ConsumerState<DeviceLinkingScreen> createState() =>
      _DeviceLinkingScreenState();
}

class _DeviceLinkingScreenState extends ConsumerState<DeviceLinkingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _deviceId;
  String? _token;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrCreateDeviceId();
  }

  Future<void> _loadOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    String? token = prefs.getString('device_token');

    if (id == null) {
      const uuid = Uuid();
      id = uuid.v4();
      token = uuid.v4();
      await prefs.setString('device_id', id);
      await prefs.setString('device_token', token!);
    }

    setState(() {
      _deviceId = id;
      _token = token;
    });
  }

  String get _qrData {
    if (_deviceId == null) return '';
    return jsonEncode({
      'type': 'INVENTORY_DEVICE',
      'device_id': _deviceId,
      'token': _token,
      'app': 'مخزوني',
    });
  }

  Future<void> _onQRDetected(String rawValue) async {
    if (_scanning) return;
    setState(() => _scanning = true);

    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      if (data['type'] != 'INVENTORY_DEVICE') {
        _showError('رمز QR غير صالح');
        return;
      }

      final deviceId = data['device_id'] as String;
      final token = data['token'] as String;

      await appDatabase.devicesDao.insertDevice(
        LinkedDevicesTableCompanion.insert(
          id: deviceId,
          deviceName: 'جهاز مرتبط',
          token: token,
          linkedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الجهاز بنجاح! ✅',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      _showError('خطأ في قراءة الرمز');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط الأجهزة'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'رمزي'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'مسح'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- رمز QR الخاص بهذا الجهاز ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'رمز QR جهازك',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'اجعل الجهاز الآخر يمسح هذا الرمز لربطه',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_deviceId != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 220,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ).animate().scale(curve: Curves.elasticOut)
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 24),
                if (_deviceId != null) ...[
                  _InfoChip(label: 'معرف الجهاز', value: _deviceId!),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _deviceId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ المعرف',
                                  style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('نسخ المعرف',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'كيفية الربط:',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _StepTile(number: '١', text: 'افتح التطبيق على الجهاز الآخر'),
                _StepTile(
                    number: '٢', text: 'اذهب إلى الإعدادات ← ربط الأجهزة'),
                _StepTile(number: '٣', text: 'اضغط على تبويب "مسح"'),
                _StepTile(
                    number: '٤', text: 'امسح الرمز الظاهر أعلاه'),
                _StepTile(number: '٥', text: 'ستتم المزامنة تلقائياً ✅'),
              ],
            ),
          ),

          // --- مسح رمز QR ---
          Column(
            children: [
              Container(
                height: 300,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.primary, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        _onQRDetected(barcode!.rawValue!);
                      }
                    },
                  ),
                ),
              ),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('جارٍ معالجة الرمز...',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'وجّه الكاميرا نحو رمز QR الجهاز الآخر',
                    style: TextStyle(
                        fontFamily: 'Cairo', color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
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
    _tabController.dispose();
    super.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String text;
  const _StepTile({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
