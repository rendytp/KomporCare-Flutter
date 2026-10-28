import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import 'beranda_page.dart';

/// Kerangka halaman Pelanggan: bottom navigation (Layanan, Pesanan, Pesan, Akun).
/// Tab "Layanan" memakai Navigator sendiri supaya halaman Cari Layanan tetap
/// menampilkan bottom navigation seperti pada desain.
class PelangganShell extends StatefulWidget {
  const PelangganShell({super.key});

  @override
  State<PelangganShell> createState() => _PelangganShellState();
}

class _PelangganShellState extends State<PelangganShell> {
  int _index = 0;
  final _layananNav = GlobalKey<NavigatorState>();

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    final nav = _layananNav.currentState;
    if (_index == 0 && nav != null && nav.canPop()) {
      nav.pop();
    } else if (_index != 0) {
      setState(() => _index = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            Navigator(
              key: _layananNav,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => BerandaPage(
                  onOpenPesanan: () => setState(() => _index = 1),
                ),
              ),
            ),
            const _SoonTab(icon: Icons.receipt_long_outlined, title: 'Pesanan'),
            const _SoonTab(icon: Icons.chat_bubble_outline, title: 'Pesan'),
            const _AkunTab(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            elevation: 0,
            selectedItemColor: AppColors.green,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Layanan'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Pesanan'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Pesan'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Akun'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoonTab extends StatelessWidget {
  const _SoonTab({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.greenBorder),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Halaman ini akan segera hadir.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _AkunTab extends StatelessWidget {
  const _AkunTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Akun',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.fullName ?? 'Pelanggan',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(user?.email ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(user?.phone ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
