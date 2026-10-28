import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

class GantiPasswordPage extends StatefulWidget {
  const GantiPasswordPage({super.key});

  @override
  State<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final msg = await PelangganApi.instance.changePassword(
        current: _current.text,
        password: _new.text,
        confirmation: _confirm.text,
      );
      if (!mounted) return;
      showSnack(context, msg);
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(title: 'Ganti Password', subtitle: 'Perbarui kata sandi Anda'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Kata sandi saat ini'),
                        AppTextField(
                          controller: _current,
                          hint: 'Kata sandi saat ini',
                          obscure: _hideCurrent,
                          onToggleObscure: () =>
                              setState(() => _hideCurrent = !_hideCurrent),
                          errorText: _serverErrors['current_password'],
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi.' : null,
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Kata sandi baru'),
                        AppTextField(
                          controller: _new,
                          hint: 'Minimal 8 karakter, huruf dan angka',
                          obscure: _hideNew,
                          onToggleObscure: () => setState(() => _hideNew = !_hideNew),
                          errorText: _serverErrors['password'],
                          validator: (v) {
                            if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                            if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                                !RegExp(r'[0-9]').hasMatch(v)) {
                              return 'Harus mengandung huruf dan angka.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const FieldLabel('Konfirmasi kata sandi baru'),
                        AppTextField(
                          controller: _confirm,
                          hint: 'Ulangi kata sandi baru',
                          obscure: _hideNew,
                          textInputAction: TextInputAction.done,
                          validator: (v) =>
                              v != _new.text ? 'Konfirmasi kata sandi tidak sama.' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Simpan kata sandi',
                    icon: Icons.lock_outline,
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
