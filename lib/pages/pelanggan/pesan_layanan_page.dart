import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/akun.dart';
import '../../models/layanan.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'alamat_form_page.dart';
import 'kelola_alamat_page.dart';
import 'pencarian_teknisi_page.dart';

/// Form pemesanan: layanan, alamat (dengan pin), jadwal, catatan -> cari teknisi otomatis.
class PesanLayananPage extends StatefulWidget {
  const PesanLayananPage({super.key, required this.service});

  final ServiceItem service;

  @override
  State<PesanLayananPage> createState() => _PesanLayananPageState();
}

class _PesanLayananPageState extends State<PesanLayananPage> {
  final _note = TextEditingController();
  List<SavedAddress>? _addresses;
  String? _error;
  int? _addressId;
  bool _asap = true;
  late DateTime _when;

  @override
  void initState() {
    super.initState();
    _when = DateTime.now().add(const Duration(hours: 2));
    _loadAddresses();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await PelangganApi.instance.addresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _error = null;
        final stillThere = list.any((a) => a.id == _addressId);
        if (!stillThere) {
          _addressId = list.isEmpty
              ? null
              : list.firstWhere((a) => a.isDefault, orElse: () => list.first).id;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  SavedAddress? get _selected {
    final l = _addresses;
    if (l == null || _addressId == null) return null;
    for (final a in l) {
      if (a.id == _addressId) return a;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _when.isBefore(now) ? now : _when,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (d == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _when.hour, minute: _when.minute),
    );
    if (t == null) return;
    setState(() => _when = DateTime(_when.year, _when.month, _when.day, t.hour, t.minute));
  }

  Future<void> _manageAddresses() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KelolaAlamatPage()));
    if (mounted) _loadAddresses();
  }

  Future<void> _editAddress(SavedAddress a) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AlamatFormPage(address: a)));
    if (saved == true && mounted) _loadAddresses();
  }

  void _submit() {
    final a = _selected;
    if (a == null) {
      showSnack(context, 'Pilih alamat servis terlebih dahulu.', error: true);
      return;
    }
    if (!_asap && _when.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      showSnack(context, 'Jadwal tidak boleh di masa lalu.', error: true);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PencarianTeknisiPage(
        service: widget.service,
        addressId: a.id,
        scheduledAt: _asap ? null : _when,
        note: _note.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final total = s.basePrice + s.visitFee;
    final selected = _selected;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: 'Pesan layanan', subtitle: s.name),
            const RoleBanner('PELANGGAN • Teknisi dipilih otomatis oleh sistem'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  FormCard(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(serviceIcon(s.name), size: 19, color: AppColors.green),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w800)),
                              Text(
                                  [
                                    s.categoryName,
                                    if (s.durationMin != null) '${s.durationMin} menit',
                                  ].where((e) => e.isNotEmpty).join(' • '),
                                  style: const TextStyle(
                                      fontSize: 10.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionTitle('Alamat servis', action: 'Kelola', onAction: _manageAddresses),
                  const SizedBox(height: 10),
                  if (_error != null)
                    ErrorRetry(message: _error!, onRetry: _loadAddresses)
                  else if (_addresses == null)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                    )
                  else if (_addresses!.isEmpty)
                    Column(
                      children: [
                        const EmptyNote('Belum ada alamat. Tambahkan alamat servis dahulu.'),
                        const SizedBox(height: 10),
                        PrimaryButton(
                            label: 'Tambah alamat', icon: Icons.add, onPressed: _manageAddresses),
                      ],
                    )
                  else
                    for (final a in _addresses!) ...[
                      _AddressOption(
                        address: a,
                        selected: a.id == _addressId,
                        onTap: () => setState(() => _addressId = a.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                  if (selected != null && !selected.hasPin)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: InfoBox(
                        title: 'Alamat belum punya pin lokasi',
                        child: GestureDetector(
                          onTap: () => _editAddress(selected),
                          child: const Text(
                              'Tanpa pin, jarak teknisi tidak bisa dihitung sehingga pencocokan kurang akurat. Ketuk di sini untuk menambah pin di peta.',
                              style: TextStyle(
                                  fontSize: 11, height: 1.4, color: AppColors.textMuted)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const SectionTitle('Jadwal kunjungan'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Choice(
                          icon: Icons.bolt,
                          label: 'Secepatnya',
                          selected: _asap,
                          onTap: () => setState(() => _asap = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Choice(
                          icon: Icons.event_outlined,
                          label: 'Pilih jadwal',
                          selected: !_asap,
                          onTap: () => setState(() => _asap = false),
                        ),
                      ),
                    ],
                  ),
                  if (!_asap) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined, size: 15),
                            label: Text(tanggalLengkap(_when),
                                style: const TextStyle(fontSize: 11.5)),
                            style: _outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule, size: 15),
                          label: Text(jamLabel(_when), style: const TextStyle(fontSize: 11.5)),
                          style: _outline,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  const SectionTitle('Catatan keluhan'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: api kompor kecil dan berbau gas',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FormCard(
                    child: Column(
                      children: [
                        _Row('Jasa servis (mulai dari)', rupiah(s.basePrice)),
                        _Row('Biaya kunjungan', rupiah(s.visitFee)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        _Row('Estimasi total', rupiah(total), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const InfoBox(
                    title: 'Teknisi dipilih otomatis',
                    child: Text(
                        'Sistem mencari teknisi terverifikasi yang menguasai layanan ini, paling dekat dengan alamat Anda, dengan mempertimbangkan pengalaman dan rating. Biaya akhir mengikuti diagnosis dan dibayar setelah servis selesai.'),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Cari teknisi terdekat',
                    icon: Icons.search,
                    onPressed: selected == null ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _outline => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v, {this.bold = false});
  final String k;
  final String v;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: TextStyle(
                        fontSize: 12,
                        color: bold ? AppColors.text : AppColors.textMuted,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
            Text(v,
                style: TextStyle(
                    fontSize: bold ? 14 : 12,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: selected ? 1.4 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.green : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.green : AppColors.text)),
            ],
          ),
        ),
      );
}

class _AddressOption extends StatelessWidget {
  const _AddressOption({required this.address, required this.selected, required this.onTap});

  final SavedAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: selected ? 1.4 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18, color: selected ? AppColors.green : AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(address.label,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        if (address.isDefault) ...[
                          const SizedBox(width: 6),
                          const Pill('Utama'),
                        ],
                        if (address.hasPin) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.location_on, size: 13, color: AppColors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(address.oneLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
