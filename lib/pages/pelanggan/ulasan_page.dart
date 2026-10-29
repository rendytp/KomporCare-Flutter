import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/alur_servis.dart';
import '../../services/customer_api.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

/// "Bagaimana servisnya?": bintang, label, komentar. Hanya setelah pesanan selesai.
class UlasanPage extends StatefulWidget {
  const UlasanPage({super.key, required this.orderCode});

  final String orderCode;

  @override
  State<UlasanPage> createState() => _UlasanPageState();
}

class _UlasanPageState extends State<UlasanPage> {
  static const _ratingLabel = {
    1: 'Sangat kurang',
    2: 'Kurang',
    3: 'Cukup',
    4: 'Puas',
    5: 'Sangat puas',
  };

  final _comment = TextEditingController();
  ReviewInfo? _info;
  String? _error;
  int _rating = 5;
  final _tags = <String>{};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final i = await PelangganApi.instance.reviewInfo(widget.orderCode);
      if (!mounted) return;
      setState(() {
        _info = i;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await PelangganApi.instance.submitReview(
        widget.orderCode,
        rating: _rating,
        tags: _tags.toList(),
        comment: _comment.text,
      );
      if (!mounted) return;
      showSnack(context, 'Terima kasih atas ulasan Anda.');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Bagaimana servisnya?',
              subtitle: i?.completedAt != null
                  ? '${widget.orderCode} • ${tanggalLengkap(i!.completedAt!)}'
                  : widget.orderCode,
            ),
            const RoleBanner('PELANGGAN • Ulasan setelah servis'),
            Expanded(child: _body(i)),
          ],
        ),
      ),
    );
  }

  Widget _body(ReviewInfo? i) {
    if (i == null) {
      return _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final name = i.technicianName ?? 'teknisi';
    final first = name.split(' ').first;
    final readOnly = !i.canReview;
    final shownRating = readOnly ? (i.rating ?? 0) : _rating;
    final shownTags = readOnly ? i.tags.toSet() : _tags;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        FormCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.check, size: 26, color: AppColors.green),
              ),
              const SizedBox(height: 10),
              const Text('Kompor kembali siap dipakai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  '${i.serviceName} • Total ${rupiah(i.totalPrice)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FormCard(
          child: Row(
            children: [
              Initials(name, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(i.serviceName,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Pill('Selesai'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
              readOnly ? 'Ulasan Anda untuk $first' : 'Beri nilai untuk $first',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var s = 1; s <= 5; s++)
              GestureDetector(
                onTap: readOnly ? null : () => setState(() => _rating = s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(s <= shownRating ? Icons.star : Icons.star_border,
                      size: 38, color: AppColors.green),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
              shownRating == 0 ? '' : '$shownRating dari 5 • ${_ratingLabel[shownRating]}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 18),
        const Text('Apa yang paling membantu?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in i.availableTags)
              _TagChip(
                label: t,
                selected: shownTags.contains(t),
                onTap: readOnly
                    ? null
                    : () => setState(() {
                          if (!_tags.remove(t)) _tags.add(t);
                        }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Ceritakan pengalaman Anda',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (readOnly)
          FormCard(
            child: Text(
                (i.comment == null || i.comment!.isEmpty) ? 'Tidak ada komentar.' : i.comment!,
                style: const TextStyle(fontSize: 12, height: 1.4)),
          )
        else ...[
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Contoh: teknisi datang sesuai estimasi dan menjelaskan biaya dengan jelas.',
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => showSnack(context, 'Unggah foto akan segera hadir.'),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Tambahkan foto hasil servis (opsional)',
                style: TextStyle(fontSize: 11.5)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (readOnly)
          const InfoBox(
              title: 'Terima kasih',
              child: Text('Ulasan Anda membantu kami memilih teknisi terbaik untuk pelanggan lain.'))
        else ...[
          const InfoBox(
              child: Text(
                  'Ulasan memengaruhi rating teknisi dan pencocokan pesanan berikutnya.')),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Kirim ulasan',
            icon: Icons.send,
            loading: _sending,
            onPressed: _submit,
          ),
          Center(
            child: TextButton(
              onPressed: _sending
                  ? null
                  : () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Lewati untuk sekarang',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.green : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 13, color: AppColors.green),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.green : AppColors.text)),
            ],
          ),
        ),
      );
}
