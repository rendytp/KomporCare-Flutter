import 'layanan.dart' show asDouble, asInt;

double? _d(dynamic v) => v == null ? null : asDouble(v);
int? _i(dynamic v) => v == null ? null : asInt(v);

/// Teknisi terpilih oleh pencocokan otomatis.
class MatchedTechnician {
  MatchedTechnician({
    required this.name,
    this.phone,
    required this.experienceYear,
    required this.ratingAvg,
    required this.totalJobs,
    this.distanceKm,
    this.etaMinutes,
    required this.score,
  });

  final String name;
  final String? phone;
  final int experienceYear;
  final double ratingAvg;
  final int totalJobs;
  final double? distanceKm;
  final int? etaMinutes;
  final double score;

  factory MatchedTechnician.fromJson(Map<String, dynamic> j) => MatchedTechnician(
        name: j['name'] as String,
        phone: j['phone'] as String?,
        experienceYear: asInt(j['experience_year']),
        ratingAvg: asDouble(j['rating_avg']),
        totalJobs: asInt(j['total_jobs']),
        distanceKm: _d(j['distance_km']),
        etaMinutes: _i(j['eta_minutes']),
        score: asDouble(j['score']),
      );
}

class MatchResult {
  MatchResult({required this.orderCode, required this.matched, this.technician});

  final String orderCode;
  final bool matched;
  final MatchedTechnician? technician;

  factory MatchResult.fromJson(Map<String, dynamic> j) => MatchResult(
        orderCode: j['order_code'] as String,
        matched: j['matched'] == true,
        technician: j['technician'] == null
            ? null
            : MatchedTechnician.fromJson(j['technician'] as Map<String, dynamic>),
      );
}

class TrackingTechnician {
  TrackingTechnician({
    required this.name,
    this.phone,
    required this.ratingAvg,
    required this.experienceYear,
    required this.totalJobs,
    this.lat,
    this.lng,
  });

  final String name;
  final String? phone;
  final double ratingAvg;
  final int experienceYear;
  final int totalJobs;
  final double? lat;
  final double? lng;

  bool get hasLocation => lat != null && lng != null;

  factory TrackingTechnician.fromJson(Map<String, dynamic> j) => TrackingTechnician(
        name: j['name'] as String,
        phone: j['phone'] as String?,
        ratingAvg: asDouble(j['rating_avg']),
        experienceYear: asInt(j['experience_year']),
        totalJobs: asInt(j['total_jobs']),
        lat: _d(j['lat']),
        lng: _d(j['lng']),
      );
}

class TimelineStep {
  TimelineStep({
    required this.key,
    required this.title,
    required this.note,
    this.time,
    required this.done,
    this.current = false,
    this.failed = false,
  });

  final String key;
  final String title;
  final String note;
  final String? time;
  final bool done;

  /// Langkah yang sedang/berikutnya dikerjakan.
  final bool current;

  /// Langkah akhir yang gagal (pesanan dibatalkan).
  final bool failed;

  factory TimelineStep.fromJson(Map<String, dynamic> j) => TimelineStep(
        key: j['key'] as String,
        title: j['title'] as String,
        note: (j['note'] as String?) ?? '',
        time: j['time'] as String?,
        done: j['done'] == true,
        current: j['current'] == true,
        failed: j['failed'] == true,
      );
}

class TrackingData {
  TrackingData({
    required this.orderCode,
    required this.status,
    required this.scheduledAt,
    required this.serviceName,
    this.durationMin,
    required this.totalPrice,
    required this.address,
    this.destLat,
    this.destLng,
    this.technician,
    this.distanceKm,
    this.etaMinutes,
    this.etaAt,
    required this.steps,
    required this.canPay,
    required this.finished,
  });

  final String orderCode;
  final String status;
  final DateTime scheduledAt;
  final String serviceName;
  final int? durationMin;
  final double totalPrice;
  final String address;
  final double? destLat;
  final double? destLng;
  final TrackingTechnician? technician;
  final double? distanceKm;
  final int? etaMinutes;
  final String? etaAt;
  final List<TimelineStep> steps;
  final bool canPay;
  final bool finished;

