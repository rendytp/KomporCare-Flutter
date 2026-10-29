import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/layanan.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import 'pesan_layanan_page.dart';

/// Cari layanan: daftar layanan dari tabel `services`, filter per kategori
/// (`service_categories`) dan pencarian teks.
class CariLayananPage extends StatefulWidget {
  const CariLayananPage({super.key, this.initialQuery, this.initialCategoryId});

  final String? initialQuery;
  final int? initialCategoryId;

  @override
  State<CariLayananPage> createState() => _CariLayananPageState();
}

class _CariLayananPageState extends State<CariLayananPage> {
  late final TextEditingController _search;
  Timer? _debounce;
  int? _categoryId;
  ServiceCatalog? _catalog;
  bool _loading = true;
  String? _error;
  int _req = 0; // mengabaikan respons lama bila ada permintaan yang lebih baru

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _categoryId = widget.initialCategoryId;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_req;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await CustomerApi.instance
          .services(query: _search.text.trim(), categoryId: _categoryId);
      if (!mounted || id != _req) return;
      setState(() {
        _catalog = c;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _req) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _selectCategory(int? id) {
    if (_categoryId == id) return;
    setState(() => _categoryId = id);
    _load();
  }

  void _order(ServiceItem s) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PesanLayananPage(service: s)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = _catalog?.categories ?? const <ServiceCategory>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).pop()),
            const _RoleBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Cari servis, pembersihan, atau komponen',
                      prefixIcon:
                          Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                            label: 'Semua',
                            selected: _categoryId == null,
                            onTap: () => _selectCategory(null)),
                        for (final c in categories) ...[
                          const SizedBox(width: 8),
                          _Chip(
                              label: c.name,
                              selected: _categoryId == c.id,
                              onTap: () => _selectCategory(c.id)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Layanan kompor',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                      if (_catalog != null)
                        Text('${_catalog!.services.length} layanan',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._results(),
                  const SizedBox(height: 4),
                  const InfoBox(
                    title: 'Tarif jelas, jadwal fleksibel',
                    child: Text(
                        'Tarif ditampilkan di muka dan waktu kunjungan bisa Anda pilih sendiri saat memesan.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results() {
    if (_loading && _catalog == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: AppColors.green)),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      ];
    }
    final items = _catalog?.services ?? const <ServiceItem>[];
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('Layanan tidak ditemukan.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ),
      ];
    }
    return [
      for (final s in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ServiceCard(service: s, onOrder: () => _order(s)),
        ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cari layanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Pilih perawatan untuk kompor Anda',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.local_fire_department_outlined,
                color: Colors.white, size: 18),
          ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.green : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.text)),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onOrder});

  final ServiceItem service;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final desc = service.description ??
        (service.durationMin != null
            ? 'Estimasi pengerjaan ${service.durationMin} menit.'
            : service.categoryName);
    final meta = [
      service.categoryName,
      if (service.durationMin != null) '${service.durationMin} menit',
    ].where((e) => e.isNotEmpty).join(' • ');

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(serviceIcon(service.name),
                    size: 18, color: AppColors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(meta,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.4, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mulai dari',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text(rupiah(service.basePrice),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pesan layanan',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
