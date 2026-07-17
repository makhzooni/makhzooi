import 'package:equatable/equatable.dart';

class LinkedDevice extends Equatable {
  final String id;
  final String deviceName;
  final String token;
  final String? ipAddress;
  final int? port;
  final DateTime linkedAt;
  final DateTime? lastSyncAt;
  final bool isActive;

  const LinkedDevice({
    required this.id,
    required this.deviceName,
    required this.token,
    this.ipAddress,
    this.port,
    required this.linkedAt,
    this.lastSyncAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, deviceName, token];
}
