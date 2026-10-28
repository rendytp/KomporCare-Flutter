import 'layanan.dart' show asInt;

class SavedAddress {
  SavedAddress({
    required this.id,
    required this.label,
    this.recipientName,
    this.recipientPhone,
    required this.fullAddress,
    required this.city,
    this.postalCode,
    this.note,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String? recipientName;
  final String? recipientPhone;
  final String fullAddress;
  final String city;
  final String? postalCode;
  final String? note;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasPin => latitude != null && longitude != null;

  /// "Jl. Mistal No. 18, Sukamaju, Depok"
  String get oneLine => [fullAddress, city].where((e) => e.trim().isNotEmpty).join(', ');

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: asInt(j['address_id']),
        label: (j['label'] as String?) ?? '',
        recipientName: j['recipient_name'] as String?,
        recipientPhone: j['recipient_phone'] as String?,
        fullAddress: (j['full_address'] as String?) ?? '',
        city: (j['city'] as String?) ?? '',
        postalCode: j['postal_code'] as String?,
        note: j['note'] as String?,
        latitude: j['latitude'] == null ? null : (j['latitude'] as num).toDouble(),
        longitude: j['longitude'] == null ? null : (j['longitude'] as num).toDouble(),
        isDefault: j['is_default'] == true || j['is_default'] == 1,
      );
}

class AppNotification {
  AppNotification({
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        title: j['title'] as String,
        message: j['message'] as String,
        isRead: j['is_read'] == true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
