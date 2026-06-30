import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Wraps a [Future] with consistent loading, error (+retry) and data states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.loadingHeight = 220,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FillHeight(
            minHeight: loadingHeight,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        if (snapshot.hasError) {
          return _FillHeight(
            minHeight: loadingHeight,
            child: Center(
              child: _ErrorState(onRetry: onRetry, error: snapshot.error),
            ),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Expands to at least [minHeight] or the viewport, and stays scrollable for
/// [RefreshIndicator] parents.
class _FillHeight extends StatelessWidget {
  const _FillHeight({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight > minHeight
            ? constraints.maxHeight
            : minHeight;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: child,
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.onRetry, this.error});

  final VoidCallback? onRetry;
  final Object? error;

  String get _message {
    final text = error.toString();
    if (text.contains('PGRST205') || text.contains('chavrusa_listings')) {
      return 'This feature is not set up in the database yet. '
          'Run the chavrusas migration in Supabase, then retry.';
    }
    return "Couldn't load this. Check your connection.";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.indigo,
                side: BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
