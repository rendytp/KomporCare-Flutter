import 'package:flutter/material.dart';

/// 140000 -> "Rp140.000"
String rupiah(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "Hari ini, 18 Okt • 10:00–11:00"
String jadwalLabel(DateTime start, int? durationMin) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(start.year, start.month, start.day);
  final diff = day.difference(today).inDays;

  final date = '${start.day} ${_bulan[start.month - 1]}';
  final head = diff == 0
      ? 'Hari ini, $date'
      : diff == 1
          ? 'Besok, $date'
          : date;

  final from = '${_two(start.hour)}:${_two(start.minute)}';
  if (durationMin == null) return '$head • $from';
  final end = start.add(Duration(minutes: durationMin));
  return '$head • $from–${_two(end.hour)}:${_two(end.minute)}';
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'waiting_payment':
      return 'Menunggu pembayaran';
    case 'pending':
      return 'Menunggu teknisi';
    case 'accepted':
      return 'Terjadwal';
    case 'on_the_way':
      return 'Dalam perjalanan';
    case 'in_progress':
      return 'Sedang dikerjakan';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

String paymentLabel(String? type, String? name) {
  if (type == 'cash') return 'Tunai ke teknisi';
  return name ?? '-';
}

/// Tabel `services` tidak punya kolom ikon, jadi dipilih dari kata kunci nama layanan.
IconData serviceIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('burner')) return Icons.local_fire_department_outlined;
  if (n.contains('pemantik') || n.contains('igniter')) return Icons.bolt_outlined;
  if (n.contains('selang') || n.contains('regulator')) return Icons.plumbing_outlined;
  if (n.contains('kebocoran')) return Icons.warning_amber_outlined;
  if (n.contains('tanam')) return Icons.kitchen_outlined;
  if (n.contains('pembersih')) return Icons.cleaning_services_outlined;
  return Icons.build_outlined;
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// 9 -> "09"
String two(int n) => n.toString().padLeft(2, '0');

/// "10:00"
String jamLabel(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "Jumat, 16 Okt 2026"
String tanggalLengkap(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// "Sabtu, 19 Sep 2026" -> dipakai juga pada pemisah tanggal chat.
String tanggalChat(DateTime d) => tanggalLengkap(d);

/// Waktu singkat untuk daftar percakapan: "08:31", "Kemarin", atau "12 Okt".
String waktuSingkat(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return jamLabel(d);
  if (diff == 1) return 'Kemarin';
  return '${d.day} ${_bulan[d.month - 1]}';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Sari Wijaya" -> "SW"
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String paymentStatusLabel(String? status) {
  switch (status) {
    case 'paid':
      return 'Lunas';
    case 'pending':
      return 'Belum dibayar';
    case 'expired':
      return 'Kedaluwarsa';
    case 'failed':
      return 'Gagal';
    case 'refunded':
      return 'Dana dikembalikan';
    default:
      return '-';
  }
}
