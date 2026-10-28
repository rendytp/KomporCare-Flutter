import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/pesanan.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'cari_layanan_page.dart';
import 'chat_page.dart';
import 'notifikasi_page.dart';

enum _Filter { semua, aktif, riwayat }

/// Tab "Pesanan": kunjungan aktif + riwayat pesanan pelanggan.
class PesananPage extends StatefulWidget {
  const PesananPage({super.key, required this.refresh});

  /// Dinaikkan oleh shell setiap kali tab ini dibuka, supaya data dimuat ulang.
  final ValueNotifier<int> refresh;

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  OrderList? _data;
  String? _error;
  bool _loading = true;
  _Filter _filter = _Filter.semua;
  String? _openingChat;

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await PelangganApi.instance.orders();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_data != null) showSnack(context, e.message, error: true);
      setState(() {
        _error = _data == null ? e.message : null;
        _loading = false;
      });
    }
  }

  Future<void> _chatTeknisi(CustomerOrder o) async {
    if (!o.hasTechnician) {
      showSnack(context, 'Teknisi belum ditentukan untuk pesanan ini.');
      return;
    }
    setState(() => _openingChat = o.orderCode);
    try {
      final id = await PelangganApi.instance.openOrderChat(o.orderCode);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(conversationId: id),
      ));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _openingChat = null);
    }
  }

  void _pesanLagi(CustomerOrder o) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CariLayananPage(initialQuery: o.serviceName),
    ));
  }

  void _detail(CustomerOrder o) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _OrderDetailSheet(order: o),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: 'Pesanan',
              subtitle: 'Kelola kunjungan aktif & riwayat servis Anda',
              onBell: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const NotifikasiPage())),
            ),
            const RoleBanner('PELANGGAN • Data pesanan diambil dari database'),
            Expanded(child: _body(d)),
          ],
        ),
      ),
    );
  }

  Widget _body(OrderList? d) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null || d == null) {
      return ErrorRetry(
        message: _error ?? 'Gagal memuat pesanan.',
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _load();
        },
      );
    }

    final showActive = _filter != _Filter.riwayat;
    final showHistory = _filter != _Filter.aktif;

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _Segments(
            filter: _filter,
            activeCount: d.active.length,
            historyCount: d.history.length,
            onChanged: (f) => setState(() => _filter = f),
          ),
          if (showActive) ...[
            const SizedBox(height: 16),
            SectionTitle('Kunjungan aktif', trailing: '${d.active.length} pesanan'),
            const SizedBox(height: 10),
            if (d.active.isEmpty)
              const EmptyNote('Belum ada kunjungan aktif.')
            else
              for (final o in d.active) ...[
                _ActiveCard(
                  order: o,
                  openingChat: _openingChat == o.orderCode,
                  onTrack: () => _detail(o),
                  onChat: () => _chatTeknisi(o),
                ),
                const SizedBox(height: 10),
              ],
          ],
          if (showHistory) ...[
            const SizedBox(height: 8),
            SectionTitle('Riwayat pesanan', trailing: '${d.history.length} pesanan'),
            const SizedBox(height: 10),
            if (d.history.isEmpty)
              const EmptyNote('Belum ada riwayat pesanan.')
            else
              for (final o in d.history) ...[
                _HistoryCard(
                  order: o,
                  onDetail: () => _detail(o),
                  onReorder: () => _pesanLagi(o),
                ),
                const SizedBox(height: 10),
              ],
          ],
          const DemoFooter(
              'Biaya servis mengikuti diagnosis dan persetujuan Anda. Pembayaran dilakukan setelah servis selesai.'),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.filter,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  final _Filter filter;
  final int activeCount;
  final int historyCount;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(_Filter f, String label) {
      final on = filter == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : AppColors.text)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          seg(_Filter.semua, 'Semua'),
          seg(_Filter.aktif, 'Aktif ($activeCount)'),
          seg(_Filter.riwayat, 'Riwayat ($historyCount)'),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.order,
    required this.openingChat,
    required this.onTrack,
    required this.onChat,
  });

  final CustomerOrder order;
  final bool openingChat;
  final VoidCallback onTrack;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final tech = order.technicianName;
    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              ),
              OrderStatusPill(order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.extraItems > 0
                ? '${order.serviceName} +${order.extraItems}'
                : order.serviceName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _IconLine(Icons.schedule, jadwalLabel(order.scheduledAt, order.durationMin)),
          const SizedBox(height: 4),
          _IconLine(Icons.location_on_outlined, order.address),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Initials(tech ?? '?', radius: 15, icon: tech == null ? Icons.person_outline : null),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tech ?? 'Teknisi belum ditentukan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Text('Teknisi',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Estimasi total',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(rupiah(order.totalPrice),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SmallButton(
                    label: 'Lacak pesanan', icon: Icons.near_me_outlined, onPressed: onTrack),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SmallButton(
                  label: openingChat ? 'Membuka...' : 'Chat teknisi',
                  icon: Icons.chat_bubble_outline,
                  filled: false,
                  onPressed: openingChat ? null : onChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order, required this.onDetail, required this.onReorder});

  final CustomerOrder order;
  final VoidCallback onDetail;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final done = order.status == 'completed';
    final date = tanggalLengkap(order.completedAt ?? order.scheduledAt);
    final meta = [date, if (order.technicianName != null) order.technicianName!].join(' • ');
    final payInfo = done
        ? (order.isPaid ? ' • Lunas' : '')
        : '';

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              ),
              OrderStatusPill(order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.extraItems > 0
                ? '${order.serviceName} +${order.extraItems}'
                : order.serviceName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(meta, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Total ${rupiah(order.totalPrice)}$payInfo',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: done ? onReorder : onDetail,
                child: Text(done ? 'Pesan lagi' : 'Lihat detail',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
              ),
              if (done) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onDetail,
                  child: const Text('Lihat detail',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.3))),
        ],
      );
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(k,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
              const SizedBox(width: 12),
              Flexible(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
              ),
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(order.orderCode,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
                OrderStatusPill(order.status),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Detail pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            row('Jadwal', jadwalLabel(order.scheduledAt, order.durationMin)),
            row('Alamat', order.address),
            row('Teknisi', order.technicianName ?? 'Belum ditentukan'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            for (final i in order.items)
              row('${i.name}${i.qty > 1 ? ' ×${i.qty}' : ''}', rupiah(i.price * i.qty)),
            if (order.transportFee > 0) row('Biaya transport', rupiah(order.transportFee)),
            row('Total', rupiah(order.totalPrice), bold: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            row('Metode bayar', paymentLabel(order.paymentType, order.paymentMethod)),
            row('Status bayar', paymentStatusLabel(order.paymentStatus)),
            if (order.cancelReason != null && order.cancelReason!.isNotEmpty)
              row('Alasan batal', order.cancelReason!),
          ],
        ),
      ),
    );
  }
}
