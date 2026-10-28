import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _accepted = false;
  bool _termsError = false;
  bool _loading = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = {};
      _termsError = !_accepted;
    });
    if (!_formKey.currentState!.validate() || !_accepted) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        fullName: _name.text,
        phone: _phone.text,
        email: _email.text,
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/pelanggan', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors.isNotEmpty) {
        setState(() => _serverErrors = e.fieldErrors);
      } else {
        showSnack(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(
                demoText: ''),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daftar akun pelanggan',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Pesan servis kompor dan pantau setiap kunjungan dengan mudah.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    FormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Data akun Pelanggan',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            const FieldLabel('Nama lengkap'),
                            AppTextField(
                              controller: _name,
                              hint: 'Masukkan nama lengkap',
                              icon: Icons.person_outline,
                              errorText: _serverErrors['full_name'],
                              autofillHints: const [AutofillHints.name],
                              validator: (v) {
                                if (_required(v, 'Nama lengkap wajib diisi') != null) {
                                  return 'Nama lengkap wajib diisi';
                                }
                                if (v!.trim().length < 3) return 'Nama minimal 3 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Nomor Telepon'),
                            AppTextField(
                              controller: _phone,
                              hint: 'Masukkan nomor telepon',
                              icon: Icons.chat_bubble_outline,
                              keyboardType: TextInputType.phone,
                              errorText: _serverErrors['phone'],
                              autofillHints: const [AutofillHints.telephoneNumber],
                              validator: (v) {
                                if (_required(v, 'x') != null) {
                                  return 'Nomor telepon wajib diisi';
                                }
                                final digits = v!.replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.length < 9 || digits.length > 15) {
                                  return 'Nomor telepon tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Email'),
                            AppTextField(
                              controller: _email,
                              hint: 'Masukkan alamat email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              errorText: _serverErrors['email'],
                              autofillHints: const [AutofillHints.email],
                              validator: (v) {
                                if (_required(v, 'x') != null) return 'Email wajib diisi';
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Kata sandi'),
                            AppTextField(
                              controller: _password,
                              hint: 'Buat kata sandi',
                              obscure: _obscure1,
                              onToggleObscure: () =>
                                  setState(() => _obscure1 = !_obscure1),
                              errorText: _serverErrors['password'],
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                                if (v.length < 8) return 'Kata sandi minimal 8 karakter';
                                if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                                    !RegExp(r'[0-9]').hasMatch(v)) {
                                  return 'Gunakan kombinasi huruf dan angka';
                                }
                                return null;
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Minimal 8 karakter, gunakan huruf dan angka.',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.textMuted)),
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Konfirmasi kata sandi'),
                            AppTextField(
                              controller: _confirm,
                              hint: 'Ulangi kata sandi',
                              obscure: _obscure2,
                              onToggleObscure: () =>
                                  setState(() => _obscure2 = !_obscure2),
                              textInputAction: TextInputAction.done,
                              validator: (v) => v != _password.text
                                  ? 'Konfirmasi kata sandi tidak sama'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _accepted,
                                    activeColor: AppColors.green,
                                    onChanged: (v) => setState(() {
                                      _accepted = v ?? false;
                                      _termsError = false;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          height: 1.4,
                                          color: AppColors.textMuted),
                                      children: [
                                        const TextSpan(text: 'Saya menyetujui '),
                                        _link('Syarat & Ketentuan'),
                                        const TextSpan(text: ' serta '),
                                        _link('Kebijakan Privasi'),
                                        const TextSpan(text: ' KomporCare.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_termsError)
                              const Padding(
                                padding: EdgeInsets.only(top: 4, left: 30),
                                child: Text('Anda harus menyetujui syarat & ketentuan',
                                    style: TextStyle(
                                        fontSize: 10.5, color: AppColors.error)),
                              ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Daftar sebagai Pelanggan',
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sudah punya akun? ',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Kembali ke login',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green)),
                          ),
                        ],
                      ),
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

  TextSpan _link(String text) => TextSpan(
        text: text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.green),
      );
}
