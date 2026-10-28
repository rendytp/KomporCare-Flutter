import 'layanan.dart' show asDouble, asInt;

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.orderCode,
    this.lastMessage,
    this.lastAt,
    required this.unread,
  });

  final int id;
  final String type; // technician | support
  final String title;
  final String subtitle;
  final String? orderCode;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  bool get isSupport => type == 'support';

  factory ConversationSummary.fromJson(Map<String, dynamic> j) => ConversationSummary(
        id: asInt(j['conversation_id']),
        type: j['type'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] as String?) ?? '',
        orderCode: j['order_code'] as String?,
        lastMessage: j['last_message'] as String?,
        lastAt: j['last_at'] == null ? null : DateTime.parse(j['last_at'] as String),
        unread: asInt(j['unread']),
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String senderRole; // customer | technician | support | system
  final String body;
  final DateTime createdAt;

  bool get mine => senderRole == 'customer';

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: asInt(j['message_id']),
        senderRole: j['sender_role'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ChatOrderInfo {
  ChatOrderInfo({
    required this.orderCode,
    required this.status,
    required this.scheduledAt,
    required this.serviceName,
    this.durationMin,
    required this.totalPrice,
  });

  final String orderCode;
  final String status;
  final DateTime scheduledAt;
  final String serviceName;
  final int? durationMin;
  final double totalPrice;

  factory ChatOrderInfo.fromJson(Map<String, dynamic> j) => ChatOrderInfo(
        orderCode: j['order_code'] as String,
        status: j['status'] as String,
        scheduledAt: DateTime.parse(j['scheduled_at'] as String),
        serviceName: j['service_name'] as String,
        durationMin: j['est_duration_min'] == null ? null : asInt(j['est_duration_min']),
        totalPrice: asDouble(j['total_price']),
      );
}

class ConversationDetail {
  ConversationDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.phone,
    this.order,
    required this.messages,
  });

  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String? phone;
  final ChatOrderInfo? order;
  final List<ChatMessage> messages;

  bool get isSupport => type == 'support';

  factory ConversationDetail.fromJson(Map<String, dynamic> j) {
    final c = j['conversation'] as Map<String, dynamic>;
    return ConversationDetail(
      id: asInt(c['conversation_id']),
      type: c['type'] as String,
      title: c['title'] as String,
      subtitle: (c['subtitle'] as String?) ?? '',
      phone: c['phone'] as String?,
      order: c['order'] == null
          ? null
          : ChatOrderInfo.fromJson(c['order'] as Map<String, dynamic>),
      messages: ((j['messages'] as List?) ?? [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
