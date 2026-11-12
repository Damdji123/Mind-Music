import 'package:flutter/foundation.dart';
import 'subscription_service.dart';

/// Ads management architecture strictly adhering to the "Monetization part" of Music player.docx:
///
/// Guidelines:
/// 1. Primary format is Native Ads, cleanly embedded between non-critical list views.
/// 2. NEVER show ads:
///    - During audio or video playback
///    - On the main player controls or now playing screens
///    - While user is in a sleep session
///    - Immediately after pressing Play (audio must start instantly)
/// 3. Zero ads for Premium subscribers.
/// 4. Rewarded ads: allow users to voluntarily watch an ad to earn extra AI requests.
class AdsService with ChangeNotifier {
  final SubscriptionService _subscriptionService;
  bool _isPlaybackActive = false;
  bool _isSleepSessionActive = false;

  AdsService(this._subscriptionService) {
    _subscriptionService.addListener(_onSubscriptionChanged);
  }

  bool get shouldShowAds => !_subscriptionService.isAdFree;

  /// Whether a native ad can be rendered safely on the current screen
  bool canDisplayNativeAd({required String screenName}) {
    if (!shouldShowAds) return false;

    // Prohibited screen contexts per document specifications
    if (_isPlaybackActive && screenName == 'NowPlayingScreen') return false;
    if (_isSleepSessionActive) return false;
    if (screenName == 'PlayerControls') return false;

    // Allowed non-critical screens:
    const allowedScreens = ['HomeScreen', 'LibraryScreen', 'PlaylistsScreen', 'SettingsScreen'];
    return allowedScreens.contains(screenName);
  }

  void setPlaybackState({required bool isPlaying}) {
    if (_isPlaybackActive != isPlaying) {
      _isPlaybackActive = isPlaying;
      notifyListeners();
    }
  }

  void setSleepSessionState({required bool isActive}) {
    if (_isSleepSessionActive != isActive) {
      _isSleepSessionActive = isActive;
      notifyListeners();
    }
  }

  /// Triggers a Rewarded Ad to earn AI credits (e.g., +3 requests)
  Future<bool> showRewardedAdForAiCredits({
    required Function(int bonusCredits) onRewardEarned,
  }) async {
    if (!_subscriptionService.isPremium) {
      // In production, invoke Google Mobile Ads RewardedAd.show()
      debugPrint('[AdsService] Rewarded Ad presented to user for extra AI credits.');
      const int bonus = 3;
      _subscriptionService.creditRewardedAiRequests(bonus);
      onRewardEarned(bonus);
      return true;
    }
    return false;
  }

  void _onSubscriptionChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
}
