import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import 'akun_page.dart';
import 'beranda_page.dart';
import 'pesan_page.dart';
import 'pesanan_page.dart';

/// Kerangka halaman Pelanggan: bottom navigation (Layanan, Pesanan, Pesan, Akun).
/// Setiap tab memakai Navigator sendiri supaya halaman turunannya (Cari Layanan,
/// Chat, Ubah profil, Kelola alamat, dst.) tetap menampilkan bottom navigation
/// seperti pada desain.
class PelangganShell extends StatefulWidget {
  const PelangganShell({super.key});

  @override
  State<PelangganShell> createState() => _PelangganShellState();
}

class _PelangganShellState extends State<PelangganShell> {
  int _index = 0;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  // Dinaikkan setiap tab dibuka agar datanya dimuat ulang.
  final _berandaRefresh = ValueNotifier<int>(0);
  final _pesananRefresh = ValueNotifier<int>(0);
  final _pesanRefresh = ValueNotifier<int>(0);
  final _akunRefresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _berandaRefresh.dispose();
    _pesananRefresh.dispose();
    _pesanRefresh.dispose();
    _akunRefresh.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) {
      // ketuk tab aktif lagi -> kembali ke halaman awal tab itu
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
    switch (i) {
      case 0:
        _berandaRefresh.value++;
      case 1:
        _pesananRefresh.value++;
      case 2:
        _pesanRefresh.value++;
      case 3:
        _akunRefresh.value++;
    }
  }

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (_index != 0) {
      setState(() => _index = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  Widget _tab(int i, WidgetBuilder root) => Navigator(
        key: _navKeys[i],
        onGenerateRoute: (_) => MaterialPageRoute(builder: root),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _tab(0, (_) => BerandaPage(
                  onOpenPesanan: () => _select(1),
                  refresh: _berandaRefresh,
                )),
            _tab(1, (_) => PesananPage(refresh: _pesananRefresh)),
            _tab(2, (_) => PesanPage(refresh: _pesanRefresh)),
            _tab(3, (_) => AkunPage(refresh: _akunRefresh)),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: _select,
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
