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
import 'ulasan_page.dart';

/// Pembayaran setelah servis selesai: Tunai (dikonfirmasi teknisi) atau QRIS (demo).
class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key, required this.orderCode});

  final String orderCode;

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  PaymentInfo? _info;
  String? _error;
  String _method = 'qris';
  bool _paying = false;
  bool _cashRequested = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final info = await PelangganApi.instance.paymentInfo(widget.orderCode);
      if (!mounted) return;
      setState(() {
        _info = info;
        _error = null;
      });
      if (info.status == 'completed') {
        _poll?.cancel();
        _goReview();
      }
    } on ApiException catch (e) {
      if (mounted && _info == null) setState(() => _error = e.message);
    }
  }

  void _goReview() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UlasanPage(orderCode: widget.orderCode)),
    );
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final res = await PelangganApi.instance.pay(widget.orderCode, _method);
      if (!mounted) return;
      showSnack(context, res.message);
      if (res.completed) {
        _goReview();
      } else {
        // Tunai: tunggu teknisi mengonfirmasi uang diterima.
        setState(() => _cashRequested = true);
        _poll?.cancel();
        _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Pembayaran',
              subtitle: info == null
                  ? widget.orderCode
                  : '${info.orderCode}${info.finishedAt != null ? ' • Servis selesai ${jamLabel(info.finishedAt!)}' : ''}',
            ),
            const RoleBanner('PELANGGAN • Pembayaran Tunai dan QRIS (demo)'),
            Expanded(child: _body(info)),
          ],
        ),
      ),
    );
  }

  Widget _body(PaymentInfo? info) {
    if (info == null) {
      return _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final tech = info.technicianName ?? 'teknisi';
    final first = tech.split(' ').first;
    final locked = !info.canPay;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${info.customerName} • $tech',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            if (info.isPaid)
              const Pill('Lunas')
            else if (_cashRequested)
              const Pill('Menunggu konfirmasi',
                  color: Color(0xFF8A5A00), background: Color(0xFFFFF1D6))
            else
              const Pill('Belum dibayar',
                  color: Color(0xFF8A5A00), background: Color(0xFFFFF1D6)),
          ],
        ),
        const SizedBox(height: 12),
        FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tagihan servis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final l in info.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(l.label,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted))),
                      Text(rupiah(l.amount),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                children: [
                  const Expanded(
                      child: Text('Total pembayaran',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                  Text(rupiah(info.total),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.green)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Pilih metode pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MethodTile(
                icon: Icons.payments_outlined,
                title: 'Tunai',
                subtitle: 'Bayar ke teknisi',
                selected: _method == 'cash',
                onTap: locked || _cashRequested ? null : () => setState(() => _method = 'cash'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MethodTile(
                icon: Icons.qr_code_2,
                title: 'QRIS',
                subtitle: 'Scan QRIS (demo)',
                selected: _method == 'qris',
                onTap: locked || _cashRequested ? null : () => setState(() => _method = 'qris'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_method == 'qris')
          FormCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text('QRIS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    Pill('DEMO'),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('KomporCare • Contoh tagihan ${info.orderCode}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.35,
                        child: QrImageView(
                          data: info.qrString,
                          size: 170,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('DEMO • TIDAK AKTIF',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(rupiah(info.total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                    'Kode QRIS ini hanya contoh dan tidak dapat dibayar lewat aplikasi bank atau e-wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, height: 1.4, color: AppColors.textMuted)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        InfoBox(
          child: Text(
              'Jika memilih Tunai, serahkan ${rupiah(info.total)} kepada $first. Pesanan dicatat selesai setelah teknisi mengonfirmasi uang diterima.'),
        ),
        const SizedBox(height: 14),
        if (_cashRequested)
          const FormCard(
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Menunggu teknisi mengonfirmasi pembayaran tunai...',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )
        else if (info.isPaid)
          PrimaryButton(label: 'Lihat ulasan', icon: Icons.star_outline, onPressed: _goReview)
        else
          PrimaryButton(
            label: _method == 'qris' ? 'Konfirmasi pembayaran demo' : 'Saya bayar tunai',
            icon: Icons.check,
            loading: _paying,
            onPressed: locked ? null : _pay,
          ),
        if (locked && !info.isPaid && !_cashRequested)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Pembayaran dibuka setelah teknisi menandai servis selesai.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        const DemoFooter(
            'Pembayaran QRIS pada versi ini hanya simulasi dan tidak memindahkan uang.'),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: selected ? AppColors.green : AppColors.textMuted),
                  const Spacer(),
                  Icon(selected ? Icons.check_circle : Icons.radio_button_off,
                      size: 18, color: selected ? AppColors.green : AppColors.border),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}
