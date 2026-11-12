import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../services/ads_service.dart';
import '../services/subscription_service.dart';

class PremiumBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subService = context.watch<SubscriptionService>();
    final isPremium = subService.isPremium;

    return GestureDetector(
      onTap: onTap ?? () => _showSubscriptionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.borderFull,
          gradient: const LinearGradient(
            colors: [
              Color(0x33F59E0B),
              Color(0x1AF59E0B),
            ],
          ),
          border: Border.all(
            color: isPremium
                ? AppColors.tertiaryContainer
                : AppColors.tertiaryContainer.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiaryContainer.withValues(alpha: isPremium ? 0.35 : 0.15),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium,
              color: AppColors.tertiaryContainer,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isPremium ? 'PRO ACTIVE' : 'PREMIUM',
              style: AppTypography.labelSmall(
                color: AppColors.tertiary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _SubscriptionModalSheet(),
    );
  }
}

class _SubscriptionModalSheet extends StatelessWidget {
  const _SubscriptionModalSheet();

  @override
  Widget build(BuildContext context) {
    final subService = context.watch<SubscriptionService>();
    final adsService = context.read<AdsService>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(AppDimensions.spaceXl),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
            border: Border.all(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.workspace_premium,
                  color: AppColors.tertiaryContainer,
                  size: 52,
                ),
                const SizedBox(height: 8),
                Text(
                  'MYPLAYER PREMIUM',
                  style: AppTypography.headlineMedium(color: AppColors.tertiary).copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upgrade your music & video journey with an intelligent offline assistant.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Benefits strictly quoted from Music player.docx
                _buildBenefitRow(Icons.block, '🚫 Remove all ads across the entire app'),
                _buildBenefitRow(Icons.smart_toy, '🤖 Advanced AI commands & multi-step execution'),
                _buildBenefitRow(Icons.queue_music, '🎶 Dynamic AI playlist generation'),
                _buildBenefitRow(Icons.folder_special, '🧠 AI library organization & Smart folders'),
                _buildBenefitRow(Icons.mic, '🎤 Extended voice commands & natural speech triggers'),
                _buildBenefitRow(Icons.palette, '🎨 Advanced themes (OLED, Cyberpunk, Sunset)'),
                _buildBenefitRow(Icons.bedtime, '🌙 Advanced sleep sessions with gentle fade-out'),
                _buildBenefitRow(Icons.graphic_eq, '🔊 32-bit Hi-Res audio DSP & custom EQ presets'),

                const SizedBox(height: 24),

                if (!subService.isPremium) ...[
                  // Pricing Option 1: Lifetime (Recommended in Document)
                  _buildPricingCard(
                    context,
                    title: 'Lifetime Access (Best Value)',
                    price: '\$24.99',
                    subtitle: 'Pay once, enjoy forever • One-time purchase utility',
                    isHighlight: true,
                    onTap: () {
                      subService.upgradeToPremium(tier: SubscriptionTier.lifetime);
                      Navigator.pop(context);
                      _showSuccessToast(context, 'Lifetime PRO Activated! Zero ads forever.');
                    },
                  ),
                  const SizedBox(height: 10),

                  // Pricing Option 2: Yearly Subscription ($10.99/yr)
                  _buildPricingCard(
                    context,
                    title: 'Premium Yearly',
                    price: '\$10.99 / year',
                    subtitle: 'Save 54% • Auto-renewing subscription',
                    onTap: () {
                      subService.upgradeToPremium(tier: SubscriptionTier.premiumYearly);
                      Navigator.pop(context);
                      _showSuccessToast(context, 'Yearly PRO Activated! Enjoy ad-free listening.');
                    },
                  ),
                  const SizedBox(height: 10),

                  // Pricing Option 3: Monthly Subscription ($1.99/mo)
                  _buildPricingCard(
                    context,
                    title: 'Premium Monthly',
                    price: '\$1.99 / month',
                    subtitle: 'Flexible monthly subscription • Cancel anytime',
                    onTap: () {
                      subService.upgradeToPremium(tier: SubscriptionTier.premiumMonthly);
                      Navigator.pop(context);
                      _showSuccessToast(context, 'Monthly PRO Activated!');
                    },
                  ),
                  const SizedBox(height: 18),

                  // Rewarded Ad Option from Document: "Need an extra AI request? Watch a short ad"
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                      borderRadius: AppDimensions.borderDefault,
                      border: Border.all(
                        color: AppColors.secondaryHighlight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ondemand_video,
                          color: AppColors.secondaryHighlight,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need an extra AI request?',
                                style: AppTypography.titleMedium(color: AppColors.onSurface),
                              ),
                              Text(
                                'Watch a short advertisement to earn +3 free AI credits.',
                                style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            adsService.showRewardedAdForAiCredits(
                              onRewardEarned: (bonus) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Rewarded Ad watched! +$bonus AI credits added.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                            );
                          },
                          child: Text(
                            'Watch Ad',
                            style: AppTypography.labelLarge(color: AppColors.secondaryHighlight),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Continue with Free Tier (Tasteful Ads)',
                      style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: AppDimensions.borderDefault,
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRO Subscription Active',
                                style: AppTypography.titleMedium(color: AppColors.success),
                              ),
                              Text(
                                'Zero ads, unlimited AI copilot, and lossless Hi-Res DSP are unlocked.',
                                style: AppTypography.bodySmall(color: AppColors.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      subService.revertToFree();
                      Navigator.pop(context);
                    },
                    child: const Text('Revert to Free Tier (For Testing)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    bool isHighlight = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppDimensions.borderDefault,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: AppDimensions.borderDefault,
            color: isHighlight
                ? AppColors.tertiaryContainer.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isHighlight
                  ? AppColors.tertiaryContainer
                  : Colors.white.withValues(alpha: 0.15),
              width: isHighlight ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium(
                        color: isHighlight ? AppColors.tertiary : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppTypography.headlineSmall(
                  color: isHighlight ? AppColors.tertiary : AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 $message'),
        backgroundColor: AppColors.tertiaryContainer,
      ),
    );
  }
}
