import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/alur_servis.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

/// Halaman QRIS. Kode dibuat oleh backend lewat API payment gateway (Midtrans).
/// Mengembalikan `true` lewat Navigator.pop bila pembayaran berhasil.
class QrisPage extends StatefulWidget {
  const QrisPage({super.key, required this.orderCode});

  final String orderCode;

  @override
  State<QrisPage> createState() => _QrisPageState();
}

enum _QrisState { loading, pending, expired, failed, paid, error }

class _QrisPageState extends State<QrisPage> {
  QrisCharge? _charge;
  _QrisState _state = _QrisState.loading;
  String? _error;
  int _left = 0;
  bool _checking = false;
  bool _confirmingDemo = false;
  Timer? _tick;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    _tick?.cancel();
    _poll?.cancel();
    setState(() {
      _state = _QrisState.loading;
      _error = null;
    });
    try {
      final c = await PelangganApi.instance.createQris(widget.orderCode);
      if (!mounted) return;
      setState(() {
        _charge = c;
        _left = c.secondsLeft;
        _state = c.secondsLeft > 0 ? _QrisState.pending : _QrisState.expired;
      });
      _startTimers();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _state = _QrisState.error;
      });
    }
  }

  void _startTimers() {
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _state != _QrisState.pending) return;
      if (_left > 0) {
        setState(() => _left--);
      } else {
        setState(() => _state = _QrisState.expired);
      }
    });
    // Mode demo tidak punya status dari gateway, jadi tidak perlu polling.
    if (_charge?.isDemo != true) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus(silent: true));
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_state != _QrisState.pending || _checking) return;
    if (!silent) setState(() => _checking = true);
    try {
      final s = await PelangganApi.instance.qrisStatus(widget.orderCode);
      if (!mounted) return;
      switch (s.status) {
        case 'paid':
          _onPaid();
        case 'expired':
          setState(() => _state = _QrisState.expired);
        case 'failed':
          setState(() => _state = _QrisState.failed);
        default:
          if (!silent) showSnack(context, 'Pembayaran belum diterima. Coba lagi sebentar.');
      }
    } on ApiException catch (e) {
      if (!silent && mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  void _onPaid() {
    _tick?.cancel();
    _poll?.cancel();
    setState(() => _state = _QrisState.paid);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  /// Hanya mode demo: tidak ada gateway yang bisa dibayar.
  Future<void> _confirmDemo() async {
    setState(() => _confirmingDemo = true);
    try {
      await PelangganApi.instance.pay(widget.orderCode, 'qris');
      if (mounted) _onPaid();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _confirmingDemo = false);
    }
  }

  String get _clock {
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _state != _QrisState.paid,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SubHeader(title: 'Pembayaran QRIS', subtitle: widget.orderCode),
              const RoleBanner('PELANGGAN • Kode QRIS dibuat lewat payment gateway'),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case _QrisState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.green),
              SizedBox(height: 14),
              Text('Membuat kode QRIS...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      case _QrisState.error:
        return ErrorRetry(message: _error ?? 'Gagal membuat kode QRIS.', onRetry: _create);
      case _QrisState.paid:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.check, size: 38, color: AppColors.green),
              ),
              SizedBox(height: 14),
              Text('Pembayaran berhasil',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Terima kasih! Mengarahkan Anda ke ulasan...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      default:
        return _qrView();
    }
  }

  Widget _qrView() {
    final c = _charge!;
    final dead = _state == _QrisState.expired || _state == _QrisState.failed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        FormCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Scan untuk membayar',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  if (c.isDemo)
                    const Pill('DEMO')
                  else if (c.sandbox)
                    const Pill('SANDBOX',
                        color: Color(0xFF8A5A00), background: Color(0xFFFFF1D6)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: dead || c.isDemo ? 0.2 : 1,
                      child: QrImageView(
                        data: c.qrString,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    if (dead)
                      _Badge(
                        _state == _QrisState.failed ? 'DIBATALKAN' : 'KEDALUWARSA',
                        AppColors.error,
                      )
                    else if (c.isDemo)
                      const _Badge('DEMO • TIDAK AKTIF', AppColors.error),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(rupiah(c.amount),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              if (!dead)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text('Bayar dalam $_clock',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!dead && !c.isDemo)
          const FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step('1', 'Buka aplikasi e-wallet atau mobile banking'),
                _Step('2', 'Pilih Scan / Bayar, arahkan kamera ke kode QR'),
                _Step('3', 'Periksa nominal lalu konfirmasi pembayaran'),
              ],
            ),
          ),
        if (c.sandbox && !dead) ...[
          const SizedBox(height: 12),
          const InfoBox(
            title: 'Mode uji (sandbox)',
            child: Text(
                'Kode ini tidak bisa dibayar dengan aplikasi e-wallet asli. Buka simulator.sandbox.midtrans.com/qris/index di browser dan ikuti petunjuknya untuk mensimulasikan pembayaran.'),
          ),
        ],
        if (c.isDemo) ...[
          const SizedBox(height: 12),
          const InfoBox(
            title: 'Mode demo',
            child: Text(
                'Server belum terhubung ke payment gateway (MIDTRANS_SERVER_KEY kosong). Kode ini hanya contoh.'),
          ),
        ],
        const SizedBox(height: 16),
        if (dead)
          PrimaryButton(label: 'Buat kode baru', icon: Icons.refresh, onPressed: _create)
        else if (c.isDemo)
          PrimaryButton(
            label: 'Konfirmasi pembayaran demo',
            icon: Icons.check,
            loading: _confirmingDemo,
            onPressed: _confirmDemo,
          )
        else
          PrimaryButton(
            label: 'Saya sudah bayar',
            icon: Icons.check,
            loading: _checking,
            onPressed: () => _checkStatus(),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ganti metode pembayaran',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ),
        const DemoFooter(
            'Status pembayaran dicek otomatis. Halaman ini akan berpindah sendiri setelah pembayaran diterima.'),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}

class _Step extends StatelessWidget {
  const _Step(this.no, this.text);
  final String no;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.greenSoft, shape: BoxShape.circle),
              child: Text(no,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.green)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}
