import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';

class SiteHeader extends StatefulWidget {
  const SiteHeader({super.key});

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;

    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      MockData.siteName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _menuOpen = !_menuOpen),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(_menuOpen ? Icons.close : Icons.menu),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _NavLink(label: 'Home', path: '/', current: current),
                  _NavLink(label: 'Forums', path: '/forums', current: current),
                  _NavLink(
                    label: 'Articles',
                    path: '/articles',
                    current: current,
                  ),
                  _NavLink(label: 'Search', path: '/search', current: current),
                ],
              ),
            ),
            crossFadeState: _menuOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.path,
    required this.current,
  });

  final String label;
  final String path;
  final String current;

  @override
  Widget build(BuildContext context) {
    final active = current == path || (path != '/' && current.startsWith(path));

    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: active ? AppColors.navy : AppColors.muted,
        backgroundColor: active
            ? AppColors.surfaceSoft
            : Colors.white.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
