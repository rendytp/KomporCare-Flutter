import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/akun.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'alamat_form_page.dart';

class KelolaAlamatPage extends StatefulWidget {
  const KelolaAlamatPage({super.key});

  @override
  State<KelolaAlamatPage> createState() => _KelolaAlamatPageState();
}

class _KelolaAlamatPageState extends State<KelolaAlamatPage> {
  List<SavedAddress>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await PelangganApi.instance.addresses();
      if (!mounted) return;
      setState(() {
        _items = list;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _form([SavedAddress? a]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AlamatFormPage(address: a, isFirst: (_items ?? []).isEmpty),
    ));
    if (saved == true) _load();
  }

  Future<void> _makeDefault(SavedAddress a) async {
    try {
      await PelangganApi.instance.makeDefaultAddress(a.id);
      if (mounted) showSnack(context, 'Alamat utama diperbarui.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(SavedAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('Alamat "${a.label}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PelangganApi.instance.deleteAddress(a.id);
      if (mounted) showSnack(context, 'Alamat dihapus.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Kelola alamat',
              subtitle: 'Simpan alamat servis',
              trailing: Text('${items?.length ?? 0} alamat',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
            const RoleBanner('PELANGGAN • Alamat disimpan ke database'),
            Expanded(
              child: _error != null
                  ? ErrorRetry(message: _error!, onRetry: _load)
                  : items == null
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.green))
                      : RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            children: [
                              const Text(
                                  'Pilih alamat yang akan dipakai untuk kunjungan teknisi.',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppColors.textMuted)),
                              const SizedBox(height: 12),
                              if (items.isEmpty)
                                const EmptyNote('Belum ada alamat tersimpan.'),
                              for (final a in items) ...[
                                _AddressCard(
                                  address: a,
                                  onEdit: () => _form(a),
                                  onMakeDefault: () => _makeDefault(a),
                                  onDelete: () => _delete(a),
                                ),
                                const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 4),
                              PrimaryButton(
                                  label: 'Tambah alamat baru',
                                  icon: Icons.add,
                                  onPressed: () => _form()),
                              const SizedBox(height: 14),
                              const InfoBox(
                                title: 'Pastikan alamat mudah ditemukan',
                                child: Text(
                                    'Tambahkan patokan seperti warna pagar atau nama toko terdekat agar teknisi tidak tersesat.'),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onMakeDefault,
    required this.onDelete,
  });

  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = address;
    final contact = [
      if ((a.recipientName ?? '').isNotEmpty) a.recipientName!,
      if ((a.recipientPhone ?? '').isNotEmpty) a.recipientPhone!,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: a.isDefault ? AppColors.green : AppColors.border,
            width: a.isDefault ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                    a.label.toLowerCase().contains('kantor')
                        ? Icons.business_outlined
                        : Icons.home_outlined,
                    size: 16,
                    color: AppColors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(a.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              if (a.isDefault) const Pill('Utama'),
            ],
          ),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(contact,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 4),
          Text(a.oneLine, style: const TextStyle(fontSize: 11.5, height: 1.35)),
          if (a.hasPin) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Pin lokasi: ${a.latitude!.toStringAsFixed(5)}, ${a.longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ],
          if ((a.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 13, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(a.note!,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _LinkAction(icon: Icons.edit_outlined, label: 'Ubah alamat', onTap: onEdit),
              const Spacer(),
              if (!a.isDefault) ...[
                _LinkAction(label: 'Jadikan utama', onTap: onMakeDefault),
                const SizedBox(width: 12),
                _LinkAction(
                    icon: Icons.delete_outline, label: 'Hapus', danger: true, onTap: onDelete),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label, required this.onTap, this.icon, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.error : AppColors.green;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: c), const SizedBox(width: 4)],
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }
}
