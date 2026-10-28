import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/chat.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

/// Chat pelanggan. Dipakai untuk "Chat Teknisi" dan "Chat CS" (dibedakan oleh `type`).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ConversationDetail? _detail;
  List<ChatMessage> _messages = [];
  String? _error;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(first: true);
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    try {
      final d = await PelangganApi.instance.conversation(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _messages = d.messages;
        _error = null;
        _loading = false;
      });
      _toBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// Polling ringan: hanya ganti daftar pesan bila ada pesan baru.
  Future<void> _refresh() async {
    if (_detail == null || _sending) return;
    try {
      final d = await PelangganApi.instance.conversation(widget.conversationId);
      if (!mounted) return;
      final changed = d.messages.length != _messages.length ||
          (d.messages.isNotEmpty &&
              _messages.isNotEmpty &&
              d.messages.last.id != _messages.last.id);
      if (changed) {
        setState(() => _messages = d.messages);
        _toBottom();
      }
    } catch (_) {
      // polling gagal diabaikan; akan dicoba lagi
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await PelangganApi.instance.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      _input.clear();
      setState(() => _messages = [..._messages, m]);
      _toBottom();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _call(String? phone) {
    if (phone == null || phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    showSnack(context, 'Nomor $phone disalin.');
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(detail: d, onCall: () => _call(d?.phone)),
            RoleBanner(d?.isSupport == true
                ? 'PELANGGAN • Chat CS'
                : 'PELANGGAN • Chat Teknisi'),
            Expanded(child: _body()),
            if (d != null) _Composer(
              controller: _input,
              sending: _sending,
              onSend: _send,
              onAttach: () => showSnack(context, 'Lampiran akan segera hadir.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null || _detail == null) {
      return ErrorRetry(
        message: _error ?? 'Gagal memuat percakapan.',
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _load();
        },
      );
    }

    final d = _detail!;
    final children = <Widget>[];

    if (d.isSupport) {
      children.add(const _SupportCard());
    } else if (d.order != null) {
      children.add(_OrderCard(order: d.order!));
    }

    DateTime? lastDay;
    for (final m in _messages) {
      if (lastDay == null || !sameDay(lastDay, m.createdAt)) {
        children.add(_DayDivider(tanggalChat(m.createdAt)));
        lastDay = m.createdAt;
      }
      children.add(_Bubble(message: m));
    }

    children.add(const SizedBox(height: 8));
    children.add(InfoBox(
      title: d.isSupport ? 'Tetap aman saat berkomunikasi' : 'Pembayaran setelah servis',
      child: Text(d.isSupport
          ? 'Tim KomporCare tidak pernah meminta OTP atau kata sandi Anda.'
          : 'Bayar setelah servis selesai, sesuai metode yang Anda pilih pada pesanan.'),
    ));

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      children: children,
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.detail, required this.onCall});
  final ConversationDetail? detail;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final support = d?.isSupport ?? false;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Initials(d?.title ?? '?',
              radius: 18, icon: support ? Icons.headset_mic_outlined : null),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d?.title ?? 'Memuat...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text(d?.subtitle ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!support && (d?.phone ?? '').isNotEmpty)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.green),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final ChatOrderInfo order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FormCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.orderCode,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ),
                OrderStatusPill(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.serviceName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(jadwalLabel(order.scheduledAt, order.durationMin),
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Estimasi ${rupiah(order.totalPrice)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: FormCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Kami siap membantu',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                Pill('CS aktif'),
              ],
            ),
            SizedBox(height: 4),
            Text(
                'Bantuan pesanan, pembayaran, atau akun. Jam operasional 08.00–21.00 WIB.',
                style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(text,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 6),
        decoration: BoxDecoration(
          color: mine ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 3),
            bottomRight: Radius.circular(mine ? 3 : 14),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(message.body,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: mine ? Colors.white : AppColors.text)),
            ),
            const SizedBox(height: 3),
            Text(jamLabel(message.createdAt),
                style: TextStyle(
                    fontSize: 9.5,
                    color: mine ? Colors.white70 : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttach,
            icon: const Icon(Icons.attach_file, size: 20, color: AppColors.textMuted),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Tulis pesan...',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: sending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
