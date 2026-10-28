import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'common.dart';

/// Header tab: ikon merek + judul + subjudul, opsional tombol lonceng.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBell,
    this.showDot = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBell;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (onBell != null)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onBell,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_none, size: 18),
                    if (showDot)
                      Positioned(
                        top: 7,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header halaman dalam (ada tombol kembali): "Ubah profil", "Kelola alamat", dst.
class SubHeader extends StatelessWidget {
  const SubHeader({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Pita hijau muda tipis di bawah header.
class RoleBanner extends StatelessWidget {
  const RoleBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.greenSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class Initials extends StatelessWidget {
  const Initials(this.name, {super.key, this.radius = 20, this.icon});

  final String name;
  final double radius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greenSoft,
      child: icon != null
          ? Icon(icon, size: radius, color: AppColors.green)
          : Text(initials(name),
              style: TextStyle(
                  fontSize: radius * 0.62,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green)),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.green, this.background});

  final String text;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? AppColors.greenSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Pill status pesanan: hijau untuk berjalan/selesai, merah untuk dibatalkan.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Pill(orderStatusLabel(status),
          color: AppColors.error, background: const Color(0xFFFBE9E6));
    }
    if (status == 'waiting_payment' || status == 'pending') {
      return Pill(orderStatusLabel(status),
          color: const Color(0xFF8A5A00), background: const Color(0xFFFFF1D6));
    }
    return Pill(orderStatusLabel(status));
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.action, this.onAction});

  final String title;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        if (trailing != null)
          Text(trailing!,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
          ),
      ],
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => FormCard(
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
}

/// Tombol isi hijau kecil (ikon + label) dan versi outline, dipakai pada kartu.
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : (danger ? AppColors.error : AppColors.text);
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return SizedBox(
      height: 40,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: shape),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: shape),
              child: child,
            ),
    );
  }
}
