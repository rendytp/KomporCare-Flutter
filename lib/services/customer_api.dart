import '../core/api_client.dart';
import '../models/akun.dart';
import '../models/chat.dart';
import '../models/layanan.dart';
import '../models/pesanan.dart';
import 'auth_service.dart';

class CustomerApi {
  CustomerApi._();
  static final CustomerApi instance = CustomerApi._();

  ApiClient get _api => AuthService.instance.api;

  Future<HomeData> home() async {
    final res = await _api.get('/customer/home');
    return HomeData.fromJson(res);
  }

  Future<ServiceCatalog> services({String? query, int? categoryId}) async {
    final res = await _api.get('/services', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (categoryId != null) 'category_id': '$categoryId',
    });
    return ServiceCatalog.fromJson(res);
  }
}

/// Endpoint halaman Pesanan, Pesan, dan Akun.
class PelangganApi {
  PelangganApi._();
  static final PelangganApi instance = PelangganApi._();

  ApiClient get _api => AuthService.instance.api;

  // ---- Pesanan ----
  Future<OrderList> orders() async => OrderList.fromJson(await _api.get('/customer/orders'));

  // ---- Pesan ----
  Future<List<ConversationSummary>> conversations() async {
    final res = await _api.get('/customer/conversations');
    return ((res['conversations'] as List?) ?? [])
        .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> openSupportChat() async {
    final res = await _api.post('/customer/conversations/support', {});
    return asInt(res['conversation_id']);
  }

  Future<int> openOrderChat(String orderCode) async {
    final res = await _api.post('/customer/orders/$orderCode/chat', {});
    return asInt(res['conversation_id']);
  }

  Future<ConversationDetail> conversation(int id) async =>
      ConversationDetail.fromJson(await _api.get('/customer/conversations/$id'));

  Future<ChatMessage> sendMessage(int id, String body) async {
    final res = await _api.post('/customer/conversations/$id/messages', {'body': body});
    return ChatMessage.fromJson(res['message'] as Map<String, dynamic>);
  }

  // ---- Akun ----
  Future<AppUser> updateProfile({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    final res = await _api.put('/account/profile', {
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
    });
    final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    AuthService.instance.currentUser = user;
    return user;
  }

  Future<String> changePassword({
    required String current,
    required String password,
    required String confirmation,
  }) async {
    final res = await _api.post('/account/password', {
      'current_password': current,
      'password': password,
      'password_confirmation': confirmation,
    });
    return (res['message'] as String?) ?? 'Kata sandi berhasil diubah.';
  }

  Future<List<SavedAddress>> addresses() async {
    final res = await _api.get('/account/addresses');
    return ((res['addresses'] as List?) ?? [])
        .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _addressBody({
    required String label,
    required String recipientName,
    required String recipientPhone,
    required String fullAddress,
    required String city,
    required String postalCode,
    required String note,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      {
        'label': label.trim(),
        'recipient_name': recipientName.trim().isEmpty ? null : recipientName.trim(),
        'recipient_phone': recipientPhone.trim().isEmpty ? null : recipientPhone.trim(),
        'full_address': fullAddress.trim(),
        'city': city.trim(),
        'postal_code': postalCode.trim().isEmpty ? null : postalCode.trim(),
        'note': note.trim().isEmpty ? null : note.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (isDefault != null) 'is_default': isDefault,
      };

  Future<void> addAddress({
    required String label,
    required String recipientName,
    required String recipientPhone,
    required String fullAddress,
    required String city,
    required String postalCode,
    required String note,
    double? latitude,
    double? longitude,
    required bool isDefault,
  }) async {
    await _api.post(
        '/account/addresses',
        _addressBody(
          label: label,
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          fullAddress: fullAddress,
          city: city,
          postalCode: postalCode,
          note: note,
          latitude: latitude,
          longitude: longitude,
          isDefault: isDefault,
        ));
  }

  Future<void> updateAddress(
    int id, {
    required String label,
    required String recipientName,
    required String recipientPhone,
    required String fullAddress,
    required String city,
    required String postalCode,
    required String note,
    double? latitude,
    double? longitude,
  }) async {
    await _api.put(
        '/account/addresses/$id',
        _addressBody(
          label: label,
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          fullAddress: fullAddress,
          city: city,
          postalCode: postalCode,
          note: note,
          latitude: latitude,
          longitude: longitude,
        ));
  }

  Future<void> makeDefaultAddress(int id) async {
    await _api.post('/account/addresses/$id/default', {});
  }

  Future<void> deleteAddress(int id) async {
    await _api.delete('/account/addresses/$id');
  }

  Future<List<AppNotification>> notifications() async {
    final res = await _api.get('/account/notifications');
    return ((res['notifications'] as List?) ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
