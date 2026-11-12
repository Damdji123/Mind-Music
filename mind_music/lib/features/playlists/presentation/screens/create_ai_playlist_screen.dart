import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/media_item_model.dart';
import '../../../../core/services/playlist_service.dart';
import '../../../../core/services/storage_scanner_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/liquid_glow.dart';

class CreateAiPlaylistScreen extends StatefulWidget {
  const CreateAiPlaylistScreen({super.key});

  @override
  State<CreateAiPlaylistScreen> createState() => _CreateAiPlaylistScreenState();
}

class _CreateAiPlaylistScreenState extends State<CreateAiPlaylistScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Chill Vibes 2024');
  final TextEditingController _descController =
      TextEditingController(text: 'Sons acoustiques, crépuscule & beats feutrés');

  int _selectedSourceIndex = 1; // 0: Library, 1: AI Copilot, 2: Manual
  int _selectedGradientIndex = 0;
  bool _isPrivate = true;
  String _selectedBpm = 'BPM 85-110';
  bool _isHiResOnly = false;
  String _selectedMood = 'Chill & Relax';
  double _targetTrackCount = 15;

  final List<MediaItemModel> _stagedTracks = [];

  final List<List<Color>> _coverGradients = [
    [const Color(0xFF0284C7), const Color(0xFF7C3AED)],
    [const Color(0xFFD97706), const Color(0xFFDC2626)],
    [const Color(0xFF059669), const Color(0xFF0284C7)],
    [const Color(0xFF9333EA), const Color(0xFFEC4899)],
  ];

  final List<String> _moods = [
    'Chill & Relax',
    'Workout & Energy',
    'Deep Focus & Study',
    'Night Drive',
    'Acoustic Sunset',
  ];

  final List<String> _bpmOptions = [
    'BPM 70-85',
    'BPM 85-110',
    'BPM 110-130',
    'BPM 130+',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate staged tracks with sample/scanned media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scanner = context.read<StorageScannerService>();
      final pool = scanner.audioFiles.isNotEmpty ? scanner.audioFiles : _generateSampleMedia();
      setState(() {
        _stagedTracks.addAll(pool.take(5));
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<MediaItemModel> _generateSampleMedia() {
    return [
      MediaItemModel(
        id: 's_1',
        title: 'Sunset Horizon',
        artist: 'Solar Fields',
        album: 'Albedo',
        duration: const Duration(minutes: 4, seconds: 15),
        filePath: 'C:/Music/sunset.flac',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 's_2',
        title: 'Cyber Streets',
        artist: 'Lorn',
        album: 'Remnant',
        duration: const Duration(minutes: 3, seconds: 50),
        filePath: 'C:/Music/streets.mp3',
        format: 'MP3',
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 's_3',
        title: 'Midnight Lo-Fi Echo',
        artist: 'Kupla',
        album: 'Kingdom in Blue',
        duration: const Duration(minutes: 2, seconds: 40),
        filePath: 'C:/Music/midnight.wav',
        format: 'WAV',
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
      MediaItemModel(
        id: 's_4',
        title: 'Deep Focus Pulse',
        artist: 'Carbon Based',
        album: 'World of Sleepers',
        duration: const Duration(minutes: 5, seconds: 20),
        filePath: 'C:/Music/pulse.flac',
        format: 'FLAC',
        isHiRes: true,
        dateModified: DateTime.utc(2024, 1, 1),
        folderName: 'Music',
      ),
    ];
  }

  void _triggerAiGeneration() {
    final scanner = context.read<StorageScannerService>();
    final pool = scanner.audioFiles.isNotEmpty ? scanner.audioFiles : _generateSampleMedia();

    final generated = List<MediaItemModel>.from(pool);
    if (_isHiResOnly) {
      final hires = generated.where((t) => t.isHiRes).toList();
      if (hires.isNotEmpty) {
        generated.retainWhere((t) => t.isHiRes);
      }
    }
    generated.shuffle();

    setState(() {
      _nameController.text = '$_selectedMood Mix';
      _descController.text = 'Ambiance $_selectedMood • $_selectedBpm • ${_isHiResOnly ? "HD Audio" : "Mix local"}';
      _stagedTracks.clear();
      _stagedTracks.addAll(generated.take(_targetTrackCount.toInt()));
      _selectedGradientIndex = Random().nextInt(_coverGradients.length);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Mix IA généré avec ${_stagedTracks.length} titres'),
        backgroundColor: AppColors.secondaryContainer,
      ),
    );
  }

  void _savePlaylist() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un titre pour la playlist.')),
      );
      return;
    }

    final playlistService = context.read<PlaylistService>();
    playlistService.createPlaylist(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      tracks: _stagedTracks,
      isAiMix: _selectedSourceIndex == 1,
      bpmRange: _selectedBpm,
      tags: [
        _selectedMood,
        if (_isHiResOnly) 'HD / FLAC',
        if (_isPrivate) 'Privée' else 'Publique',
      ],
      gradientIndex: _selectedGradientIndex,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist "${_nameController.text.trim()}" enregistrée !'),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _coverGradients[_selectedGradientIndex % _coverGradients.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidGlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Screen Navigation Bar
              _buildNavigationBar(context),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.margin,
                    vertical: AppDimensions.spaceSm,
                  ),
                  children: [
                    // Identity Glass Capsule
                    _buildIdentityCapsule(gradient),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Source Selection Grid
                    _buildSourceSelector(),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // AI Controls if AI Copilot is selected
                    if (_selectedSourceIndex == 1) ...[
                      _buildAiControlsCard(),
                      const SizedBox(height: AppDimensions.spaceLg),
                    ],

                    // Tracklist Preview Section
                    _buildTracklistPreview(),
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

  Widget _buildNavigationBar(BuildContext context) {
    return Padding(
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
                size: 42,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Créer une Playlist', style: AppTypography.headlineSmall()),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.primaryContainer, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              'AI Mix',
                              style: AppTypography.labelSmall(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Bibliothèque locale • Haute fidélité',
                    style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            ],
          ),
          GlassButton(
            label: 'Enregistrer',
            icon: const Icon(Icons.check, size: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: _savePlaylist,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCapsule(List<Color> gradient) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art selector
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGradientIndex = (_selectedGradientIndex + 1) % _coverGradients.length;
                  });
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.music_note, color: Colors.white, size: 36),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.palette, size: 12, color: AppColors.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TITRE & HUMEUR',
                          style: AppTypography.labelSmall(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.offline_pin, size: 11, color: AppColors.secondaryHighlight),
                              const SizedBox(width: 3),
                              Text(
                                '100% Local',
                                style: AppTypography.labelSmall(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.titleMedium(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Nom de votre playlist...',
                        hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descController,
                      style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Ajouter une description ou ambiance...',
                        hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.glassBorderSubtle, height: 1),
          const SizedBox(height: 10),
          // Metadata quick pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPill(
                  icon: _isPrivate ? Icons.lock : Icons.lock_open,
                  label: _isPrivate ? 'Privée' : 'Publique',
                  isActive: _isPrivate,
                  onTap: () => setState(() => _isPrivate = !_isPrivate),
                ),
                const SizedBox(width: 8),
                _buildPill(
                  icon: Icons.equalizer,
                  label: _selectedBpm,
                  isActive: true,
                  onTap: _showBpmPicker,
                ),
                const SizedBox(width: 8),
                _buildPill(
                  icon: Icons.hd,
                  label: 'Audio HD / FLAC',
                  isActive: _isHiResOnly,
                  onTap: () => setState(() => _isHiResOnly = !_isHiResOnly),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryContainer.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primaryContainer : AppColors.glassBorderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSelector() {
    final sources = [
      {'title': 'Bibliothèque', 'sub': 'Parcourir dossiers', 'icon': Icons.library_music},
      {'title': 'Copilote IA', 'sub': 'Mix auto & humeur', 'icon': Icons.smart_toy, 'smart': true},
      {'title': 'Sélection Manuelle', 'sub': 'Choisir morceaux', 'icon': Icons.checklist},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOURCE DES MORCEAUX',
          style: AppTypography.labelMedium(color: AppColors.onSurfaceMuted, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (i) {
            final s = sources[i];
            final isSelected = _selectedSourceIndex == i;
            final isSmart = s['smart'] == true;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSourceIndex = i),
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isSmart
                            ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                            : AppColors.primaryContainer.withValues(alpha: 0.2))
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isSmart ? AppColors.secondaryHighlight : AppColors.primaryContainer)
                          : AppColors.glassBorderSubtle,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isSmart ? AppColors.secondaryHighlight : AppColors.primaryContainer)
                                  .withValues(alpha: 0.25),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      if (isSmart)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryHighlight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SMART',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      Icon(
                        s['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? (isSmart ? AppColors.secondaryHighlight : AppColors.primaryContainer)
                            : AppColors.onSurfaceMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s['title'] as String,
                        style: AppTypography.labelMedium(
                          color: isSelected ? AppColors.onSurface : AppColors.onSurfaceMuted,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['sub'] as String,
                        style: AppTypography.labelSmall(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAiControlsCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      customGradient: LinearGradient(
        colors: [
          AppColors.secondaryContainer.withValues(alpha: 0.2),
          AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.secondaryHighlight, size: 18),
                  const SizedBox(width: 8),
                  Text('Paramètres du Mix Intelligent', style: AppTypography.titleMedium()),
                ],
              ),
              Text(
                '${_targetTrackCount.toInt()} titres',
                style: AppTypography.labelMedium(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Humeur musicale cible :', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(mood),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMood = mood),
                    selectedColor: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.secondaryHighlight : AppColors.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Nombre de morceaux dans le mix :', style: AppTypography.labelSmall(color: AppColors.onSurfaceMuted)),
          Slider(
            value: _targetTrackCount,
            min: 5,
            max: 40,
            divisions: 7,
            label: '${_targetTrackCount.toInt()} titres',
            activeColor: AppColors.primaryContainer,
            inactiveColor: Colors.white.withValues(alpha: 0.1),
            onChanged: (val) => setState(() => _targetTrackCount = val),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.flash_on),
              label: const Text('Générer le mix instantanément', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _triggerAiGeneration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracklistPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'APERÇU DES MORCEAUX (${_stagedTracks.length})',
              style: AppTypography.labelMedium(color: AppColors.onSurfaceMuted, letterSpacing: 1.1),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              onPressed: () {
                final extra = _generateSampleMedia();
                setState(() {
                  _stagedTracks.addAll(extra.take(2));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_stagedTracks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucun morceau sélectionné. Cliquez sur générer ou ajouter.',
                style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stagedTracks.length,
            itemBuilder: (ctx, i) {
              final track = _stagedTracks[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        track.isVideo ? Icons.videocam : Icons.audiotrack,
                        size: 18,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: AppTypography.titleMedium(color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${track.artist} • ${track.format} • ${track.formattedDuration}',
                            style: AppTypography.bodySmall(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.onSurfaceMuted),
                      onPressed: () {
                        setState(() {
                          _stagedTracks.removeAt(i);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showBpmPicker() {
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
            Text('Sélectionner la plage de tempo (BPM)', style: AppTypography.headlineSmall()),
            const SizedBox(height: 12),
            ..._bpmOptions.map((bpm) => Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: const Icon(Icons.speed, color: AppColors.primaryContainer),
                    title: Text(bpm),
                    trailing: _selectedBpm == bpm
                        ? const Icon(Icons.check, color: AppColors.primaryContainer)
                        : null,
                    onTap: () {
                      setState(() => _selectedBpm = bpm);
                      Navigator.pop(ctx);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
