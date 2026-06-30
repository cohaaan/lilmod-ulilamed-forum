import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

String forumLink(String path) => '${AppConfig.siteUrl}$path';

/// Copies a deep link to the clipboard and confirms with a snackbar.
Future<void> copyForumLink(
  BuildContext context,
  String path, {
  String label = 'Link copied',
}) async {
  final link = forumLink(path);
  await Clipboard.setData(ClipboardData(text: link));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.link_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label · $link',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
}
