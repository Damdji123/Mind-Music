import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/security/security_validator.dart';
import '../../../../core/services/playback_engine_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/liquid_glow.dart';
import '../../../player/presentation/screens/now_playing_screen.dart';

class AiVoiceAssistantScreen extends StatefulWidget {
  const AiVoiceAssistantScreen({super.key});

  @override
  State<AiVoiceAssistantScreen> createState() => _AiVoiceAssistantScreenState();
}

class _AiVoiceAssistantScreenState extends State<AiVoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final TextEditingController _promptController = TextEditingController();

  bool _isListening = true;
  String _lastRecognizedText =
      'Play my chill playlist and stop in 30 minutes with gentle fade out.';
  bool _intentConfirmed = true;
  final int _matchedTracksCount = 28;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
  }

  void _processCommand(String rawInput) {
    final sanitized = SecurityValidator.sanitizeInput(rawInput);
    if (sanitized.isEmpty) return;

    final subService = context.read<SubscriptionService>();
    if (!subService.canQueryAi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Daily free AI query quota reached. Upgrade to PRO or watch an ad!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    subService.consumeAiRequest();

    setState(() {
      _lastRecognizedText = sanitized;
      _intentConfirmed = true;
      _promptController.clear();
    });

    _executeParsedIntent(sanitized);
  }

  void _executeParsedIntent(String command) {
    final playback = context.read<PlaybackEngineService>();
    final scanner = context.read<StorageScannerService>();
    final lower = command.toLowerCase();

    if (lower.contains('play') || lower.contains('joue') || lower.contains('chill') || lower.contains('mix')) {
      if (scanner.audioFiles.isNotEmpty) {
        playback.setQueue(scanner.audioFiles, startIndex: 0);
      }
    }

    if (lower.contains('timer') || lower.contains('sleep') || lower.contains('30') || lower.contains('45')) {
      final minutes = lower.contains('45') ? 45 : 30;
      playback.startSleepTimer(Duration(minutes: minutes), fadeOut: true);
    }

    if (lower.contains('scan') || lower.contains('storage') || lower.contains('sd')) {
      scanner.scanDeviceStorage();
    }
  }

  void _startCurrentSession() {
    final playback = context.read<PlaybackEngineService>();
    final scanner = context.read<StorageScannerService>();

    if (scanner.audioFiles.isNotEmpty) {
      playback.setQueue(scanner.audioFiles, startIndex: 0);
    }
    playback.startSleepTimer(const Duration(minutes: 30), fadeOut: true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlowBackground(
        primaryGlow: AppColors.secondaryHighlight,
        secondaryGlow: AppColors.primaryContainer,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Header Bar
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
                        GlassIconButton(
                          icon: Icons.arrow_back,
                          size: 38,
                          iconSize: 20,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Copilot & Voice',
                              style: AppTypography.headlineSmall(color: AppColors.onSurface),
                            ),
                            Row(
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
                                Text(
                                  'Local Neural Engine • Instant',
                                  style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: AppDimensions.borderFull,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 13, color: AppColors.secondaryHighlight),
                          const SizedBox(width: 4),
                          Text(
                            'v2.4 Nano',
                            style: AppTypography.labelSmall(color: AppColors.secondaryHighlight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Animated Neural Listening Orb & Waveform
                      _buildListeningCenterStage(),

                      const SizedBox(height: 24),

                      // Intent Confirmation Card with Batch Actions
                      if (_intentConfirmed)
                        _buildIntentConfirmedCard(),

                      const SizedBox(height: 20),

                      // Quick Voice Command Chips Matrix
                      _buildQuickSuggestions(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 3. Bottom Prompt Input Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.margin,
                  0,
                  AppDimensions.margin,
                  12,
                ),
                child: GlassTextField(
                  controller: _promptController,
                  hintText: 'Type an AI command or tap mic...',
                  leading: const Icon(Icons.smart_toy_outlined, color: AppColors.secondaryHighlight, size: 20),
                  onSubmitted: _processCommand,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: _isListening ? AppColors.secondaryHighlight : AppColors.onSurfaceMuted,
                          size: 22,
                        ),
                        onPressed: _toggleListening,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, color: AppColors.primaryContainer, size: 22),
                        onPressed: () => _processCommand(_promptController.text),
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

  // --- Neural Listening Center Stage ---
  Widget _buildListeningCenterStage() {
    return Column(
      children: [
        // Pulsing Rings around Microphone
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            final scale = _isListening ? 1.0 + (_waveController.value * 0.12) : 1.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                if (_isListening)
                  Container(
                    width: 140 * scale,
                    height: 140 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondaryHighlight.withValues(
                          alpha: (0.35 * (1.0 - _waveController.value)).clamp(0.0, 1.0),
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                // Inner Glow Capsule
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0x66C084FC),
                        Color(0x3338BDF8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryHighlight.withValues(alpha: _isListening ? 0.5 : 0.2),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 42,
                    ),
                    onPressed: _toggleListening,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),
        Text(
          _isListening ? 'Listening Actively' : 'Listening Paused',
          style: AppTypography.headlineSmall(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          _isListening
              ? 'Tap to pause • Speak naturally in English or French'
              : 'Tap microphone to resume voice commands',
          style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
        ),

        const SizedBox(height: 14),

        // Live Simulated Audio Waveform Bars
        if (_isListening)
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(14, (i) {
                  final heightFactor = ((i % 4 + 1) * 6.0) * (0.6 + (_waveController.value * 0.6));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 3.5,
                    height: heightFactor.clamp(6.0, 32.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i % 2 == 0
                          ? AppColors.primaryContainer
                          : AppColors.secondaryHighlight,
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }

  // --- Intent Confirmed Card ---
  Widget _buildIntentConfirmedCard() {
    return GlassContainer(
      elevation: GlassElevation.level2,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      borderRadius: AppDimensions.borderLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                    child: const Icon(Icons.check, color: Colors.black, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Intent Confirmed',
                    style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: AppDimensions.borderFull,
                ),
                child: Text(
                  'Batch 3 Actions',
                  style: AppTypography.labelSmall(color: AppColors.secondaryHighlight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recognized Quote Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: AppDimensions.borderDefault,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: AppColors.secondaryHighlight, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '"$_lastRecognizedText"',
                    style: AppTypography.bodyMedium(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Checklist
          _buildActionRow(Icons.check_circle, 'Found $_matchedTracksCount ambient tracks in local library'),
          _buildActionRow(Icons.queue_music, 'Created smart queue: "Chill Evening Mix"'),
          _buildActionRow(Icons.timer, 'Sleep timer set: 30 mins with exponential volume fade'),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Start Session',
                  icon: const Icon(Icons.play_arrow, size: 18),
                  variant: GlassButtonVariant.aiAccent,
                  height: 44,
                  onPressed: _startCurrentSession,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderFull),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Type adjustments below to modify session parameters.')),
                  );
                },
                child: const Text('Modify'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.onSurfaceSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Voice Prompts Matrix ---
  Widget _buildQuickSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Voice Suggestions',
          style: AppTypography.labelLarge(color: AppColors.onSurfaceMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPromptPill(Icons.fitness_center, 'Workout High-Energy Mix'),
            _buildPromptPill(Icons.bedtime, 'Sleep in 45m'),
            _buildPromptPill(Icons.sync, 'Scan Storage Media'),
            _buildPromptPill(Icons.equalizer, 'Bass Boost EQ'),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptPill(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _processCommand(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: AppDimensions.borderFull,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelSmall(color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
