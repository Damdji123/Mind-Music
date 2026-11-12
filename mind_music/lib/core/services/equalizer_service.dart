import 'package:flutter/foundation.dart';

class EqualizerPreset {
  final String id;
  final String name;
  final List<double> bandGains; // 10 bands (-12 to +12 dB)
  final bool isCustom;
  final String characteristics;

  const EqualizerPreset({
    required this.id,
    required this.name,
    required this.bandGains,
    this.isCustom = false,
    this.characteristics = 'Équilibré',
  });

  EqualizerPreset copyWith({
    String? id,
    String? name,
    List<double>? bandGains,
    bool? isCustom,
    String? characteristics,
  }) {
    return EqualizerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bandGains: bandGains ?? List.from(this.bandGains),
      isCustom: isCustom ?? this.isCustom,
      characteristics: characteristics ?? this.characteristics,
    );
  }
}

class EqualizerService extends ChangeNotifier {
  static const List<String> frequencyLabels = [
    '32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'
  ];

  static const List<String> frequencyUnits = [
    '32Hz', '64Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'
  ];

  bool _isEnabled = true;
  String _activePresetId = 'bass';
  List<double> _currentGains = [8.0, 6.0, 4.0, 2.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0];

  // DSP Enhancements
  double _bassBoost = 0.65; // 0.0 - 1.0
  double _virtualizer = 0.40; // 0.0 - 1.0 (3D surround)
  String _reverbPreset = 'Room'; // None, Room, Concert Hall, Cathedral
  bool _loudnessNormalizer = true;

  final Map<String, EqualizerPreset> _builtInPresets = {
    'bass': const EqualizerPreset(
      id: 'bass',
      name: 'Bass Boost',
      bandGains: [8.0, 6.0, 4.0, 2.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0],
      characteristics: '+6dB Sub-Bass, -1dB Mid, +3dB Air',
    ),
    'jazz': const EqualizerPreset(
      id: 'jazz',
      name: 'Jazz',
      bandGains: [4.0, 2.0, 0.0, 2.0, -2.0, -2.0, 0.0, 2.0, 4.0, 5.0],
      characteristics: 'Chaleur cuivrée & présence contrebasse',
    ),
    'pop': const EqualizerPreset(
      id: 'pop',
      name: 'Pop',
      bandGains: [-2.0, -1.0, 2.0, 4.0, 5.0, 4.0, 2.0, -1.0, -1.0, -2.0],
      characteristics: 'Accentuation médiums & clarté refrain',
    ),
    'electro': const EqualizerPreset(
      id: 'electro',
      name: 'Électro',
      bandGains: [6.0, 5.0, 2.0, 0.0, -2.0, 2.0, 1.0, 3.0, 5.0, 6.0],
      characteristics: 'Kick percutant & brillance synthé',
    ),
    'vocal': const EqualizerPreset(
      id: 'vocal',
      name: 'Clarté Vocale',
      bandGains: [-3.0, -2.0, -1.0, 3.0, 6.0, 6.0, 4.0, 2.0, 0.0, -1.0],
      characteristics: 'Détachement des voix & intelligibilité',
    ),
    'acoustic': const EqualizerPreset(
      id: 'acoustic',
      name: 'Acoustique',
      bandGains: [3.0, 2.0, 1.0, 1.0, 2.0, 2.0, 3.0, 3.0, 4.0, 4.0],
      characteristics: 'Résonance naturelle bois & cordes',
    ),
    'rock': const EqualizerPreset(
      id: 'rock',
      name: 'Rock Dynamique',
      bandGains: [5.0, 3.0, -1.0, -2.0, 1.0, 3.0, 4.0, 5.0, 6.0, 6.0],
      characteristics: 'Guitare distordue & attaque batterie',
    ),
    'flat': const EqualizerPreset(
      id: 'flat',
      name: 'Flat / Pure Direct',
      bandGains: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      characteristics: 'Réponse en fréquence neutre de référence',
    ),
  };

  final List<EqualizerPreset> _customPresets = [];

  bool get isEnabled => _isEnabled;
  String get activePresetId => _activePresetId;
  List<double> get currentGains => List.unmodifiable(_currentGains);
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  String get reverbPreset => _reverbPreset;
  bool get loudnessNormalizer => _loudnessNormalizer;

  List<EqualizerPreset> get allPresets => [
        ..._builtInPresets.values,
        ..._customPresets,
      ];

  EqualizerPreset get activePreset {
    if (_builtInPresets.containsKey(_activePresetId)) {
      return _builtInPresets[_activePresetId]!;
    }
    try {
      return _customPresets.firstWhere((p) => p.id == _activePresetId);
    } catch (_) {
      return _builtInPresets['bass']!;
    }
  }

  void toggleMasterEq() {
    _isEnabled = !_isEnabled;
    notifyListeners();
  }

  void selectPreset(String presetId) {
    _activePresetId = presetId;
    if (_builtInPresets.containsKey(presetId)) {
      _currentGains = List.from(_builtInPresets[presetId]!.bandGains);
    } else {
      final custom = _customPresets.firstWhere((p) => p.id == presetId, orElse: () => _builtInPresets['bass']!);
      _currentGains = List.from(custom.bandGains);
    }
    notifyListeners();
  }

  void setBandGain(int bandIndex, double gain) {
    if (bandIndex >= 0 && bandIndex < _currentGains.length) {
      _currentGains[bandIndex] = gain.clamp(-12.0, 12.0);
      _activePresetId = 'custom';
      notifyListeners();
    }
  }

  void resetToFlat() {
    _currentGains = List.filled(10, 0.0);
    _activePresetId = 'flat';
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    notifyListeners();
  }

  void setBassBoost(double value) {
    _bassBoost = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setVirtualizer(double value) {
    _virtualizer = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setReverb(String preset) {
    _reverbPreset = preset;
    notifyListeners();
  }

  void toggleLoudnessNormalizer() {
    _loudnessNormalizer = !_loudnessNormalizer;
    notifyListeners();
  }

  EqualizerPreset saveCustomPreset(String name) {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final custom = EqualizerPreset(
      id: newId,
      name: name.trim().isEmpty ? 'Profil Utilisateur' : name.trim(),
      bandGains: List.from(_currentGains),
      isCustom: true,
      characteristics: 'Courbe personnalisée (${name.trim()})',
    );
    _customPresets.add(custom);
    _activePresetId = newId;
    notifyListeners();
    return custom;
  }

  EqualizerPreset duplicateLockedPreset(String sourcePresetId, String newName) {
    final source = allPresets.firstWhere((p) => p.id == sourcePresetId, orElse: () => _builtInPresets['bass']!);
    final newId = 'custom_dup_${DateTime.now().millisecondsSinceEpoch}';
    final custom = EqualizerPreset(
      id: newId,
      name: newName.trim().isEmpty ? '${source.name} (Modifiable)' : newName.trim(),
      bandGains: List.from(source.bandGains),
      isCustom: true,
      characteristics: 'Dérivé de ${source.name}',
    );
    _customPresets.add(custom);
    _activePresetId = newId;
    _currentGains = List.from(custom.bandGains);
    notifyListeners();
    return custom;
  }

  void deleteCustomPreset(String presetId) {
    _customPresets.removeWhere((p) => p.id == presetId);
    if (_activePresetId == presetId) {
      selectPreset('bass');
    } else {
      notifyListeners();
    }
  }
}
