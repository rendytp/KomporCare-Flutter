import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      // Peran (pelanggan / teknisi) ditentukan oleh server dari kolom users.role.
      final user = await AuthService.instance.login(
        identifier: _identifier.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        user.role == 'technician' ? '/teknisi' : '/pelanggan',
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                    const Text('Selamat datang kembali',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Masuk untuk melanjutkan ke KomporCare.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    FormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Masuk ke akun Anda',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            const FieldLabel('Email atau nomor Telepon'),
                            AppTextField(
                              controller: _identifier,
                              hint: 'Masukkan email atau nomor terdaftar',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username],
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Email atau nomor telepon wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            const FieldLabel('Kata sandi'),
                            AppTextField(
                              controller: _password,
                              hint: 'Masukkan kata sandi',
                              obscure: _obscure,
                              onToggleObscure: () =>
                                  setState(() => _obscure = !_obscure),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Kata sandi wajib diisi'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/forgot'),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text('Lupa kata sandi?',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.green)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            PrimaryButton(
                              label: 'Masuk',
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const InfoBox(
                      child: Text(
                          'Akun Teknisi disiapkan oleh pengelola KomporCare. Hubungi pengelola jika belum memiliki akses.'),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Column(
                        children: [
                          TextButton.icon(
                            onPressed: () => showSnack(context,
                                'Hubungi admin KomporCare untuk bantuan masuk.'),
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 14, color: AppColors.green),
                            label: const Text('Butuh bantuan masuk?',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.green)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Pelanggan baru? ',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textMuted)),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: const Text('Daftar akun pelanggan',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.green)),
                              ),
                            ],
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
}
