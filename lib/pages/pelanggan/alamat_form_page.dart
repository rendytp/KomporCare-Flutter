import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/akun.dart';
import '../../services/auth_service.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'pilih_lokasi_page.dart';

/// Form tambah / ubah alamat. Mengembalikan `true` bila berhasil disimpan.
class AlamatFormPage extends StatefulWidget {
  const AlamatFormPage({super.key, this.address, this.isFirst = false});

  final SavedAddress? address;
  final bool isFirst;

  @override
  State<AlamatFormPage> createState() => _AlamatFormPageState();
}

class _AlamatFormPageState extends State<AlamatFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late final TextEditingController _note;
  bool _makeDefault = false;
  double? _lat;
  double? _lng;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final u = AuthService.instance.currentUser;
    _label = TextEditingController(text: a?.label ?? '');
    _recipient = TextEditingController(text: a?.recipientName ?? u?.fullName ?? '');
    _phone = TextEditingController(text: a?.recipientPhone ?? u?.phone ?? '');
    _address = TextEditingController(text: a?.fullAddress ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _note = TextEditingController(text: a?.note ?? '');
    _makeDefault = widget.isFirst;
    _lat = a?.latitude;
    _lng = a?.longitude;

    // Alamat baru: langsung buka peta supaya tidak perlu mengetik manual.
    if (a == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickOnMap();
      });
    }
  }

  Future<void> _pickOnMap() async {
    final initial = (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null;
    final picked = await Navigator.of(context, rootNavigator: true).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => PilihLokasiPage(initial: initial)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lat = picked.lat;
      _lng = picked.lng;
      if (picked.fullAddress.isNotEmpty) _address.text = picked.fullAddress;
      if (picked.city.isNotEmpty) _city.text = picked.city;
      if ((picked.postalCode ?? '').isNotEmpty) _postal.text = picked.postalCode!;
    });
  }

  @override
  void dispose() {
    for (final c in [_label, _recipient, _phone, _address, _city, _postal, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String msg) => (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = PelangganApi.instance;
      if (_editing) {
        await api.updateAddress(
          widget.address!.id,
          label: _label.text,
          recipientName: _recipient.text,
          recipientPhone: _phone.text,
          fullAddress: _address.text,
          city: _city.text,
          postalCode: _postal.text,
          note: _note.text,
          latitude: _lat,
          longitude: _lng,
        );
      } else {
        await api.addAddress(
          label: _label.text,
          recipientName: _recipient.text,
          recipientPhone: _phone.text,
          fullAddress: _address.text,
          city: _city.text,
          postalCode: _postal.text,
          note: _note.text,
          latitude: _lat,
          longitude: _lng,
          isDefault: _makeDefault,
        );
      }
      if (!mounted) return;
      showSnack(context, _editing ? 'Alamat diperbarui.' : 'Alamat ditambahkan.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: _editing ? 'Ubah alamat' : 'Tambah alamat baru',
              subtitle: 'Alamat tujuan kunjungan teknisi',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _LocationCard(lat: _lat, lng: _lng, onTap: _pickOnMap),
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Nama alamat'),
                        AppTextField(
                          controller: _label,
                          hint: 'Contoh: Rumah, Kantor',
                          errorText: _serverErrors['label'],
                          validator: (v) => _required(v, 'Nama alamat wajib diisi.'),
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Nama penerima'),
                        AppTextField(
                          controller: _recipient,
                          hint: 'Nama yang menerima teknisi',
                          errorText: _serverErrors['recipient_name'],
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Nomor telepon penerima'),
                        AppTextField(
                          controller: _phone,
                          hint: '08xxxxxxxxxx',
                          keyboardType: TextInputType.phone,
                          errorText: _serverErrors['recipient_phone'],
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Alamat lengkap'),
                        TextFormField(
                          controller: _address,
                          minLines: 2,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 13),
                          validator: (v) => _required(v, 'Alamat lengkap wajib diisi.'),
                          decoration: InputDecoration(
                            hintText: 'Jalan, nomor, RT/RW, kelurahan',
                            errorText: _serverErrors['full_address'],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FieldLabel('Kota'),
                                  AppTextField(
                                    controller: _city,
                                    hint: 'Kota',
                                    errorText: _serverErrors['city'],
                                    validator: (v) => _required(v, 'Kota wajib diisi.'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FieldLabel('Kode pos'),
                                  AppTextField(
                                    controller: _postal,
                                    hint: 'Opsional',
                                    keyboardType: TextInputType.number,
                                    errorText: _serverErrors['postal_code'],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Patokan / catatan untuk teknisi'),
                        AppTextField(
                          controller: _note,
                          hint: 'Contoh: pagar hijau, dekat warung',
                          textInputAction: TextInputAction.done,
                          errorText: _serverErrors['note'],
                        ),
                        if (!_editing && !widget.isFirst) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _makeDefault,
                            onChanged: (v) => setState(() => _makeDefault = v ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.green,
                            dense: true,
                            title: const Text('Jadikan alamat utama',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _editing ? 'Simpan perubahan' : 'Simpan alamat',
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu pemilih lokasi: tombol "Pilih lokasi di peta" atau pratinjau peta + pin.
class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.lat, required this.lng, required this.onTap});

  final double? lat;
  final double? lng;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (lat == null || lng == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.greenBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.map_outlined, size: 26, color: AppColors.green),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih lokasi di peta',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
                    SizedBox(height: 2),
                    Text('Alamat terisi otomatis dari titik yang Anda pilih.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.green),
            ],
          ),
        ),
      );
    }

    final point = LatLng(lat!, lng!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey('$lat,$lng'),
              options: MapOptions(
                initialCenter: point,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.komporcare',
                ),
              ],
            ),
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Icon(Icons.location_on, size: 36, color: AppColors.error),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 15),
                label: const Text('Ubah lokasi', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 34),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
