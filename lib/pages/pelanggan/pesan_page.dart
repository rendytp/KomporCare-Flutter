import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/chat.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';
import 'chat_page.dart';

/// Tab "Pesan": daftar percakapan dengan teknisi dan Bantuan KomporCare.
class PesanPage extends StatefulWidget {
  const PesanPage({super.key, required this.refresh});

  final ValueNotifier<int> refresh;

  @override
  State<PesanPage> createState() => _PesanPageState();
}

class _PesanPageState extends State<PesanPage> {
  List<ConversationSummary>? _all;
  String? _error;
  bool _loading = true;
  bool _onlyUnread = false;
  String _query = '';
  bool _openingSupport = false;

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
      final list = await PelangganApi.instance.conversations();
      if (!mounted) return;
      setState(() {
        _all = list;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_all != null) showSnack(context, e.message, error: true);
      setState(() {
        _error = _all == null ? e.message : null;
        _loading = false;
      });
    }
  }

  Future<void> _open(int id) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatPage(conversationId: id),
    ));
    if (mounted) _load();
  }

  Future<void> _openSupport() async {
    setState(() => _openingSupport = true);
    try {
      final id = await PelangganApi.instance.openSupportChat();
      if (!mounted) return;
      await _open(id);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _openingSupport = false);
    }
  }

  List<ConversationSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    return (_all ?? []).where((c) {
      if (_onlyUnread && c.unread == 0) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          (c.orderCode ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TabHeader(
              title: 'Pesan',
              subtitle: 'Percakapan dengan teknisi dan Bantuan KomporCare',
            ),
            const RoleBanner('PELANGGAN • Percakapan diambil dari database'),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null || _all == null) {
      return ErrorRetry(
        message: _error ?? 'Gagal memuat pesan.',
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _load();
        },
      );
    }

    final unread = _all!.fold<int>(0, (s, c) => s + c.unread);
    final items = _filtered;
    final hasSupport = _all!.any((c) => c.isSupport);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau nomor pesanan',
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                  label: 'Semua',
                  on: !_onlyUnread,
                  onTap: () => setState(() => _onlyUnread = false)),
              const SizedBox(width: 8),
              _Chip(
                  label: 'Belum dibaca ($unread)',
                  on: _onlyUnread,
                  onTap: () => setState(() => _onlyUnread = true)),
            ],
          ),
          const SizedBox(height: 16),
          SectionTitle('Percakapan Anda', trailing: '${items.length} percakapan'),
          const SizedBox(height: 10),
          if (items.isEmpty)
            EmptyNote(_query.isNotEmpty || _onlyUnread
                ? 'Tidak ada percakapan yang cocok.'
                : 'Belum ada percakapan. Chat dengan teknisi dapat dibuka dari halaman Pesanan.')
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    _ConversationTile(item: items[i], onTap: () => _open(items[i].id)),
                  ],
                ],
              ),
            ),
          if (!hasSupport) ...[
            const SizedBox(height: 10),
            SmallButton(
              label: _openingSupport ? 'Membuka...' : 'Hubungi Bantuan KomporCare',
              icon: Icons.support_agent,
              filled: false,
              onPressed: _openingSupport ? null : _openSupport,
            ),
          ],
          const SizedBox(height: 14),
          const InfoBox(
            title: 'Tetap aman saat berkomunikasi',
            child: Text(
                'Jangan bagikan kode OTP atau kata sandi kepada siapa pun, termasuk yang mengaku dari KomporCare.'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppColors.green : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : AppColors.text)),
        ),
      );
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});
  final ConversationSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item.unread > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Initials(item.title,
                radius: 20, icon: item.isSupport ? Icons.headset_mic_outlined : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      Text(waktuSingkat(item.lastAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.lastMessage ?? 'Belum ada pesan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: unread ? FontWeight.w600 : FontWeight.w400)),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: AppColors.green, shape: BoxShape.circle),
                          child: Text('${item.unread}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
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
