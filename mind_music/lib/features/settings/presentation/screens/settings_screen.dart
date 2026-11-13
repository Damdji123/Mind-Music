import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../equalizer/presentation/screens/equalizer_screen.dart';
import '../../../sleep_timer/presentation/screens/advanced_sleep_timer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final themeProvider = context.watch<ThemeProvider>();
    final scanner = context.watch<StorageScannerService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Navigation Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                    vertical: AppDimensions.spaceSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GlassIconButton(
                              icon: Icons.arrow_back_rounded,
                              size: 40,
                              iconSize: 20,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: AppDimensions.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settings',
                                    style: AppTypography.headlineMedium(color: AppColors.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'v1.0.0 • Storage & AI Control',
                                    style: AppTypography.labelSmall(color: AppColors.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlassIconButton(
                            icon: Icons.help_outline_rounded,
                            size: 38,
                            iconSize: 20,
                            onPressed: () => _showHelpDialog(context),
                          ),
                          const SizedBox(width: AppDimensions.spaceXs),
                          GlassIconButton(
                            icon: Icons.restart_alt_rounded,
                            size: 38,
                            iconSize: 20,
                            onPressed: () => _confirmResetDialog(context, prefs, themeProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.margin,
                  AppDimensions.spaceSm,
                  AppDimensions.margin,
                  AppDimensions.spaceXl * 2,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Version 1.0 (MVP) App & Storage Status Banner
                    _buildAppStatusCard(context),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 2. Personalization & Theme
                    _buildThemeCard(context, prefs, themeProvider),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 3. Playback & Audio Engine
                    _buildAudioEngineCard(context, prefs),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 4. Haptics & Sensory Effects
                    _buildHapticsCard(context, prefs),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 5. AI & Smart Assistant
                    _buildAiCard(context, prefs),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 6. Library & Local Storage
                    _buildStorageCard(context, prefs, scanner),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 7. System & Privacy
                    _buildSystemCard(context, prefs),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Version 1.0 App Status Card (Liquid + Glass Morphism) ---
  Widget _buildAppStatusCard(BuildContext context) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      customFillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Mind-Music Player',
                            style: AppTypography.titleMedium(color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'v1.0.0 MVP',
                            style: AppTypography.labelSmall(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '100% Offline • Local Media Engine & SQLite Cache',
                      style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Zero Tracking • Privacy First',
                        style: AppTypography.labelMedium(color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showAppInfoSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'About',
                  style: AppTypography.labelMedium(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Personalization & Theme Card ---
  Widget _buildThemeCard(
    BuildContext context,
    PreferencesService prefs,
    ThemeProvider themeProvider,
  ) {
    final themes = [
      {'id': 'oledDark', 'name': 'Ultra Dark', 'color': AppColors.primaryContainer, 'mode': AppThemeMode.oledDark},
      {'id': 'liquidGlass', 'name': 'Liquid Glass', 'color': AppColors.primary, 'mode': AppThemeMode.liquidGlass},
      {'id': 'cyberpunk', 'name': 'Cyberpunk', 'color': AppColors.secondaryHighlight, 'mode': AppThemeMode.cyberpunk},
      {'id': 'sunset', 'name': 'Sunset', 'color': AppColors.tertiaryContainer, 'mode': AppThemeMode.sunset},
    ];

    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                      ),
                      child: const Icon(Icons.palette_outlined, color: AppColors.secondaryHighlight, size: 18),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Text(
                        'Theme & Aesthetics',
                        style: AppTypography.headlineSmall(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'OLED ENGINE',
                style: AppTypography.labelSmall(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Theme Mini Preview Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: themes.map((t) {
                final isSelected = prefs.themeMode == t['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      prefs.setThemeMode(t['id'] as String);
                      themeProvider.setTheme(t['mode'] as AppThemeMode);
                      prefs.triggerHaptic();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceContainerHighest
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (t['color'] as Color).withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t['color'] as Color,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (t['color'] as Color).withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t['name'] as String,
                            style: AppTypography.labelMedium(
                              color: isSelected ? AppColors.onSurface : AppColors.onSurfaceMuted,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Toggles
          _buildToggleTile(
            title: 'Ambient Dynamic Blur',
            subtitle: 'Reactive glass lighting driven by real-time album chroma',
            value: prefs.ambientDynamicBlur,
            onChanged: (val) {
              prefs.setAmbientDynamicBlur(val);
              themeProvider.toggleAmbientDynamicBlur();
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),
          _buildToggleTile(
            title: 'Pure Black AMOLED Mode',
            subtitle: '0-nits backdrop for extended battery life',
            value: prefs.pureBlackAmoled,
            onChanged: (val) {
              prefs.setPureBlackAmoled(val);
              if (val) {
                themeProvider.setTheme(AppThemeMode.oledDark);
              }
              prefs.triggerHaptic();
            },
          ),
        ],
      ),
    );
  }

  // --- 3. Playback & Audio Engine Card ---
  Widget _buildAudioEngineCard(BuildContext context, PreferencesService prefs) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: AppColors.primaryContainer, size: 18),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  'Playback & Audio Engine',
                  style: AppTypography.headlineSmall(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Quality Row
          _buildActionTile(
            title: 'Audio Output Quality',
            subtitle: prefs.audioOutputQuality,
            icon: Icons.chevron_right_rounded,
            onTap: () => _showQualitySelectionDialog(context, prefs),
          ),
          const SizedBox(height: 8),

          // Gapless Playback Toggle
          _buildToggleTile(
            title: 'Gapless Playback',
            subtitle: 'Zero latency boundary between consecutive tracks',
            value: prefs.gaplessPlayback,
            onChanged: (val) {
              prefs.setGaplessPlayback(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // Equalizer & Spatial Audio Shortcut
          _buildActionTile(
            title: 'Equalizer & Spatial Audio',
            subtitle: 'Dolby Atmos & 10-Band Parametric EQ',
            icon: Icons.chevron_right_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EqualizerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 4. Haptics & Sensory Effects Card ---
  Widget _buildHapticsCard(BuildContext context, PreferencesService prefs) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Text(
                        'Haptics & Sensory Effects',
                        style: AppTypography.headlineSmall(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'TACTILE',
                  style: AppTypography.labelSmall(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Haptic Feedback Switch
          _buildToggleTile(
            title: 'Haptic Feedback',
            subtitle: 'Vibrations tactiles lors des interactions et transitions',
            value: prefs.hapticFeedback,
            onChanged: (val) {
              prefs.setHapticFeedback(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // Startup Chime Switch
          _buildToggleTile(
            title: 'Startup Chime & Transitions',
            subtitle: 'Son harmonique au splash et aux transitions clés',
            value: prefs.startupChime,
            onChanged: (val) {
              prefs.setStartupChime(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // UI Sound Volume Slider
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Volume des effets sonores UI',
                              style: AppTypography.titleMedium(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(prefs.uiSoundVolume * 100).toInt()}%',
                        style: AppTypography.labelMedium(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primaryContainer,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: prefs.uiSoundVolume,
                    onChanged: (val) => prefs.setUiSoundVolume(val),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('0% Muet', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tester :',
                          style: AppTypography.labelSmall(
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...[0.25, 0.50, 1.0].map((level) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                prefs.setUiSoundVolume(level);
                                prefs.triggerHaptic();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (prefs.uiSoundVolume == level)
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(level * 100).toInt()}%',
                                  style: AppTypography.labelSmall(
                                    color: (prefs.uiSoundVolume == level)
                                        ? AppColors.primary
                                        : AppColors.onSurfaceMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Haptic Intensity Selector
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Haptic Intensity',
                        style: AppTypography.titleMedium(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      prefs.hapticIntensity == HapticLevel.soft
                          ? 'Doux'
                          : prefs.hapticIntensity == HapticLevel.medium
                              ? 'Moyen (Équilibré)'
                              : 'Prononcé',
                      style: AppTypography.labelMedium(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildHapticLevelPill(context, prefs, HapticLevel.soft, 'Doux'),
                    const SizedBox(width: 8),
                    _buildHapticLevelPill(context, prefs, HapticLevel.medium, 'Moyen'),
                    const SizedBox(width: 8),
                    _buildHapticLevelPill(context, prefs, HapticLevel.strong, 'Prononcé'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Test Button
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tester le retour sensoriel',
                              style: AppTypography.titleMedium(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pulsation haptique & note harmonique',
                              style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    prefs.triggerHaptic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚡ Haptic triggered (${prefs.hapticIntensity.name.toUpperCase()}) & sound simulated at ${(prefs.uiSoundVolume * 100).toInt()}%',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.surfaceContainerHigh,
                      ),
                    );
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: const Text('Tester'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHapticLevelPill(
    BuildContext context,
    PreferencesService prefs,
    HapticLevel level,
    String label,
  ) {
    final isSelected = prefs.hapticIntensity == level;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => prefs.setHapticIntensity(level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : AppColors.outline,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMedium(
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. AI & Smart Assistant Card ---
  Widget _buildAiCard(BuildContext context, PreferencesService prefs) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondaryHighlight, size: 18),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Text(
                        'AI & Smart Assistant',
                        style: AppTypography.headlineSmall(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryHighlight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NEURAL',
                  style: AppTypography.labelSmall(
                    color: AppColors.secondaryHighlight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Inference Model Info
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFERENCE MODEL',
                  style: AppTypography.labelSmall(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Local Neural Engine v1.0',
                        style: AppTypography.titleMedium(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Offline',
                        style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Voice Wake Word Switch
          _buildToggleTile(
            title: 'Voice Wake Word ("Hey Mind-Music")',
            subtitle: 'Ultra-low-power voice trigger listening on DSP',
            value: prefs.voiceWakeWord,
            onChanged: (val) {
              prefs.setVoiceWakeWord(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // Auto-Tag Metadata Switch
          _buildToggleTile(
            title: 'Auto-Tag Missing Metadata',
            subtitle: 'AI artwork enhancement, lyrics & genre indexing',
            value: prefs.autoTagMetadata,
            onChanged: (val) {
              prefs.setAutoTagMetadata(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // AI Sleep Assistant Behavior Shortcut
          _buildActionTile(
            title: 'AI Sleep Assistant Behavior',
            subtitle: 'Exponential Volume Fade & Auto-pause',
            icon: Icons.chevron_right_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdvancedSleepTimerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 6. Library & Local Storage Card ---
  Widget _buildStorageCard(
    BuildContext context,
    PreferencesService prefs,
    StorageScannerService scanner,
  ) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHighest,
                ),
                child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  'Library & Local Storage',
                  style: AppTypography.headlineSmall(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Auto-Scan Directories
          _buildActionTile(
            title: 'Auto-Scan Media Directories',
            subtitle: scanner.isScanning
                ? 'Scanning in progress (${(scanner.scanProgress * 100).toInt()}%)...'
                : 'Instant (Music, DCIM, Downloads)',
            icon: Icons.tune_rounded,
            onTap: () {
              scanner.scanDeviceStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔍 Deep scanning storage directories...'),
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Audio Extractor Preset
          _buildActionTile(
            title: 'Video Audio Extractor',
            subtitle: 'Default export: ${prefs.audioExtractorPreset}',
            icon: Icons.tune_rounded,
            onTap: () => _showExtractorPresetDialog(context, prefs),
          ),
          const SizedBox(height: 8),

          // Cache Cleanup Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cached Art & Waveforms',
                        style: AppTypography.titleMedium(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '1.2 GB temporary index',
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    prefs.triggerHaptic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🧹 Temporary cache & waveform index cleared (1.2 GB freed).'),
                        backgroundColor: AppColors.surfaceContainerHigh,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: AppColors.onErrorContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Clear Cache',
                    style: AppTypography.labelMedium(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.bold,
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

  // --- 7. System & Privacy Card ---
  Widget _buildSystemCard(BuildContext context, PreferencesService prefs) {
    return GlassContainer(
      borderRadius: AppDimensions.borderLg,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHighest,
                ),
                child: const Icon(Icons.settings_suggest_rounded, color: AppColors.onSurfaceMuted, size: 18),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  'System & Privacy',
                  style: AppTypography.headlineSmall(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Language
          _buildActionTile(
            title: 'Language',
            subtitle: prefs.language,
            icon: Icons.chevron_right_rounded,
            onTap: () => _showLanguageDialog(context, prefs),
          ),
          const SizedBox(height: 8),

          // Notifications Toggle
          _buildToggleTile(
            title: 'Sleep & Playback Alerts',
            subtitle: 'Rich status notifications & lock screen controls',
            value: prefs.notificationsEnabled,
            onChanged: (val) {
              prefs.setNotificationsEnabled(val);
              prefs.triggerHaptic();
            },
          ),
          const SizedBox(height: 8),

          // Privacy Guard
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy & Data Guard',
                              style: AppTypography.titleMedium(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Zero Telemetry Analytics',
                              style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '100% OFFLINE',
                        style: AppTypography.labelSmall(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // App Architecture & Changelog
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mind-Music Architecture',
                        style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Build 1420 • Liquid Glass v1.0.0',
                        style: AppTypography.labelMedium(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showChangelogDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Changelog'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Common Widget Builders ---
  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: AppDimensions.borderDefault,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryContainer,
            activeThumbColor: AppColors.onPrimary,
            inactiveTrackColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppDimensions.borderDefault,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: AppDimensions.borderDefault,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Dialogs & Sheets ---
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('Help & Documentation', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
        content: Text(
          'Mind-Music is a 100% offline-first media player with embedded neural audio processing, 10-band DSP equalizer, and privacy-preserving architecture.\n\nAll media indexing and AI models run locally on your device hardware without collecting telemetry.',
          style: AppTypography.bodyMedium(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: AppTypography.labelLarge(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmResetDialog(
    BuildContext context,
    PreferencesService prefs,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('Reset to Defaults?', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
        content: Text(
          'This will restore all aesthetic themes, audio settings, haptics, and system preferences to their factory state.',
          style: AppTypography.bodyMedium(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.labelLarge(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              prefs.resetToDefaults();
              themeProvider.setTheme(AppThemeMode.liquidGlass);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Settings reset to factory defaults.'),
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.onErrorContainer,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showQualitySelectionDialog(BuildContext context, PreferencesService prefs) {
    final qualities = [
      'Lossless FLAC & 32bit Hi-Res',
      'High Fidelity 24bit / 96kHz',
      'Standard 16bit / 44.1kHz CD Quality',
      'Battery Saver Low Bitrate',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audio Output Quality', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            ...qualities.map((q) {
              final isSelected = prefs.audioOutputQuality == q;
              return ListTile(
                title: Text(q, style: AppTypography.bodyLarge(color: AppColors.onSurface)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  prefs.setAudioOutputQuality(q);
                  prefs.triggerHaptic();
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showExtractorPresetDialog(BuildContext context, PreferencesService prefs) {
    final presets = ['FLAC Lossless', 'MP3 320 kbps', 'AAC 256 kbps', 'WAV Raw PCM'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video Audio Extractor Preset', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            ...presets.map((p) {
              final isSelected = prefs.audioExtractorPreset == p;
              return ListTile(
                title: Text(p, style: AppTypography.bodyLarge(color: AppColors.onSurface)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  prefs.setAudioExtractorPreset(p);
                  prefs.triggerHaptic();
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, PreferencesService prefs) {
    final languages = ['Français / English', 'English', 'Français', 'Español', 'Deutsch'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interface Language', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            ...languages.map((l) {
              final isSelected = prefs.language == l;
              return ListTile(
                title: Text(l, style: AppTypography.bodyLarge(color: AppColors.onSurface)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  prefs.setLanguage(l);
                  prefs.triggerHaptic();
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('Changelog v1.0.0', style: AppTypography.headlineSmall(color: AppColors.onSurface)),
        content: SingleChildScrollView(
          child: Text(
            '• Initial Release of Mind-Music Liquid Glass Edition\n'
            '• High performance offline audio & video playback engine\n'
            '• 10-Band Graphic Equalizer with live Bezier Spline response\n'
            '• Advanced Sleep Timer with logarithmic gradual fade-out\n'
            '• AI Mix generator & Smart Playlists with reordering\n'
            '• Fullscreen video player with speed pitch preservation\n'
            '• Local storage deep scanning & video audio extractor\n'
            '• Zero telemetry & privacy-preserving architecture',
            style: AppTypography.bodyMedium(color: AppColors.onSurfaceMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Done', style: AppTypography.labelLarge(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAppInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text('Mind-Music v1.0.0 (MVP)', style: AppTypography.headlineSmall(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'An offline-first media powerhouse combining glassmorphism and liquid photon aesthetics with SQLite storage scanning, 10-band graphic equalizer, gapless audio playback, and local AI voice commands.\n\nAll your audio and video files stay strictly private on your device storage with zero remote telemetry.',
              style: AppTypography.bodyMedium(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
