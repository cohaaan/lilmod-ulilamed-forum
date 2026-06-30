import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/design_direction.dart';
import '../theme/design_direction_controller.dart';
import '../theme/design_directions.dart';
import '../widgets/design_direction_mockup.dart';

/// Scrollable gallery of all 10 enterprise design directions with live mockups.
class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  @override
  void initState() {
    super.initState();
    designDirectionController.addListener(_onDirectionChanged);
  }

  @override
  void dispose() {
    designDirectionController.removeListener(_onDirectionChanged);
    super.dispose();
  }

  void _onDirectionChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final activeId = designDirectionController.active.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Design directions'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: DesignDirections.all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final direction = DesignDirections.all[index];
          final isActive = direction.id == activeId;
          return _DirectionCard(
            direction: direction,
            isActive: isActive,
            onApply: () async {
              await designDirectionController.apply(direction);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Applied "${direction.name}" theme'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.direction,
    required this.isActive,
    required this.onApply,
  });

  final DesignDirection direction;
  final bool isActive;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final traits = <String>[
      'Radius ${direction.cornerRadius.round()}px',
      direction.useShadow ? 'Shadow' : 'Flat',
      direction.useBorder ? 'Borders' : 'Borderless',
      direction.pillTags ? 'Pill tags' : 'Rect tags',
      _densityLabel(direction.density),
      _typographyLabel(direction.typography),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.line,
          width: isActive ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        direction.name,
                        style: AppText.section,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppText.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  direction.concept,
                  style: AppText.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  'Evokes: ${direction.evokes}',
                  style: AppText.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(child: DesignDirectionMockup(direction: direction)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DesignPaletteStrip(direction: direction),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in traits) _TraitChip(label: t),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: isActive ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: direction.primary,
                disabledBackgroundColor: AppColors.surfaceMuted,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(direction.cornerRadius),
                ),
              ),
              child: Text(
                isActive ? 'Currently applied' : 'Apply theme',
                style: AppText.label.copyWith(
                  color: isActive ? AppColors.muted : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _densityLabel(double d) {
    if (d < 0.95) return 'Compact';
    if (d > 1.05) return 'Airy';
    return 'Standard density';
  }

  String _typographyLabel(DesignTypography t) {
    return switch (t) {
      DesignTypography.inter => 'Inter sans',
      DesignTypography.lato => 'Lato sans',
      DesignTypography.serif => 'Serif headlines',
      DesignTypography.mono => 'IBM Plex',
      DesignTypography.system => 'System UI',
    };
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(fontSize: 10),
      ),
    );
  }
}
