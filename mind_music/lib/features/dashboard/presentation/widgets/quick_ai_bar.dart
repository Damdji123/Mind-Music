import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/glass_text_field.dart';

class QuickAiBar extends StatelessWidget {
  final ValueChanged<String>? onCommandSubmitted;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onOpenAssistant;

  const QuickAiBar({
    super.key,
    this.onCommandSubmitted,
    this.onVoiceTap,
    this.onOpenAssistant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.secondaryHighlight,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI COPILOT',
                  style: AppTypography.labelSmall(
                    color: AppColors.secondaryHighlight,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: AppDimensions.borderFull,
                  border: Border.all(
                    color: AppColors.secondaryHighlight.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Offline Neural Engine',
                        style: AppTypography.labelSmall(color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassTextField(
          hintText: 'Ask me anything ("Play chill playlist", "Sleep timer 45m")...',
          leading: const Icon(
            Icons.smart_toy_outlined,
            color: AppColors.secondaryHighlight,
            size: 20,
          ),
          onSubmitted: onCommandSubmitted,
          onVoicePressed: onVoiceTap,
          onTap: onOpenAssistant,
        ),
        const SizedBox(height: 10),
        // Suggestion Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildSuggestionChip(
                context,
                icon: Icons.play_circle_outline,
                label: '"Play chill playlist"',
              ),
              const SizedBox(width: 8),
              _buildSuggestionChip(
                context,
                icon: Icons.playlist_add,
                label: '"Create mix"',
              ),
              const SizedBox(width: 8),
              _buildSuggestionChip(
                context,
                icon: Icons.bedtime_outlined,
                label: '"Sleep timer 45m"',
              ),
              const SizedBox(width: 8),
              _buildSuggestionChip(
                context,
                icon: Icons.graphic_eq,
                label: '"Bass boost EQ"',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppDimensions.borderFull,
        onTap: () {
          final cleanQuery = label.replaceAll('"', '');
          onCommandSubmitted?.call(cleanQuery);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: AppDimensions.borderFull,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall(color: AppColors.onSurfaceSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
