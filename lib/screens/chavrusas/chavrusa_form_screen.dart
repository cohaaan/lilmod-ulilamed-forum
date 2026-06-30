import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/chavrusa_listing.dart';
import '../../theme/chavrusa_directory_theme.dart';
import '../../widgets/chavrusa/chavrusa_post_form.dart';

/// Full-screen post/edit route (mobile and deep links).
class ChavrusaFormScreen extends StatelessWidget {
  const ChavrusaFormScreen({super.key, this.existing});

  final ChavrusaListing? existing;

  @override
  Widget build(BuildContext context) {
    final existing = this.existing ?? GoRouterState.of(context).extra as ChavrusaListing?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ChavrusaDirectoryTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          existing == null ? 'Post availability' : 'Edit availability',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: ChavrusaPostForm(
          existing: existing,
          onCancel: () => context.pop(),
          onSaved: () => context.pop(true),
        ),
      ),
    );
  }
}
