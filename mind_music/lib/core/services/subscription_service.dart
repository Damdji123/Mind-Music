import 'package:flutter/foundation.dart';

enum SubscriptionTier {
  free,
  premiumMonthly,   // $1.99 / month
  premiumYearly,    // $10.99 / year
  lifetime,         // One-time purchase utility option
}

/// Manages User Entitlements and Freemium status according to the document's
/// "Monetization part" specification:
///
/// Free:
/// - Full local audio & video playback
/// - Library management & basic playlists
/// - Basic sleep timer & basic AI commands
/// - Tasteful native ads on non-critical screens
///
/// Premium (MYPLAYER PREMIUM):
/// - 🚫 Remove all ads
/// - 🤖 Advanced AI commands
/// - 🎶 AI playlist generation
/// - 🧠 AI library organization & smart folders
/// - 🎤 Extended voice commands
/// - 🎨 Advanced themes (OLED, Cyberpunk, Sunset)
/// - 🌙 Advanced sleep sessions with gradual fade-out
/// - 🔊 32-bit Hi-Res audio DSP
class SubscriptionService with ChangeNotifier {
  SubscriptionTier _currentTier = SubscriptionTier.free;
  int _freeAiRequestsQuota = 5; // Daily cloud AI quota for free tier

  SubscriptionTier get currentTier => _currentTier;
  bool get isPremium => _currentTier != SubscriptionTier.free;
  bool get isLifetime => _currentTier == SubscriptionTier.lifetime;
  int get remainingAiRequests => _freeAiRequestsQuota;

  // --- Entitlements as defined in Music player.docx ---

  /// Completely suppresses all advertising in the entire application
  bool get isAdFree => isPremium;

  /// Advanced AI commands (e.g. multi-step action intent parsing)
  bool get hasAdvancedAiCommands => isPremium;

  /// Dynamic AI playlist generator based on mood, tempo, recent listening
  bool get hasAiPlaylistGeneration => isPremium;

  /// AI automatic library metadata organization and smart folder sorting
  bool get hasAiLibraryOrganization => isPremium;

  /// Extended voice commands & wake-word listening
  bool get hasExtendedVoiceCommands => isPremium;

  /// Premium aesthetic themes (OLED Ultra Dark, Cyberpunk Neon, Sunset Glow)
  bool get hasAdvancedThemes => isPremium;

  /// Advanced sleep sessions (fade-out curves, sleep sensor, track ending)
  bool get hasAdvancedSleepSessions => isPremium;

  /// Studio 32-bit DSP & custom equalizer preset saving/locking
  bool get hasHiResDsp => isPremium;

  /// Checks if AI request can be performed
  bool get canQueryAi {
    if (isPremium) return true;
    return _freeAiRequestsQuota > 0;
  }

  /// Consumes 1 AI credit for free users
  void consumeAiRequest() {
    if (!isPremium && _freeAiRequestsQuota > 0) {
      _freeAiRequestsQuota--;
      notifyListeners();
    }
  }

  /// Rewarded Ad benefit: user voluntarily watches an ad to unlock +3 extra AI requests
  void creditRewardedAiRequests(int count) {
    _freeAiRequestsQuota += count;
    notifyListeners();
  }

  /// Upgrades user to a premium plan
  void upgradeToPremium({SubscriptionTier tier = SubscriptionTier.premiumYearly}) {
    _currentTier = tier;
    notifyListeners();
  }

  /// Reset to free tier (useful for testing & subscription expiration)
  void revertToFree() {
    _currentTier = SubscriptionTier.free;
    _freeAiRequestsQuota = 5;
    notifyListeners();
  }
}
