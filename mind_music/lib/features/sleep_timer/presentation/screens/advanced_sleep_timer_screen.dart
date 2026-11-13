import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';

class AdvancedSleepTimerScreen extends StatefulWidget {
  const AdvancedSleepTimerScreen({super.key});

  @override
  State<AdvancedSleepTimerScreen> createState() => _AdvancedSleepTimerScreenState();
}

class _AdvancedSleepTimerScreenState extends State<AdvancedSleepTimerScreen> {
  int _selectedMinutes = 30;
  bool _fadeOut = true;
  bool _stopAtTrackEnd = false;

  final List<int> _presetOptions = [15, 30, 45, 60, 90];

  void _adjustMinutes(int delta) {
    setState(() {
      _selectedMinutes = (_selectedMinutes + delta).clamp(5, 240);
    });
  }

  void _startTimer(PlaybackEngineService playback) {
    playback.startSleepTimer(
      Duration(minutes: _selectedMinutes),
      fadeOut: _fadeOut,
      stopAtTrackEnd: _stopAtTrackEnd,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌙 Sleep Timer activé pour $_selectedMinutes minutes'),
        backgroundColor: AppColors.secondaryContainer,
      ),
    );
  }

  void _cancelTimer(PlaybackEngineService playback) {
    playback.cancelSleepTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep Timer annulé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackEngineService>();
    final ads = context.watch<AdsService>();
    final isActive = playback.isSleepTimerActive;
    final remaining = playback.remainingSleepDuration;

    final displayMinutes = isActive && remaining != null ? remaining.inMinutes : _selectedMinutes;
    final displaySeconds = isActive && remaining != null ? remaining.inSeconds.remainder(60) : 0;
    final timeString =
        '${displayMinutes.toString().padLeft(2, "0")}:${displaySeconds.toString().padLeft(2, "0")}';

    // Calculate arc percentage
    final totalTargetSeconds = max(1, _selectedMinutes * 60);
    final remainingSeconds = isActive && remaining != null ? remaining.inSeconds : totalTargetSeconds;
    final progress = (remainingSeconds / totalTargetSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, isActive),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                    vertical: AppDimensions.spaceSm,
                  ),
                  children: [
                    // Central Circular Interactive Dial Card
                    _buildCentralDialCard(context, timeString, progress, isActive, playback),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Quick Duration Preset Pills
                    _buildPresetPills(isActive),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Smart Audio Modifiers
                    _buildFadeOutCard(),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Sleep Protection Guarantee
                    _buildSleepProtectionCard(ads),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Main Action CTA
                    _buildMainActionButton(isActive, playback),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isActive) {
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
                  size: 42,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Sleep Timer', style: AppTypography.headlineSmall()),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bedtime, size: 14, color: AppColors.secondaryHighlight),
                          ),
                        ],
                      ),
                      Text(
                        'Minuteur intelligent & fondu sonore',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            const BoxShadow(
                              color: AppColors.primaryContainer,
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'En cours' : 'Prêt',
                  style: AppTypography.labelSmall(
                    color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralDialCard(
    BuildContext context,
    String timeString,
    double progress,
    bool isActive,
    PlaybackEngineService playback,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        children: [
          // Dial Meter Canvas
          SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _DialArcPainter(progress: progress),
                ),
                Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'RESTANT' : 'DURÉE',
                            style: AppTypography.labelSmall(
                              color: AppColors.onSurfaceMuted,
                              letterSpacing: 1.2,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeString,
                        style: AppTypography.displayLarge(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? 'Fondu actif' : 'Ajuster +/-',
                        style: AppTypography.labelSmall(
                          color: AppColors.primaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Incremental Adjustment Deck
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: AppColors.onSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('- 5 min', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isActive ? null : () => _adjustMinutes(-5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stopAtTrackEnd
                        ? AppColors.primaryContainer.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                    foregroundColor: _stopAtTrackEnd ? AppColors.primaryContainer : AppColors.onSurface,
                    elevation: 0,
                    side: BorderSide(
                      color: _stopAtTrackEnd ? AppColors.primaryContainer : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('Fin du titre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _stopAtTrackEnd = !_stopAtTrackEnd);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: AppColors.onSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ 5 min', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isActive ? null : () => _adjustMinutes(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPills(bool isActive) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._presetOptions.map((minutes) {
            final isSelected = _selectedMinutes == minutes;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isActive ? null : () => setState(() => _selectedMinutes = minutes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryContainer : AppColors.glassBorderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isSelected) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60 > 0 ? "${minutes % 60}m" : ""}',
                          style: AppTypography.labelMedium(
                            color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom picker pill
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isActive ? null : _showCustomMinutesDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 14, color: AppColors.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Perso',
                      style: AppTypography.labelMedium(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFadeOutCard() {
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volume_down, color: AppColors.primaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fondu sonore progressif',
                            style: AppTypography.titleMedium(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Atténuation douce sans réveil brutal',
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
              Switch(
                value: _fadeOut,
                activeThumbColor: AppColors.primaryContainer,
                onChanged: (val) => setState(() => _fadeOut = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le volume décroît de manière logarithmique pendant les 60 dernières secondes pour respecter les cycles d\'endormissement naturels.',
            style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepProtectionCard(AdsService ads) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      customGradient: LinearGradient(
        colors: [
          AppColors.secondaryContainer.withValues(alpha: 0.2),
          AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryHighlight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_moon_outlined, color: AppColors.secondaryHighlight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Protection Sommeil Garanti',
                        style: AppTypography.titleMedium(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 14, color: AppColors.secondaryHighlight),
                  ],
                ),
                Text(
                  'Toutes les publicités et alertes visuelles sont systématiquement bloquées durant la session.',
                  style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(bool isActive, PlaybackEngineService playback) {
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorContainer,
            foregroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Arrêter le Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          onPressed: () => _cancelTimer(playback),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppColors.primaryContainer.withValues(alpha: 0.5),
        ),
        icon: const Icon(Icons.bedtime),
        label: const Text('Démarrer le Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: () => _startTimer(playback),
      ),
    );
  }

  void _showCustomMinutesDialog() {
    int temp = _selectedMinutes;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.borderLg),
          title: Text('Durée personnalisée', style: AppTypography.headlineSmall()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$temp minutes', style: AppTypography.headlineMedium(color: AppColors.primaryContainer)),
              Slider(
                value: temp.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                activeColor: AppColors.primaryContainer,
                onChanged: (val) => setDialogState(() => temp = val.toInt()),
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
                setState(() => _selectedMinutes = temp);
                Navigator.pop(ctx);
              },
              child: const Text('Valider', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Circular Dial Arc Painter ---
class _DialArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _DialArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active radiant arc
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          AppColors.primaryContainer,
          AppColors.secondaryHighlight,
          AppColors.primaryContainer,
        ],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialArcPainter oldDelegate) => oldDelegate.progress != progress;
}
