import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final msg = await AuthService.instance.forgotPassword(_identifier.text);
      if (!mounted) return;
      showSnack(context, msg);
      Navigator.pushNamed(context, '/reset', arguments: _identifier.text.trim());
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
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: const Icon(Icons.key_outlined,
                          size: 20, color: AppColors.green),
                    ),
                    const SizedBox(height: 14),
                    const Text('Lupa kata sandi?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Pulihkan akses akun dengan email atau nomor WhatsApp yang sudah terdaftar.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    FormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pulihkan akun Anda',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            const Text('Untuk akun Pelanggan dan Teknisi.',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.green)),
                            const SizedBox(height: 14),
                            const FieldLabel('Email atau nomor Telepon'),
                            AppTextField(
                              controller: _identifier,
                              hint: 'Masukkan email atau nomor terdaftar',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Email atau nomor telepon wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Gunakan salah satu yang terhubung ke akun Anda.',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Kode pemulihan 6 digit akan dikirim ke email akun Anda.',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.4,
                                  color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: 'Minta pemulihan kata sandi',
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            size: 14, color: AppColors.green),
                        label: const Text('Kembali ke login',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const InfoBox(
                      title: 'Akses akun Teknisi',
                      child: Text(
                          'Jika email atau nomor telepon Anda tidak dapat diakses, hubungi Admin pengelola KomporCare untuk bantuan.'),
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