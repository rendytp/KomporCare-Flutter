import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/alur_servis.dart';
import '../../models/layanan.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'tracking_page.dart';

enum _Phase { searching, matched, none, error }

/// Layar "Mencari teknisi terdekat..." (radar) lalu hasil pencocokan otomatis.
/// Pesanan dibuat sekali saat layar ini dibuka; "Cari lagi" memakai pesanan yang sama.
class PencarianTeknisiPage extends StatefulWidget {
  const PencarianTeknisiPage({
    super.key,
    required this.service,
    required this.addressId,
    this.scheduledAt,
    this.note,
  });

  final ServiceItem service;
  final int addressId;
  final DateTime? scheduledAt;
  final String? note;

  @override
  State<PencarianTeknisiPage> createState() => _PencarianTeknisiPageState();
}

class _PencarianTeknisiPageState extends State<PencarianTeknisiPage>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Memeriksa teknisi yang menguasai layanan',
    'Menghitung jarak ke lokasi Anda',
    'Menilai pengalaman dan rating',
    'Mengunci teknisi terbaik untuk Anda',
  ];

  late final AnimationController _radar =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  Timer? _ticker;
  int _msg = 0;
  _Phase _phase = _Phase.searching;
  String? _orderCode;
  MatchResult? _result;
  String? _error;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted && _phase == _Phase.searching) {
        setState(() => _msg = (_msg + 1) % _messages.length);
      }
    });
    _run();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _radar.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.searching;
      _error = null;
    });
    try {
      // Animasi minimal 3 detik supaya terasa seperti proses pencarian.
      final minWait = Future<void>.delayed(const Duration(seconds: 3));
      final api = PelangganApi.instance;
      final Future<MatchResult> call = _orderCode == null
          ? api.createOrder(
              serviceId: widget.service.id,
              addressId: widget.addressId,
              scheduledAt: widget.scheduledAt,
              note: widget.note,
            )
          : api.rematch(_orderCode!);
      final res = await call;
      await minWait;
      if (!mounted) return;
      setState(() {
        _orderCode = res.orderCode;
        _result = res;
        _phase = res.matched ? _Phase.matched : _Phase.none;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _cancel() async {
    final code = _orderCode;
    if (code == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _cancelling = true);
    try {
      await PelangganApi.instance.cancelOrder(code, reason: 'Dibatalkan pelanggan saat mencari teknisi');
      if (!mounted) return;
      showSnack(context, 'Pesanan dibatalkan.');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _track() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TrackingPage(orderCode: _orderCode!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Selama mencari, tombol kembali tidak membatalkan pesanan diam-diam.
      canPop: _phase != _Phase.searching,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SubHeader(
                title: 'Mencari teknisi',
                subtitle: widget.service.name,
              ),
              const RoleBanner('PELANGGAN • Pencocokan teknisi otomatis'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: switch (_phase) {
                    _Phase.searching => _searching(),
                    _Phase.matched => _matched(),
                    _Phase.none => _none(),
                    _Phase.error => _failed(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searching() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: AnimatedBuilder(
              animation: _radar,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Builder(builder: (_) {
                      final t = (_radar.value + i / 3) % 1;
                      return Container(
                        width: 70 + 170 * t,
                        height: 70 + 170 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.green.withValues(alpha: 0.12 * (1 - t)),
                          border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.5 * (1 - t))),
                        ),
                      );
                    }),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.handyman_outlined, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Mencari teknisi terdekat...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(_messages[_msg],
                key: ValueKey(_msg),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      );

  Widget _matched() {
    final t = _result!.technician!;
    final reasons = <String>[
      'Menguasai layanan ${widget.service.name}',
      if (t.distanceKm != null) 'Terdekat dari lokasi Anda (${_km(t.distanceKm!)} km)',
      if (t.experienceYear > 0) 'Berpengalaman ${t.experienceYear} tahun',
      if (t.totalJobs > 0 && t.ratingAvg > 0)
        'Rating ${t.ratingAvg.toStringAsFixed(1)} dari ${t.totalJobs} pekerjaan',
    ];

    return ListView(
      children: [
        const SizedBox(height: 8),
        const Center(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.greenSoft,
            child: Icon(Icons.check, size: 30, color: AppColors.green),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Teknisi ditemukan!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(_result!.orderCode,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 16),
        FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Initials(t.name, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.green),
                            const SizedBox(width: 3),
                            Text(
                                t.totalJobs > 0
                                    ? t.ratingAvg.toStringAsFixed(1)
                                    : 'Baru',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(' • ${t.totalJobs} pekerjaan',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (t.etaMinutes != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('±${t.etaMinutes} mnt',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green)),
                        const Text('perkiraan tiba',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.border),
              ),
              const Text('Kenapa teknisi ini?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final r in reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 15, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Lacak teknisi', icon: Icons.near_me_outlined, onPressed: _track),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancelling ? null : _cancel,
          child: Text(_cancelling ? 'Membatalkan...' : 'Batalkan pesanan',
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _none() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.greenSoft,
            child: Icon(Icons.search_off, size: 32, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada teknisi tersedia',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Semua teknisi yang cocok sedang bertugas atau terlalu jauh dari lokasi Anda. Coba cari lagi atau ubah jadwal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Cari lagi', icon: Icons.refresh, onPressed: _run),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancelling ? null : _cancel,
            child: const Text('Batalkan pesanan',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      );

  Widget _failed() => ErrorRetry(message: _error ?? 'Terjadi kesalahan.', onRetry: _run);

  String _km(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}
