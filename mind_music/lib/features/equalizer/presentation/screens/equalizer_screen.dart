import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/equalizer_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final TextEditingController _customNameController = TextEditingController();

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eq = context.watch<EqualizerService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(context),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                    vertical: AppDimensions.spaceSm,
                  ),
                  children: [
                    // Master Status Card
                    _buildMasterStatusCard(context, eq),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Presets Carousel
                    _buildPresetsSection(context, eq),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // 10-Band Graphic Equalizer Console
                    _build10BandConsole(context, eq),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // DSP FX Section
                    _buildDspEffectsSection(context, eq),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
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
                  icon: Icons.arrow_back,
                  size: 40,
                  iconSize: 20,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Égaliseur Studio',
                        style: AppTypography.headlineSmall(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Traitement DSP matériel 32-bit',
                        style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
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
          GlassButton(
            label: 'Sauvegarder',
            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onPressed: () => _showSaveCustomPresetDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterStatusCard(BuildContext context, EqualizerService eq) {
    final active = eq.activePreset;

    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      customGradient: LinearGradient(
        colors: [
          AppColors.surfaceContainer.withValues(alpha: 0.8),
          AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: eq.isEnabled ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                            shape: BoxShape.circle,
                            boxShadow: eq.isEnabled
                                ? [
                                    const BoxShadow(
                                      color: AppColors.primaryContainer,
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MOTEUR AUDIO 32-BIT HI-RES',
                          style: AppTypography.labelSmall(
                            color: eq.isEnabled ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Égaliseur Audio & DSP',
                      style: AppTypography.headlineMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: AppColors.onSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset'),
                onPressed: () {
                  eq.resetToFlat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Égaliseur réinitialisé à Plat')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.graphic_eq, color: AppColors.primaryContainer, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Profil : ${active.name}',
                                style: AppTypography.labelMedium(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'FLAC 96kHz',
                        style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Master EQ Toggle
              Switch(
                value: eq.isEnabled,
                activeThumbColor: AppColors.primaryContainer,
                activeTrackColor: AppColors.primaryContainer.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.onSurfaceMuted,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                onChanged: (_) => eq.toggleMasterEq(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(BuildContext context, EqualizerService eq) {
    final active = eq.activePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRÉRÉGLAGES SONORES',
              style: AppTypography.labelMedium(color: AppColors.onSurfaceMuted, letterSpacing: 1.1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                active.characteristics,
                style: AppTypography.labelSmall(
                  color: AppColors.primaryContainer,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: eq.allPresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final p = eq.allPresets[i];
              final isSelected = p.id == eq.activePresetId;

              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => eq.selectPreset(p.id),
                  onLongPress: p.isCustom
                      ? () => _showCustomPresetOptions(context, p, eq)
                      : () => _showLockedPresetDuplication(context, p, eq),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryContainer : AppColors.glassBorderSubtle,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.isCustom ? Icons.tune : (isSelected ? Icons.speaker_group : Icons.music_note),
                          size: 16,
                          color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.name,
                          style: AppTypography.labelMedium(
                            color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (p.isCustom) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: AppColors.secondaryHighlight),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _build10BandConsole(BuildContext context, EqualizerService eq) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Spectre 10-Bandes',
                        style: AppTypography.titleMedium(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Q: 1.41', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+12 dB', style: AppTypography.labelSmall(color: AppColors.secondaryHighlight)),
                  const SizedBox(width: 6),
                  Text('0 dB', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
                  const SizedBox(width: 6),
                  Text('-12 dB', style: AppTypography.labelSmall(color: AppColors.primaryContainer)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Spline Curve Visualization Canvas
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _EqualizerCurvePainter(gains: eq.currentGains),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 10 Band Vertical Sliders Matrix
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (i) {
                final gain = eq.currentGains[i];
                final label = EqualizerService.frequencyLabels[i];

                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${gain > 0 ? "+" : ""}${gain.toInt()}',
                        style: AppTypography.labelSmall(
                          color: gain == 0 ? AppColors.onSurfaceMuted : AppColors.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: AppColors.primaryContainer,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: gain,
                              min: -12.0,
                              max: 12.0,
                              divisions: 24,
                              onChanged: eq.isEnabled
                                  ? (val) => eq.setBandGain(i, val)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTypography.labelSmall(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDspEffectsSection(BuildContext context, EqualizerService eq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMÉLIORATIONS DSP & ESPACE SONORE',
          style: AppTypography.labelMedium(color: AppColors.onSurfaceMuted, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        // Bass Boost
        GlassContainer(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.surround_sound, color: AppColors.primaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bass Boost Dynamique',
                            style: AppTypography.titleMedium(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(eq.bassBoost * 100).toInt()}%',
                    style: AppTypography.labelMedium(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: eq.bassBoost,
                min: 0.0,
                max: 1.0,
                activeColor: AppColors.primaryContainer,
                inactiveColor: Colors.white.withValues(alpha: 0.1),
                onChanged: eq.isEnabled ? (v) => eq.setBassBoost(v) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3D Spatial Virtualizer
        GlassContainer(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.spatial_audio_off, color: AppColors.secondaryHighlight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Spatialisation 3D (Surround)',
                            style: AppTypography.titleMedium(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(eq.virtualizer * 100).toInt()}%',
                    style: AppTypography.labelMedium(
                      color: AppColors.secondaryHighlight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: eq.virtualizer,
                min: 0.0,
                max: 1.0,
                activeColor: AppColors.secondaryHighlight,
                inactiveColor: Colors.white.withValues(alpha: 0.1),
                onChanged: eq.isEnabled ? (v) => eq.setVirtualizer(v) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Reverb Environment
        GlassContainer(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.waves, color: AppColors.primaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Réverbération Studio',
                            style: AppTypography.titleMedium(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Environnement acoustique virtuel',
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
              DropdownButton<String>(
                value: eq.reverbPreset,
                dropdownColor: AppColors.surfaceContainerLowest,
                style: AppTypography.labelMedium(color: AppColors.primaryContainer),
                underline: const SizedBox(),
                items: ['None', 'Room', 'Concert Hall', 'Cathedral']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: eq.isEnabled ? (val) => eq.setReverb(val ?? 'Room') : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSaveCustomPresetDialog(BuildContext context) {
    _customNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
        title: Text('Sauvegarder Preset Custom', style: AppTypography.headlineSmall()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enregistre la configuration actuelle des 10 bandes dans vos profils utilisateur.',
              style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customNameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ex: Bass & Vocal Hi-Fi',
                hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () {
              final name = _customNameController.text.trim();
              if (name.isNotEmpty) {
                final eq = context.read<EqualizerService>();
                final saved = eq.saveCustomPreset(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preset "${saved.name}" sauvegardé !')),
                );
              }
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showLockedPresetDuplication(BuildContext context, EqualizerPreset preset, EqualizerService eq) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: AppColors.secondaryHighlight),
                const SizedBox(width: 8),
                Text('Preset Prédéfini : ${preset.name}', style: AppTypography.headlineSmall()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Les préréglages d\'usine sont calibrés et verrouillés pour garantir une restitution audio de référence. Pour modifier les bandes, dupliquez ce profil dans vos presets custom.',
              style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.copy),
                label: const Text('Dupliquer et déverrouiller', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  final dup = eq.duplicateLockedPreset(preset.id, '${preset.name} (Édition)');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profil "${dup.name}" créé et sélectionné !')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPresetOptions(BuildContext context, EqualizerPreset preset, EqualizerService eq) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text('Supprimer "${preset.name}"', style: const TextStyle(color: AppColors.error)),
                onTap: () {
                  eq.deleteCustomPreset(preset.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preset custom supprimé')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Spline Painter for Dynamic Audio Curve ---
class _EqualizerCurvePainter extends CustomPainter {
  final List<double> gains;

  _EqualizerCurvePainter({required this.gains});

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) return;

    // 0 dB dashed reference line
    final zeroY = size.height / 2;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), gridPaint);

    final points = <Offset>[];
    final stepX = size.width / (gains.length - 1);

    for (int i = 0; i < gains.length; i++) {
      final x = i * stepX;
      // map gain (-12 to +12) to y (size.height to 0)
      final norm = (gains[i] + 12) / 24; // 0.0 to 1.0
      final y = size.height - (norm * (size.height - 16) + 8);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Fill area gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.35),
          AppColors.secondaryHighlight.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke spline line
    final linePaint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EqualizerCurvePainter oldDelegate) => true;
}
