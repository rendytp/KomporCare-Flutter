import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/alur_servis.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'chat_page.dart';
import 'pembayaran_page.dart';
import 'ulasan_page.dart';

/// "Kunjungan Anda": status, peta posisi teknisi, ETA, dan linimasa pesanan.
class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.orderCode});

  final String orderCode;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  TrackingData? _data;
  String? _error;
  Timer? _poll;
  bool _busy = false;
  bool _announcedPay = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final d = await PelangganApi.instance.tracking(widget.orderCode);
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
      });
      if (d.canPay && !_announcedPay && silent) {
        // Servis baru saja ditandai selesai oleh teknisi: buka halaman pembayaran otomatis.
        _announcedPay = true;
        showSnack(context, 'Servis selesai. Silakan lakukan pembayaran.');
        if (ModalRoute.of(context)?.isCurrent ?? false) _pay();
      }
      if (d.status == 'completed' || d.status == 'cancelled') _poll?.cancel();
    } on ApiException catch (e) {
      if (mounted && _data == null) setState(() => _error = e.message);
    }
  }

  Future<void> _chatTechnician() async {
    setState(() => _busy = true);
    try {
      final id = await PelangganApi.instance.openOrderChat(widget.orderCode);
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChatPage(conversationId: id)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _help() async {
    setState(() => _busy = true);
    try {
      final id = await PelangganApi.instance.openSupportChat();
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChatPage(conversationId: id)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PembayaranPage(orderCode: widget.orderCode)));
    if (mounted) _load();
  }

  Future<void> _review() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UlasanPage(orderCode: widget.orderCode)));
    if (mounted) _load();
  }

  Future<void> _rematch() async {
    setState(() => _busy = true);
    try {
      final r = await PelangganApi.instance.rematch(widget.orderCode);
      if (!mounted) return;
      showSnack(context, r.matched ? 'Teknisi ditemukan.' : 'Belum ada teknisi tersedia.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Teknisi akan diberi tahu dan kunjungan dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PelangganApi.instance.cancelOrder(widget.orderCode);
      if (!mounted) return;
      showSnack(context, 'Pesanan dibatalkan.');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Kunjungan Anda',
              subtitle: d == null
                  ? widget.orderCode
                  : '${d.orderCode} • ${tanggalLengkap(d.scheduledAt)}',
            ),
            const RoleBanner('PELANGGAN • Status dan pelacakan teknisi'),
            Expanded(child: _body(d)),
            if (d != null && d.technician != null) _BottomBar(
              busy: _busy,
              onChat: _chatTechnician,
              onHelp: _help,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TrackingData? d) {
    if (d == null) {
      return _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final active = d.status == 'accepted' || d.status == 'on_the_way';

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          _StatusCard(data: d),
          const SizedBox(height: 12),
          if (d.hasDestination) ...[
            _MapCard(data: d),
            const SizedBox(height: 12),
          ],
          if (d.technician != null)
            _TechnicianCard(data: d)
          else if (d.status == 'pending' || d.status == 'waiting_payment')
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Belum ada teknisi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                      'Semua teknisi yang cocok sedang bertugas. Coba cari lagi.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  SmallButton(
                      label: _busy ? 'Mencari...' : 'Cari teknisi lagi',
                      icon: Icons.refresh,
                      onPressed: _busy ? null : _rematch),
                ],
              ),
            ),
          if (d.status == 'in_progress' && !d.finished) ...[
            const SizedBox(height: 12),
            const FormCard(
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Pembayaran Tunai atau QRIS dibuka setelah teknisi menandai servis selesai.',
                        style: TextStyle(fontSize: 11.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          if (d.canPay) ...[
            const SizedBox(height: 12),
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servis selesai',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Total tagihan ${rupiah(d.totalPrice)}. Pilih Tunai atau QRIS.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  PrimaryButton(label: 'Bayar sekarang', icon: Icons.payments_outlined, onPressed: _pay),
                ],
              ),
            ),
          ],
          if (d.status == 'completed') ...[
            const SizedBox(height: 12),
            PrimaryButton(label: 'Beri ulasan', icon: Icons.star_outline, onPressed: _review),
          ],
          const SizedBox(height: 18),
          const Text('Perjalanan pesanan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _Timeline(steps: d.steps),
          const DemoFooter(
              'Posisi teknisi diperbarui otomatis tiap 5 detik. Rute dan waktu tiba bersifat perkiraan dan dapat berubah.'),
          if (active)
            Center(
              child: TextButton(
                onPressed: _cancel,
                child: const Text('Batalkan pesanan',
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data});
  final TrackingData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    late final String headline;
    late final String sub;

    switch (d.status) {
      case 'on_the_way':
        headline = d.etaAt != null ? 'Tiba sekitar ${d.etaAt}' : 'Teknisi dalam perjalanan';
        sub = 'Jadwal servis ${jadwalLabel(d.scheduledAt, d.durationMin)} • Estimasi dari posisi terkini';
      case 'accepted':
        headline = 'Teknisi bersiap berangkat';
        sub = 'Jadwal servis ${jadwalLabel(d.scheduledAt, d.durationMin)}';
      case 'in_progress':
        headline = d.finished ? 'Servis selesai' : 'Servis sedang dikerjakan';
        sub = d.finished
            ? 'Silakan lakukan pembayaran untuk menyelesaikan pesanan.'
            : 'Teknisi sedang mengecek dan memperbaiki kompor Anda.';
      case 'completed':
        headline = 'Pesanan selesai';
        sub = 'Terima kasih telah memakai KomporCare.';
      case 'cancelled':
        headline = 'Pesanan dibatalkan';
        sub = 'Anda dapat memesan layanan lagi kapan saja.';
      default:
        headline = 'Mencari teknisi';
        sub = 'Sistem sedang mencari teknisi terbaik untuk Anda.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderStatusPill(d.status),
          const SizedBox(height: 8),
          Text(headline,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.green)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11.5, height: 1.4)),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.data});
  final TrackingData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final home = LatLng(d.destLat!, d.destLng!);
    final t = d.technician;
    final tech = (t != null && t.hasLocation) ? LatLng(t.lat!, t.lng!) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            FlutterMap(
              // Dibangun ulang saat teknisi bergerak supaya kamera menyesuaikan.
              key: ValueKey('${tech?.latitude},${tech?.longitude}'),
              options: MapOptions(
                initialCenter: home,
                initialZoom: 15,
                initialCameraFit: tech == null
                    ? null
                    : CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints([home, tech]),
                        padding: const EdgeInsets.all(40),
                        maxZoom: 17,
                      ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.komporcare',
                ),
                if (tech != null)
                  PolylineLayer(polylines: [
                    Polyline(points: [tech, home], strokeWidth: 4, color: AppColors.green),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    point: home,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.home, size: 20, color: Colors.white),
                    ),
                  ),
                  if (tech != null)
                    Marker(
                      point: tech,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.green, width: 2),
                        ),
                        child: const Icon(Icons.two_wheeler, size: 20, color: AppColors.green),
                      ),
                    ),
                ]),
              ],
            ),
            if (d.distanceKm != null)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                  ),
                  child: Text(
                      'Jarak ${d.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km${d.etaMinutes != null ? ' • ±${d.etaMinutes} menit' : ''}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ),
            if (tech == null)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Posisi teknisi belum tersedia',
                      style: TextStyle(fontSize: 10.5)),
                ),
              ),
            const Positioned(
              right: 6,
              bottom: 4,
              child: Text('© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 8.5, color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.data});
  final TrackingData data;

  @override
  Widget build(BuildContext context) {
    final t = data.technician!;
    final km = data.distanceKm;
    final line1 = (km != null && data.etaMinutes != null)
        ? '${km.toStringAsFixed(1).replaceAll('.', ',')} km • ±${data.etaMinutes} menit'
        : 'Teknisi KomporCare';

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Initials(t.name, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(line1,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.green),
                  const SizedBox(width: 3),
                  Text(t.totalJobs > 0 ? t.ratingAvg.toStringAsFixed(1) : 'Baru',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Menuju: ${data.address}',
                    style: const TextStyle(fontSize: 11.5, height: 1.3)),
              ),
            ],
          ),
          if (t.experienceYear > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('${t.experienceYear} tahun pengalaman • ${t.totalJobs} pekerjaan',
                    style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 26,
                    child: Column(
                      children: [
                        _dot(steps[i]),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: steps[i].done && (steps[i + 1].done || steps[i + 1].failed)
                                  ? (steps[i + 1].failed ? AppColors.error : AppColors.green)
                                  : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].title,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: steps[i].failed
                                      ? AppColors.error
                                      : (steps[i].done || steps[i].current)
                                          ? AppColors.text
                                          : AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(steps[i].note,
                              style: const TextStyle(
                                  fontSize: 11, height: 1.3, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  Text(steps[i].time ?? '',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(TimelineStep s) {
    if (s.failed) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: s.done ? AppColors.green : AppColors.surface,
        border: Border.all(
            color: s.done || s.current ? AppColors.green : AppColors.border, width: 2),
      ),
      child: s.done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.busy, required this.onChat, required this.onHelp});

  final bool busy;
  final VoidCallback onChat;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SmallButton(
                  label: 'Chat teknisi',
                  icon: Icons.chat_bubble_outline,
                  onPressed: busy ? null : onChat),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SmallButton(
                  label: 'Bantuan',
                  icon: Icons.headset_mic_outlined,
                  filled: false,
                  onPressed: busy ? null : onHelp),
            ),
          ],
        ),
      );
}
