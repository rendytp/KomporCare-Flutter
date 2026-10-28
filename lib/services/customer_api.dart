import '../core/api_client.dart';
import '../models/layanan.dart';
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
