import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/page_parts.dart';

/// Halaman teks statis (Kebijakan privasi, Syarat & ketentuan).
class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  factory InfoPage.privacy() => const InfoPage(
        title: 'Kebijakan privasi',
        sections: [
          ('Data yang kami simpan',
              'Nama, nomor telepon, email, alamat servis, dan riwayat pesanan Anda.'),
          ('Penggunaan data',
              'Data dipakai untuk memproses pesanan, menghubungkan Anda dengan teknisi, dan memberi bantuan.'),
          ('Keamanan',
              'Kata sandi disimpan dalam bentuk terenkripsi. KomporCare tidak pernah meminta OTP atau kata sandi Anda.'),
        ],
      );

  factory InfoPage.terms() => const InfoPage(
        title: 'Syarat & ketentuan',
        sections: [
          ('Layanan',
              'KomporCare menghubungkan pelanggan dengan teknisi servis kompor gas panggilan.'),
          ('Biaya',
              'Biaya mengikuti tarif layanan dan persetujuan Anda setelah diagnosis oleh teknisi.'),
          ('Pembatalan',
              'Pesanan dapat dibatalkan sebelum teknisi berangkat. Hubungi Bantuan KomporCare untuk kendala lain.'),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(title: title, subtitle: 'KomporCare'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final s in sections) ...[
                    FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(s.$2,
                              style: const TextStyle(
                                  fontSize: 12, height: 1.4, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
