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
      return 'Teknisi berangkat';
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
