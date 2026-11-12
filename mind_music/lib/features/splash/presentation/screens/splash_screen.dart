import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _stageTimer;
  double _progress = 0.0;
  int _currentStageIndex = 0;
  bool _isNavigated = false;

  final List<Map<String, String>> _stages = [
    {
      'title': 'Initialisation du moteur audio...',
      'sub': 'Configuration des codecs 24-bit Flac',
    },
    {
      'title': 'Indexation des fichiers lossless...',
      'sub': 'Vérification des répertoires de stockage',
    },
    {
      'title': 'Calibration Neural AI...',
      'sub': "Synchronisation du profil d'égalisation adaptatif",
    },
    {
      'title': 'Optimisation du tampon...',
      'sub': 'Latence ultra-faible prête',
    },
    {
      'title': 'Bienvenue sur MyPlayer !',
      'sub': 'Tous les systèmes sont opérationnels',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _startInitializationSequence();
  }

  void _startInitializationSequence() {
    const totalDurationMs = 1600;
    const intervalMs = 40;
    final increment = intervalMs / totalDurationMs;

    _stageTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress = (_progress + increment).clamp(0.0, 1.0);

        if (_progress < 0.28) {
          _currentStageIndex = 0;
        } else if (_progress < 0.64) {
          _currentStageIndex = 1;
        } else if (_progress < 0.92) {
          _currentStageIndex = 2;
        } else if (_progress < 1.0) {
          _currentStageIndex = 3;
        } else {
          _currentStageIndex = 4;
        }
      });

      if (_progress >= 1.0) {
        timer.cancel();
        _onInitializationComplete();
      }
    });
  }

  void _onInitializationComplete() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_isNavigated) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (_isNavigated) return;
    _isNavigated = true;
    _stageTimer?.cancel();

    final prefs = context.read<PreferencesService>();
    final targetScreen = prefs.isOnboarded
        ? const HomeDashboardScreen()
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, anim, secondaryAnim) => targetScreen,
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = _stages[_currentStageIndex];
    final remainingTime = ((1.0 - _progress) * 1.6).clamp(0.0, 1.6).toStringAsFixed(1);

    return Scaffold(
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.margin,
                  vertical: AppDimensions.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: AppColors.primaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MyPlayer Init',
                          style: AppTypography.labelMedium(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _navigateToNextScreen,
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLarge(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // Center Stage: Logo, Tagline, Feature Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                child: Column(
                  children: [
                    // Breathing Animated Logo Aura
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final scale = 1.0 + (_animController.value * 0.06);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(
                                    alpha: 0.25 + (_animController.value * 0.2),
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const AppLogo(size: 92),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Mind-Music',
                      style: AppTypography.displayLarge(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Media. Your AI. Your Way.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Feature Badges: Offline, Lossless, Neural AI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeaturePill(Icons.wifi_off, 'Offline 100%'),
                        const SizedBox(width: 8),
                        _buildFeaturePill(Icons.graphic_eq, 'Lossless 24b'),
                        const SizedBox(width: 8),
                        _buildFeaturePill(Icons.psychology, 'Neural AI'),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Progress & Control Pod
              Padding(
                padding: const EdgeInsets.all(AppDimensions.margin),
                child: GlassContainer(
                  elevation: GlassElevation.level2,
                  padding: const EdgeInsets.all(AppDimensions.spaceLg),
                  borderRadius: AppDimensions.borderLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              currentStage['title']!,
                              style: AppTypography.titleMedium(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: AppTypography.titleMedium(
                              color: AppColors.primaryContainer,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              currentStage['sub']!,
                              style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${remainingTime}s',
                            style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Refractive Glowing Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            FractionallySizedBox(
                              widthFactor: _progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: AppColors.aiVioletCyanGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          label: "Entrer dans l'expérience",
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          variant: GlassButtonVariant.primary,
                          onPressed: _navigateToNextScreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            context.read<StorageScannerService>().scanDeviceStorage();
                            _navigateToNextScreen();
                          },
                          child: Text(
                            'Already configured? Skip to player',
                            style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: AppDimensions.borderFull,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryContainer),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.labelSmall(color: AppColors.onSurfaceSecondary),
          ),
        ],
      ),
    );
  }
}
