import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../dashboard/presentation/screens/home_dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _permissionGranted = false;

  final int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = context.read<PreferencesService>();
    await prefs.setOnboarded(true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, anim, secondaryAnim) => const HomeDashboardScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Header with Step Counter & Skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.margin,
                  vertical: AppDimensions.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: AppDimensions.borderFull,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.secondaryHighlight,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Étape ${_currentPage + 1} sur $_totalPages',
                            style: AppTypography.labelSmall(
                              color: AppColors.onSurfaceSecondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Passer',
                        style: AppTypography.labelLarge(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // Carousel PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildSlide1Welcome(),
                    _buildSlide2LocalStorage(),
                    _buildSlide3AiVoice(),
                    _buildSlide4Themes(),
                  ],
                ),
              ),

              // Bottom Navigation & Indicators
              Padding(
                padding: const EdgeInsets.all(AppDimensions.margin),
                child: Column(
                  children: [
                    // Indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected
                                ? AppColors.primaryContainer
                                : Colors.white.withValues(alpha: 0.2),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Primary Button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: _currentPage == _totalPages - 1
                            ? 'Commencer l\'expérience'
                            : 'Continuer',
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        variant: _currentPage == _totalPages - 1
                            ? GlassButtonVariant.aiAccent
                            : GlassButtonVariant.primary,
                        onPressed: _onNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Slide 1: Welcome & Unified Multimedia ---
  Widget _buildSlide1Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.aiVioletCyanGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.headphones,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bienvenue sur\nMind-Music',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge(color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Votre musique, vos vidéos et votre copilote IA unifiés dans une bulle sonore transparente d’exception.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: 24),

          // Features Bento Row
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  elevation: GlassElevation.level1,
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  borderRadius: AppDimensions.borderMd,
                  child: Column(
                    children: [
                      const Icon(Icons.graphic_eq, color: AppColors.tertiary, size: 28),
                      const SizedBox(height: 8),
                      Text('FLAC Hi-Res', style: AppTypography.titleMedium()),
                      const SizedBox(height: 2),
                      Text('32-bit / 192kHz', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: GlassContainer(
                  elevation: GlassElevation.level1,
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  borderRadius: AppDimensions.borderMd,
                  child: Column(
                    children: [
                      const Icon(Icons.movie_outlined, color: AppColors.secondaryHighlight, size: 28),
                      const SizedBox(height: 8),
                      Text('4K HDR Video', style: AppTypography.titleMedium()),
                      const SizedBox(height: 2),
                      Text('Zéro latence', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Slide 2: Local Storage & Safe Permissions ---
  Widget _buildSlide2LocalStorage() {
    final scanner = context.watch<StorageScannerService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.folder_special_outlined,
              color: AppColors.primaryContainer,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lecture Locale\nSans Compromis',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge(color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Vos morceaux et vidéos hors-ligne organisés instantanément, sans aucune conversion nécessaire.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: 24),

          // Safe Permissions Request Card
          GlassContainer(
            elevation: GlassElevation.level2,
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            borderRadius: AppDimensions.borderLg,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _permissionGranted ? Icons.check_circle : Icons.lock_open_outlined,
                      color: _permissionGranted ? AppColors.success : AppColors.primaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _permissionGranted ? 'Accès Autorisé' : 'Accès aux fichiers médias',
                            style: AppTypography.titleMedium(color: AppColors.onSurface),
                          ),
                          Text(
                            _permissionGranted
                                ? 'Prêt à indexer ${scanner.audioFiles.length} fichiers'
                                : 'Nécessaire pour lire vos musiques et vidéos locales.',
                            style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: _permissionGranted ? AppColors.success : AppColors.primaryContainer,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.borderFull,
                      ),
                    ),
                    onPressed: () async {
                      final granted = await scanner.requestPermissions();
                      setState(() {
                        _permissionGranted = granted;
                      });
                      if (granted) {
                        scanner.scanDeviceStorage();
                      }
                    },
                    child: Text(
                      _permissionGranted ? '✓ Autorisation Accordée' : 'Autoriser l\'accès',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Slide 3: Voice & AI Natural Commands ---
  Widget _buildSlide3AiVoice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryHighlight.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.secondaryHighlight.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.mic_none,
              color: AppColors.secondaryHighlight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilotez Tout\nà la Voix',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge(color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Dites simplement ce que vous ressentez, votre copilote orchestre la file d’attente idéale.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: 24),

          // Voice Command Examples
          _buildVoiceChip(Icons.play_arrow, '"Joue ma playlist Chill."'),
          const SizedBox(height: 8),
          _buildVoiceChip(Icons.bedtime, '"Arrête la musique dans 45 minutes."'),
          const SizedBox(height: 8),
          _buildVoiceChip(Icons.playlist_add, '"Crée une playlist avec mes musiques d\'ambiance."'),
          const SizedBox(height: 8),
          _buildVoiceChip(Icons.palette, '"Change le thème en mode sombre."'),
        ],
      ),
    );
  }

  Widget _buildVoiceChip(IconData icon, String quote) {
    return GlassContainer(
      elevation: GlassElevation.level1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: AppDimensions.borderFull,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondaryHighlight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: AppTypography.bodyMedium(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // --- Slide 4: Aesthetic Themes & Customization ---
  Widget _buildSlide4Themes() {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.tertiaryContainer.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.palette_outlined,
              color: AppColors.tertiaryContainer,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Votre Style,\nVos Reflets',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge(color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Adaptez les transparences et halos lumineux à vos envies du moment.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceSecondary),
          ),
          const SizedBox(height: 24),

          // Theme Selector Grid
          Row(
            children: [
              Expanded(
                child: _buildThemeTile(
                  title: 'Liquid Glass',
                  icon: Icons.water_drop,
                  mode: AppThemeMode.liquidGlass,
                  currentMode: themeProvider.currentMode,
                  onTap: () => themeProvider.setTheme(AppThemeMode.liquidGlass),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: _buildThemeTile(
                  title: 'Ultra Noir',
                  icon: Icons.dark_mode,
                  mode: AppThemeMode.oledDark,
                  currentMode: themeProvider.currentMode,
                  onTap: () => themeProvider.setTheme(AppThemeMode.oledDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: _buildThemeTile(
                  title: 'Cyberpunk',
                  icon: Icons.electric_bolt,
                  mode: AppThemeMode.cyberpunk,
                  currentMode: themeProvider.currentMode,
                  onTap: () => themeProvider.setTheme(AppThemeMode.cyberpunk),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: _buildThemeTile(
                  title: 'Sunset Doré',
                  icon: Icons.wb_twilight,
                  mode: AppThemeMode.sunset,
                  currentMode: themeProvider.currentMode,
                  onTap: () => themeProvider.setTheme(AppThemeMode.sunset),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required String title,
    required IconData icon,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;

    return GlassContainer(
      elevation: isSelected ? GlassElevation.level2 : GlassElevation.level1,
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      borderRadius: AppDimensions.borderMd,
      hasSpecularBorder: true,
      customBorder: isSelected
          ? Border.all(color: AppColors.primaryContainer, width: 1.5)
          : null,
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.titleMedium(
              color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
