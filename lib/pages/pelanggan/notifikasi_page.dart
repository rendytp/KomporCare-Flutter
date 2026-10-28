import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/akun.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<AppNotification>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await PelangganApi.instance.notifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(title: 'Notifikasi', subtitle: 'Pembaruan pesanan dan akun'),
            Expanded(
              child: _error != null
                  ? ErrorRetry(message: _error!, onRetry: _load)
                  : _items == null
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.green))
                      : RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_items!.isEmpty) const EmptyNote('Belum ada notifikasi.'),
                              for (final n in _items!) ...[
                                FormCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 3),
                                      Text(n.message,
                                          style: const TextStyle(fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 6),
                                      Text(
                                          '${tanggalLengkap(n.createdAt)} • ${jamLabel(n.createdAt)}',
                                          style: const TextStyle(
                                              fontSize: 10, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
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