  bool get hasDestination => destLat != null && destLng != null;

  factory TrackingData.fromJson(Map<String, dynamic> j) {
    final dest = j['destination'] as Map<String, dynamic>?;
    return TrackingData(
      orderCode: j['order_code'] as String,
      status: j['status'] as String,
      scheduledAt: DateTime.parse(j['scheduled_at'] as String),
      serviceName: j['service_name'] as String,
      durationMin: _i(j['est_duration_min']),
      totalPrice: asDouble(j['total_price']),
      address: (j['address'] as String?) ?? '',
      destLat: dest == null ? null : _d(dest['lat']),
      destLng: dest == null ? null : _d(dest['lng']),
      technician: j['technician'] == null
          ? null
          : TrackingTechnician.fromJson(j['technician'] as Map<String, dynamic>),
      distanceKm: _d(j['distance_km']),
      etaMinutes: _i(j['eta_minutes']),
      etaAt: j['eta_at'] as String?,
      steps: ((j['steps'] as List?) ?? [])
          .map((e) => TimelineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      canPay: j['can_pay'] == true,
      finished: j['finished'] == true,
    );
  }
}

class BillLine {
  BillLine({required this.label, required this.amount});
  final String label;
  final double amount;

  factory BillLine.fromJson(Map<String, dynamic> j) =>
      BillLine(label: j['label'] as String, amount: asDouble(j['amount']));
}

class PaymentInfo {
  PaymentInfo({
    required this.orderCode,
    required this.status,
    required this.customerName,
    this.technicianName,
    this.finishedAt,
    required this.lines,
    required this.total,
    this.paymentStatus,
    this.paymentType,
    required this.canPay,
    required this.qrString,
  });

  final String orderCode;
  final String status;
  final String customerName;
  final String? technicianName;
  final DateTime? finishedAt;
  final List<BillLine> lines;
  final double total;
  final String? paymentStatus;
  final String? paymentType;
  final bool canPay;
  final String qrString;

  bool get isPaid => paymentStatus == 'paid';

  factory PaymentInfo.fromJson(Map<String, dynamic> j) => PaymentInfo(
        orderCode: j['order_code'] as String,
        status: j['status'] as String,
        customerName: (j['customer_name'] as String?) ?? '',
        technicianName: j['technician_name'] as String?,
        finishedAt:
            j['finished_at'] == null ? null : DateTime.parse(j['finished_at'] as String),
        lines: ((j['lines'] as List?) ?? [])
            .map((e) => BillLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: asDouble(j['total']),
        paymentStatus: j['payment_status'] as String?,
        paymentType: j['payment_type'] as String?,
        canPay: j['can_pay'] == true,
        qrString: (j['qr_string'] as String?) ?? '',
      );
}

class ReviewInfo {
  ReviewInfo({
    required this.orderCode,
    required this.status,
    required this.serviceName,
    this.completedAt,
    required this.totalPrice,
    this.technicianName,
    required this.availableTags,
    required this.canReview,
    this.rating,
    this.comment,
    this.tags = const [],
  });

  final String orderCode;
  final String status;
  final String serviceName;
  final DateTime? completedAt;
  final double totalPrice;
  final String? technicianName;
  final List<String> availableTags;
  final bool canReview;
  final int? rating;
  final String? comment;
  final List<String> tags;

  factory ReviewInfo.fromJson(Map<String, dynamic> j) {
    final r = j['review'] as Map<String, dynamic>?;
    return ReviewInfo(
      orderCode: j['order_code'] as String,
      status: j['status'] as String,
      serviceName: j['service_name'] as String,
      completedAt:
          j['completed_at'] == null ? null : DateTime.parse(j['completed_at'] as String),
      totalPrice: asDouble(j['total_price']),
      technicianName: j['technician_name'] as String?,
      availableTags: ((j['available_tags'] as List?) ?? []).map((e) => e as String).toList(),
      canReview: j['can_review'] == true,
      rating: r == null ? null : asInt(r['rating']),
      comment: r == null ? null : r['comment'] as String?,
      tags: r == null ? const [] : ((r['tags'] as List?) ?? []).map((e) => e as String).toList(),
    );
  }
}
