import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

class UbahProfilPage extends StatefulWidget {
  const UbahProfilPage({super.key});

  @override
  State<UbahProfilPage> createState() => _UbahProfilPageState();
}

class _UbahProfilPageState extends State<UbahProfilPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  Map<String, String> _serverErrors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = AuthService.instance.currentUser;
    _name = TextEditingController(text: u?.fullName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _email = TextEditingController(text: u?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PelangganApi.instance.updateProfile(
        fullName: _name.text,
        phone: _phone.text,
        email: _email.text,
      );
      if (!mounted) return;
      showSnack(context, 'Profil berhasil diperbarui.');
      Navigator.of(context).pop();
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
    final name = AuthService.instance.currentUser?.fullName ?? '';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(
                title: 'Ubah profil', subtitle: 'Perbarui informasi akun Anda'),
            const RoleBanner('PELANGGAN • Perubahan disimpan ke database'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FormCard(
                    child: Row(
                      children: [
                        Initials(name, radius: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w800)),
                              const Text('Pelanggan',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showSnack(context, 'Ubah foto akan segera hadir.'),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  size: 18, color: AppColors.green),
                              SizedBox(height: 2),
                              Text('Ubah foto',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Informasi pribadi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Pastikan data Anda benar agar teknisi mudah menghubungi Anda.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Nama lengkap'),
                        AppTextField(
                          controller: _name,
                          hint: 'Nama lengkap',
                          icon: Icons.person_outline,
                          errorText: _serverErrors['full_name'],
                          validator: (v) => (v == null || v.trim().length < 3)
                              ? 'Nama minimal 3 karakter.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Nomor telepon'),
                        AppTextField(
                          controller: _phone,
                          hint: '08xxxxxxxxxx',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          errorText: _serverErrors['phone'],
                          validator: (v) => (v == null || v.trim().length < 9)
                              ? 'Nomor telepon tidak valid.'
                              : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Nomor ini dipakai untuk masuk dan dihubungi teknisi.',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Alamat email'),
                        AppTextField(
                          controller: _email,
                          hint: 'nama@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          errorText: _serverErrors['email'],
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email tidak valid.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const InfoBox(
                    title: 'Data Anda tetap aman',
                    child: Text(
                        'Informasi pribadi hanya dipakai untuk kebutuhan layanan KomporCare.'),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                      label: 'Simpan perubahan', icon: Icons.check, loading: _saving, onPressed: _save),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
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
