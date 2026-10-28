import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(String identifier) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final msg = await AuthService.instance.resetPassword(
        identifier: identifier,
        code: _code.text,
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      showSnack(context, msg);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final firstField =
          e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : null;
      showSnack(context, firstField ?? e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identifier =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(demoText: 'Atur ulang kata sandi'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Masukkan kode',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      identifier.isEmpty
                          ? 'Masukkan kode 6 digit yang dikirim ke email Anda, lalu buat kata sandi baru.'
                          : 'Kode 6 digit dikirim untuk $identifier. Masukkan kode tersebut, lalu buat kata sandi baru.',
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    FormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Kode pemulihan'),
                            AppTextField(
                              controller: _code,
                              hint: '6 digit kode',
                              icon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                                      ? null
                                      : 'Kode harus 6 digit angka',
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Kata sandi baru'),
                            AppTextField(
                              controller: _password,
                              hint: 'Buat kata sandi baru',
                              obscure: _obscure1,
                              onToggleObscure: () =>
                                  setState(() => _obscure1 = !_obscure1),
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
                              hint: 'Ulangi kata sandi baru',
                              obscure: _obscure2,
                              onToggleObscure: () =>
                                  setState(() => _obscure2 = !_obscure2),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(identifier),
                              validator: (v) => v != _password.text
                                  ? 'Konfirmasi kata sandi tidak sama'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Simpan kata sandi baru',
                              loading: _loading,
                              onPressed: () => _submit(identifier),
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
                        label: const Text('Kembali',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green)),
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
