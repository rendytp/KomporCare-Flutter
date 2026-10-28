import 'layanan.dart' show asDouble, asInt;

class OrderItem {
  OrderItem({required this.name, required this.qty, required this.price, this.durationMin});

  final String name;
  final int qty;
  final double price;
  final int? durationMin;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['name'] as String,
        qty: asInt(j['qty']),
        price: asDouble(j['price']),
        durationMin: j['est_duration_min'] == null ? null : asInt(j['est_duration_min']),
      );
}

class CustomerOrder {
  CustomerOrder({
    required this.orderCode,
    required this.status,
    required this.scheduledAt,
    this.completedAt,
    required this.serviceName,
    required this.extraItems,
    required this.items,
    this.durationMin,
    required this.address,
    required this.addressLabel,
    this.technicianName,
    required this.hasTechnician,
    required this.subtotal,
    required this.transportFee,
    required this.totalPrice,
    this.paymentMethod,
    this.paymentType,
    this.paymentStatus,
    this.cancelReason,
  });

  final String orderCode;
  final String status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String serviceName;
  final int extraItems;
  final List<OrderItem> items;
  final int? durationMin;
  final String address;
  final String addressLabel;
  final String? technicianName;
  final bool hasTechnician;
  final double subtotal;
  final double transportFee;
  final double totalPrice;
  final String? paymentMethod;
  final String? paymentType;
  final String? paymentStatus;
  final String? cancelReason;

  bool get isActive => const [
        'waiting_payment',
        'pending',
        'accepted',
        'on_the_way',
        'in_progress',
      ].contains(status);

  bool get isPaid => paymentStatus == 'paid';

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
        orderCode: j['order_code'] as String,
        status: j['status'] as String,
        scheduledAt: DateTime.parse(j['scheduled_at'] as String),
        completedAt:
            j['completed_at'] == null ? null : DateTime.parse(j['completed_at'] as String),
        serviceName: (j['service_name'] as String?) ?? '-',
        extraItems: asInt(j['extra_items']),
        items: ((j['items'] as List?) ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMin: j['est_duration_min'] == null ? null : asInt(j['est_duration_min']),
        address: (j['address'] as String?) ?? '',
        addressLabel: (j['address_label'] as String?) ?? '',
        technicianName: j['technician_name'] as String?,
        hasTechnician: j['has_technician'] == true,
        subtotal: asDouble(j['subtotal']),
        transportFee: asDouble(j['transport_fee']),
        totalPrice: asDouble(j['total_price']),
        paymentMethod: j['payment_method'] as String?,
        paymentType: j['payment_type'] as String?,
        paymentStatus: j['payment_status'] as String?,
        cancelReason: j['cancel_reason'] as String?,
      );
}

class OrderList {
  OrderList({required this.active, required this.history});

  final List<CustomerOrder> active;
  final List<CustomerOrder> history;

  factory OrderList.fromJson(Map<String, dynamic> j) => OrderList(
        active: ((j['active'] as List?) ?? [])
            .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: ((j['history'] as List?) ?? [])
            .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
