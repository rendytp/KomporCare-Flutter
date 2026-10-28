import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/layanan.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import 'cari_layanan_page.dart';

/// Beranda Pelanggan (tab "Layanan"). Semua data dari API Laravel.
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.onOpenPesanan});

  final VoidCallback onOpenPesanan;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  HomeData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await CustomerApi.instance.home();
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

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _openSearch({String? query}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CariLayananPage(initialQuery: query),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(address: _data?.address, unread: _data?.unread ?? 0),
            const _RoleBanner(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _retry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _Hero(onTap: () => _openSearch()),
          const SizedBox(height: 14),
          TextField(
            readOnly: true,
            onTap: () => _openSearch(),
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Cari layanan',
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Pilih layanan untuk mencari teknisi',
            action: 'Lihat semua',
            onAction: () => _openSearch(),
          ),
          const SizedBox(height: 10),
          if (data.services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada layanan tersedia.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final s in data.services)
                  _ServiceTile(service: s, onTap: () => _openSearch(query: s.name)),
              ],
            ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Kunjungan Anda',
            action: 'Lihat detail',
            onAction: widget.onOpenPesanan,
          ),
          const SizedBox(height: 10),
          if (data.activeOrder != null)
            _OrderCard(order: data.activeOrder!)
          else
            const _EmptyVisit(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.address, required this.unread});

  final AddressInfo? address;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final location = address == null
        ? 'Tambah alamat'
        : [address!.label, address!.city].where((e) => e.isNotEmpty).join(', ');

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department_outlined,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.green),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showSnack(context, 'Notifikasi akan segera hadir.'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none, size: 18),
                      if (unread > 0)
                        Positioned(
                          top: 7,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('KomporCare',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Text('Servis kompor gas panggilan',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  const _RoleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.greenSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Text(
        'PELANGGAN • Layanan dan jadwal diambil dari database',
        style: TextStyle(
            fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dapur nyaman,\nkompor terawat.',
              style: TextStyle(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text('Temukan teknisi, lihat tarif, lalu pilih waktu kunjungan.',
              style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 12),
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF2B7A55), Color(0xFF123F2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.local_fire_department_outlined,
                size: 54, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.greenDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cari layanan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(action,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green)),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(serviceIcon(service.name),
                    size: 18, color: AppColors.green),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(service.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(orderStatusLabel(order.status),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.serviceName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(jadwalLabel(order.scheduledAt, order.durationMin),
                    style: const TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.person_outline, size: 16, color: AppColors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.technicianName ?? 'Teknisi belum ditentukan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const Text('Teknisi',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(rupiah(order.totalPrice),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 14, color: AppColors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pembayaran: ${paymentLabel(order.paymentType, order.paymentMethod)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVisit extends StatelessWidget {
  const _EmptyVisit();

  @override
  Widget build(BuildContext context) {
    return const FormCard(
      child: Text('Belum ada kunjungan terjadwal.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
    );
  }
}
