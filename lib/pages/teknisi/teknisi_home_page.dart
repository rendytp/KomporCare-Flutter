import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Beranda Teknisi (placeholder, akan diisi: tugas servis, status kerja).
class TeknisiHomePage extends StatelessWidget {
  const TeknisiHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(demoText: 'Beranda Teknisi'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${user?.fullName ?? 'Teknisi'}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Halaman beranda teknisi akan dibuat di sini.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService.instance.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (_) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Keluar'),
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
