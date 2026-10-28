int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class ServiceCategory {
  ServiceCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ServiceCategory.fromJson(Map<String, dynamic> j) =>
      ServiceCategory(id: asInt(j['category_id']), name: j['name'] as String);
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    required this.basePrice,
    required this.visitFee,
    this.durationMin,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String? description;
  final double basePrice;
  final double visitFee;
  final int? durationMin;

  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
        id: asInt(j['service_id']),
        categoryId: asInt(j['category_id']),
        categoryName: (j['category_name'] as String?) ?? '',
        name: j['name'] as String,
        description: j['description'] as String?,
        basePrice: asDouble(j['base_price']),
        visitFee: asDouble(j['visit_fee']),
        durationMin: j['est_duration_min'] == null ? null : asInt(j['est_duration_min']),
      );
}

class ServiceCatalog {
  ServiceCatalog({required this.categories, required this.services});

  final List<ServiceCategory> categories;
  final List<ServiceItem> services;

  factory ServiceCatalog.fromJson(Map<String, dynamic> j) => ServiceCatalog(
        categories: (j['categories'] as List)
            .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        services: (j['services'] as List)
            .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AddressInfo {
  AddressInfo({required this.label, required this.fullAddress, required this.city});

  final String label;
  final String fullAddress;
  final String city;

  factory AddressInfo.fromJson(Map<String, dynamic> j) => AddressInfo(
        label: (j['label'] as String?) ?? '',
        fullAddress: (j['full_address'] as String?) ?? '',
        city: (j['city'] as String?) ?? '',
      );
}

class ActiveOrder {
  ActiveOrder({
    required this.orderCode,
    required this.status,
    required this.scheduledAt,
    required this.totalPrice,
    required this.serviceName,
    this.durationMin,
    this.technicianName,
    this.paymentMethod,
    this.paymentType,
    this.paymentStatus,
  });

  final String orderCode;
  final String status;
  final DateTime scheduledAt;
  final double totalPrice;
  final String serviceName;
  final int? durationMin;
  final String? technicianName;
  final String? paymentMethod;
  final String? paymentType;
  final String? paymentStatus;

  factory ActiveOrder.fromJson(Map<String, dynamic> j) => ActiveOrder(
        orderCode: j['order_code'] as String,
        status: j['status'] as String,
        scheduledAt: DateTime.parse(j['scheduled_at'] as String),
        totalPrice: asDouble(j['total_price']),
        serviceName: j['service_name'] as String,
        durationMin: j['est_duration_min'] == null ? null : asInt(j['est_duration_min']),
        technicianName: j['technician_name'] as String?,
        paymentMethod: j['payment_method'] as String?,
        paymentType: j['payment_type'] as String?,
        paymentStatus: j['payment_status'] as String?,
      );
}

class HomeData {
  HomeData({
    this.address,
    required this.services,
    this.activeOrder,
    required this.unread,
  });

  final AddressInfo? address;
  final List<ServiceItem> services;
  final ActiveOrder? activeOrder;
  final int unread;

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
        address: j['address'] == null
            ? null
            : AddressInfo.fromJson(j['address'] as Map<String, dynamic>),
        services: (j['services'] as List)
            .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeOrder: j['active_order'] == null
            ? null
            : ActiveOrder.fromJson(j['active_order'] as Map<String, dynamic>),
        unread: asInt(j['unread_notifications']),
      );
}
