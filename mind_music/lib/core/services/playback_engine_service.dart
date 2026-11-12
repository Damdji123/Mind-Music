import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item_model.dart';
import 'ads_service.dart';
import '../security/security_validator.dart';

enum PlaybackMode {
  audio,
  video,
}

class PlaybackEngineService with ChangeNotifier {
  final AdsService _adsService;

  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

  PlaybackMode _mode = PlaybackMode.audio;
  MediaItemModel? _currentMedia;
  List<MediaItemModel> _queue = [];
  int _queueIndex = 0;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  // Sleep Timer
  Timer? _sleepTimer;
  Timer? _sleepCountdownTicker;
  Duration? _remainingSleepDuration;
  bool _isSleepTimerActive = false;

  PlaybackEngineService(this._adsService) {
    _initAudioStreams();
  }

  PlaybackMode get mode => _mode;
  MediaItemModel? get currentMedia => _currentMedia;
  List<MediaItemModel> get queue => _queue;
  int get queueIndex => _queueIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  bool get isSleepTimerActive => _isSleepTimerActive;
  Duration? get remainingSleepDuration => _remainingSleepDuration;
  VideoPlayerController? get videoController => _videoController;

  void _initAudioStreams() {
    _audioPlayer.positionStream.listen((pos) {
      if (_mode == PlaybackMode.audio) {
        _position = pos;
        notifyListeners();
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (_mode == PlaybackMode.audio && dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (_mode == PlaybackMode.audio) {
        _isPlaying = state.playing;
        _adsService.setPlaybackState(isPlaying: _isPlaying);

        if (state.processingState == ProcessingState.completed) {
          _onPlaybackCompleted();
        }
        notifyListeners();
      }
    });
  }

  void setQueue(List<MediaItemModel> mediaList, {int startIndex = 0}) {
    _queue = List.from(mediaList);
    _queueIndex = startIndex.clamp(0, _queue.isNotEmpty ? _queue.length - 1 : 0);
    if (_queue.isNotEmpty) {
      playMedia(_queue[_queueIndex]);
    }
  }

  Future<void> playMedia(MediaItemModel media) async {
    // Security check: ensure path is safe from traversal and allowed
    if (!SecurityValidator.isSafeMediaPath(media.filePath)) {
      debugPrint('[PlaybackEngine] Blocked attempt to play unsafe media path: ${media.filePath}');
      return;
    }

    _currentMedia = media;
    _mode = media.isVideo ? PlaybackMode.video : PlaybackMode.audio;
    _position = Duration.zero;
    _duration = media.duration;
    notifyListeners();

    if (_mode == PlaybackMode.audio) {
      await _disposeVideoController();
      try {
        if (media.filePath.startsWith('assets/')) {
          // Play simulated audio for demo files
          await _audioPlayer.setAsset(media.filePath);
        } else {
          await _audioPlayer.setFilePath(media.filePath);
        }
        await _audioPlayer.play();
      } catch (e) {
        // Fallback for mock/virtual items in emulator
        debugPrint('[PlaybackEngine] Audio play notice: $e (running in preview state)');
        _isPlaying = true;
        _adsService.setPlaybackState(isPlaying: true);
        notifyListeners();
      }
    } else {
      // Video Playback
      await _audioPlayer.pause();
      await _disposeVideoController();

      try {
        if (media.filePath.startsWith('assets/')) {
          _videoController = VideoPlayerController.asset(media.filePath);
        } else {
          _videoController = VideoPlayerController.networkUrl(Uri.file(media.filePath));
        }

        await _videoController!.initialize();
        _duration = _videoController!.value.duration;

        _videoController!.addListener(_videoListener);
        await _videoController!.play();
      } catch (e) {
        debugPrint('[PlaybackEngine] Video play notice: $e (running in preview state)');
        _isPlaying = true;
        _adsService.setPlaybackState(isPlaying: true);
      }
    }
    notifyListeners();
  }

  void _videoListener() {
    if (_videoController != null && _mode == PlaybackMode.video) {
      _position = _videoController!.value.position;
      _isPlaying = _videoController!.value.isPlaying;
      _adsService.setPlaybackState(isPlaying: _isPlaying);

      if (_position >= _duration && _duration > Duration.zero) {
        _onPlaybackCompleted();
      }
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_mode == PlaybackMode.audio) {
      if (_currentMedia != null) {
        try {
          await _audioPlayer.pause();
        } catch (_) {}
      }
    } else if (_videoController != null) {
      try {
        await _videoController!.pause();
      } catch (_) {}
    }
    _isPlaying = false;
    _adsService.setPlaybackState(isPlaying: false);
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_mode == PlaybackMode.audio) {
      if (_currentMedia == null) {
        _isPlaying = !_isPlaying;
        _adsService.setPlaybackState(isPlaying: _isPlaying);
        notifyListeners();
        return;
      }
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } catch (_) {
        _isPlaying = !_isPlaying;
        _adsService.setPlaybackState(isPlaying: _isPlaying);
      }
    } else if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
    } else {
      _isPlaying = !_isPlaying;
      _adsService.setPlaybackState(isPlaying: _isPlaying);
    }
    notifyListeners();
  }

  Future<void> seek(Duration targetPosition) async {
    _position = targetPosition;
    if (_mode == PlaybackMode.audio) {
      await _audioPlayer.seek(targetPosition);
    } else if (_videoController != null) {
      await _videoController!.seekTo(targetPosition);
    }
    notifyListeners();
  }

  void skipNext() {
    if (_queue.isNotEmpty) {
      if (_queueIndex < _queue.length - 1) {
        _queueIndex++;
      } else if (_loopMode == LoopMode.all) {
        _queueIndex = 0;
      }
      playMedia(_queue[_queueIndex]);
    }
  }

  void skipPrevious() {
    if (_queue.isNotEmpty) {
      if (_position.inSeconds > 3) {
        seek(Duration.zero);
      } else if (_queueIndex > 0) {
        _queueIndex--;
        playMedia(_queue[_queueIndex]);
      } else {
        seek(Duration.zero);
      }
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _audioPlayer.setShuffleModeEnabled(_isShuffle);
    notifyListeners();
  }

  void toggleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    _audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  Future<void> setSpeed(double targetSpeed) async {
    _speed = targetSpeed;
    if (_mode == PlaybackMode.audio) {
      await _audioPlayer.setSpeed(_speed);
    } else if (_videoController != null) {
      await _videoController!.setPlaybackSpeed(_speed);
    }
    notifyListeners();
  }

  // --- Advanced Sleep Timer with Gradual Fade-out ---

  void startSleepTimer(
    Duration duration, {
    bool fadeOut = true,
    bool stopAtTrackEnd = false,
  }) {
    cancelSleepTimer();

    _isSleepTimerActive = true;
    _remainingSleepDuration = duration;
    _adsService.setSleepSessionState(isActive: true);
    notifyListeners();

    // 1-second countdown ticker for UI countdown display
    _sleepCountdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSleepDuration != null && _remainingSleepDuration!.inSeconds > 0) {
        _remainingSleepDuration = _remainingSleepDuration! - const Duration(seconds: 1);

        // If fadeOut is enabled, start reducing volume gradually in the final 60 seconds
        if (fadeOut && _remainingSleepDuration!.inSeconds <= 60 && _remainingSleepDuration!.inSeconds > 0) {
          final volumeRatio = _remainingSleepDuration!.inSeconds / 60.0;
          _audioPlayer.setVolume(volumeRatio.clamp(0.0, 1.0));
        }

        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    _sleepTimer = Timer(duration, () async {
      await _audioPlayer.pause();
      if (_videoController != null) {
        await _videoController!.pause();
      }
      _audioPlayer.setVolume(1.0); // Reset volume
      cancelSleepTimer();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdownTicker?.cancel();
    _sleepTimer = null;
    _sleepCountdownTicker = null;
    _isSleepTimerActive = false;
    _remainingSleepDuration = null;
    _audioPlayer.setVolume(1.0);
    _adsService.setSleepSessionState(isActive: false);
    notifyListeners();
  }

  void _onPlaybackCompleted() {
    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      if (_mode == PlaybackMode.audio) {
        _audioPlayer.play();
      } else {
        _videoController?.play();
      }
    } else {
      // Natural transition to next track
      _adsService.setPlaybackState(isPlaying: false);
      skipNext();
    }
  }

  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    cancelSleepTimer();
    _audioPlayer.dispose();
    _disposeVideoController();
    super.dispose();
  }
}
