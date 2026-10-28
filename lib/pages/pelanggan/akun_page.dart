import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/akun.dart';
import '../../services/auth_service.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'chat_page.dart';
import 'ganti_password_page.dart';
import 'info_page.dart';
import 'kelola_alamat_page.dart';
import 'notifikasi_page.dart';
import 'ubah_profil_page.dart';

/// Tab "Akun": profil, alamat servis, pengaturan, bantuan.
class AkunPage extends StatefulWidget {
  const AkunPage({super.key, required this.refresh});

  final ValueNotifier<int> refresh;

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  List<SavedAddress>? _addresses;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await PelangganApi.instance.addresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && _addresses == null) setState(() => _error = e.message);
    }
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) {
      setState(() {}); // profil mungkin berubah
      _load();
    }
  }

  Future<void> _openHelp() async {
    try {
      final id = await PelangganApi.instance.openSupportChat();
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChatPage(conversationId: id)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk memakai aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final primary = (_addresses ?? []).isEmpty
        ? null
        : _addresses!.firstWhere((a) => a.isDefault, orElse: () => _addresses!.first);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TabHeader(title: 'Akun', subtitle: 'Profil dan pengaturan pelanggan'),
            const RoleBanner('PELANGGAN • Profil diambil dari database'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    FormCard(
                      child: Row(
                        children: [
                          Initials(user?.fullName ?? '?', radius: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.fullName ?? 'Pelanggan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800)),
                                Text(user?.phone ?? '-',
                                    style: const TextStyle(
                                        fontSize: 11.5, color: AppColors.textMuted)),
                                Text(user?.email ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11.5, color: AppColors.textMuted)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Pill('Pelanggan'),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _push(const UbahProfilPage()),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit_outlined,
                                              size: 13, color: AppColors.green),
                                          SizedBox(width: 4),
                                          Text('Ubah profil',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.green)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle('Alamat servis',
                        action: 'Kelola', onAction: () => _push(const KelolaAlamatPage())),
                    const SizedBox(height: 10),
                    if (_error != null)
                      EmptyNote(_error!)
                    else if (_addresses == null)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                            child: CircularProgressIndicator(color: AppColors.green)),
                      )
                    else if (primary == null)
                      const EmptyNote('Belum ada alamat tersimpan.')
                    else
                      FormCard(
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.greenSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.home_outlined,
                                  size: 18, color: AppColors.green),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(primary.label,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text(primary.oneLine,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            if (primary.isDefault) const Pill('Utama'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    const SectionTitle('Pengaturan akun'),
                    const SizedBox(height: 10),
                    _MenuGroup(children: [
                      _MenuItem(
                          icon: Icons.notifications_none,
                          title: 'Notifikasi',
                          subtitle: 'Pembaruan pesanan dan akun',
                          onTap: () => _push(const NotifikasiPage())),
                      _MenuItem(
                          icon: Icons.lock_outline,
                          title: 'Ganti Password',
                          subtitle: 'Perbarui kata sandi Anda',
                          onTap: () => _push(const GantiPasswordPage())),
                    ]),
                    const SizedBox(height: 18),
                    const SectionTitle('Bantuan & informasi'),
                    const SizedBox(height: 10),
                    _MenuGroup(children: [
                      _MenuItem(
                          icon: Icons.headset_mic_outlined,
                          title: 'Pusat bantuan',
                          subtitle: 'Chat dengan tim KomporCare',
                          onTap: _openHelp),
                      _MenuItem(
                          icon: Icons.shield_outlined,
                          title: 'Kebijakan privasi',
                          subtitle: 'Cara kami menjaga data Anda',
                          onTap: () => _push(InfoPage.privacy())),
                      _MenuItem(
                          icon: Icons.description_outlined,
                          title: 'Syarat & ketentuan',
                          subtitle: 'Aturan penggunaan layanan',
                          onTap: () => _push(InfoPage.terms())),
                    ]),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Keluar dari akun'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const DemoFooter('KomporCare v1.0.0 • Akun pelanggan'),
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

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              children[i],
            ],
          ],
        ),
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
