// ─────────────────────────────────────────────
//  evidence_view.dart
//  Evidence Capture screen: Photo / Video / Audio.
//  • Requests Camera & Microphone permissions immediately upon opening.
//  • Real photo capture, video recording, and ambient audio recording.
//  • Built-in Evidence Vault with full photo preview, audio playback,
//    video details, and secure permanent file deletion.
// ─────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

class SavedEvidenceItem {
  final String path;
  final String type; // 'photo', 'video', 'audio'
  final DateTime timestamp;
  final String title;

  SavedEvidenceItem({
    required this.path,
    required this.type,
    required this.timestamp,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'title': title,
  };

  factory SavedEvidenceItem.fromJson(Map<String, dynamic> json) => SavedEvidenceItem(
    path: json['path'] as String? ?? '',
    type: json['type'] as String? ?? 'photo',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    title: json['title'] as String? ?? 'Evidence',
  );
}

class EvidenceView extends StatefulWidget {
  const EvidenceView({super.key});

  @override
  State<EvidenceView> createState() => _EvidenceViewState();
}

class _EvidenceViewState extends State<EvidenceView> {
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _selectedTab = 0; // 0=Photo, 1=Video, 2=Audio
  final tabs = ['Photo', 'Video', 'Audio'];

  bool _hasCameraPermission = false;
  bool _hasMicPermission = false;
  bool _isRecordingAudio = false;
  int _audioSeconds = 0;
  Timer? _audioTimer;

  final List<SavedEvidenceItem> _savedEvidence = [];
  static const String _kEvidencePrefsKey = 'raksha_saved_evidence_vault';

  // Audio player state
  String? _currentlyPlayingPath;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();
    _loadEvidenceFromPrefs();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = (state == PlayerState.playing);
        });
      }
    });
  }

  Future<void> _requestInitialPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (mounted) {
      setState(() {
        _hasCameraPermission = cameraGranted;
        _hasMicPermission = micGranted;
      });
    }

    if (!cameraGranted || !micGranted) {
      Get.snackbar(
        'Permissions Notice',
        'Camera and Microphone permissions enable rapid evidence recording.',
        backgroundColor: AppColors.cardBg,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _loadEvidenceFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kEvidencePrefsKey) ?? [];
      final loaded = <SavedEvidenceItem>[];
      for (final s in list) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          loaded.add(SavedEvidenceItem.fromJson(m));
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _savedEvidence.assignAll(loaded);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveEvidenceToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedEvidence.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_kEvidencePrefsKey, list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Capture Photo ────────────────────────────
  Future<void> _capturePhoto() async {
    if (!_hasCameraPermission) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        Get.snackbar('Permission Denied', 'Camera permission is required to capture photos.');
        return;
      }
      setState(() => _hasCameraPermission = true);
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _savedEvidence.insert(
            0,
            SavedEvidenceItem(
              path: photo.path,
              type: 'photo',
              timestamp: DateTime.now(),
              title: 'Photo_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
        });
        await _saveEvidenceToPrefs();
        Get.snackbar(
          '📸 Photo Saved',
          'Evidence saved securely in your vault.',
          backgroundColor: AppColors.cardBg,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Capture Error', 'Could not access camera: $e');
    }
  }

  // ── Record Video ─────────────────────────────
  Future<void> _recordVideo() async {
    if (!_hasCameraPermission || !_hasMicPermission) {
      final statuses = await [Permission.camera, Permission.microphone].request();
      if (!(statuses[Permission.camera]?.isGranted ?? false)) {
        Get.snackbar('Permission Denied', 'Camera permission is required to record video.');
        return;
      }
      setState(() {
        _hasCameraPermission = true;
        _hasMicPermission = statuses[Permission.microphone]?.isGranted ?? false;
      });
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 3),
      );
      if (video != null) {
        setState(() {
          _savedEvidence.insert(
            0,
            SavedEvidenceItem(
              path: video.path,
              type: 'video',
              timestamp: DateTime.now(),
              title: 'Video_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
        });
        await _saveEvidenceToPrefs();
        Get.snackbar(
          '🎥 Video Saved',
          'Video evidence stored safely in your vault.',
          backgroundColor: AppColors.cardBg,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Video Error', 'Could not record video: $e');
    }
  }

  // ── Record Audio ─────────────────────────────
  Future<void> _toggleAudioRecording() async {
    if (_isRecordingAudio) {
      final path = await _audioRecorder.stop();
      _audioTimer?.cancel();
      setState(() {
        _isRecordingAudio = false;
        if (path != null) {
          _savedEvidence.insert(
            0,
            SavedEvidenceItem(
              path: path,
              type: 'audio',
              timestamp: DateTime.now(),
              title: 'Audio_${DateTime.now().millisecondsSinceEpoch} (${_audioSeconds}s)',
            ),
          );
        }
      });
      await _saveEvidenceToPrefs();
      Get.snackbar(
        '🎙️ Audio Saved',
        'Ambient voice & audio recording saved as evidence.',
        backgroundColor: AppColors.cardBg,
        colorText: Colors.white,
      );
    } else {
      if (!_hasMicPermission) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          Get.snackbar('Permission Denied', 'Microphone permission required for audio recording.');
          return;
        }
        setState(() => _hasMicPermission = true);
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _audioSeconds = 0;
      _audioTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _audioSeconds++);
      });

      setState(() {
        _isRecordingAudio = true;
      });
    }
  }

  void _onMainCaptureTap() {
    if (_selectedTab == 0) {
      _capturePhoto();
    } else if (_selectedTab == 1) {
      _recordVideo();
    } else {
      _toggleAudioRecording();
    }
  }

  // ── Preview Photo ────────────────────────────
  void _viewPhoto(SavedEvidenceItem item) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: File(item.path).existsSync()
                    ? InteractiveViewer(
                        child: Image.file(File(item.path), fit: BoxFit.contain),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('File not found on device storage', style: TextStyle(color: Colors.white)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: CircleAvatar(
                backgroundColor: Colors.black87,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview Audio ────────────────────────────
  void _playAudio(SavedEvidenceItem item) {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isPlayingThis = (_currentlyPlayingPath == item.path && _isPlayingAudio);

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.primary)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.audiotrack_rounded, color: AppColors.primary, size: 40),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item.timestamp.toLocal().toString().split('.')[0],
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 24),
                IconButton.filled(
                  iconSize: 44,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: Icon(isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: () async {
                    if (isPlayingThis) {
                      await _audioPlayer.pause();
                      setSheetState(() => _isPlayingAudio = false);
                    } else {
                      _currentlyPlayingPath = item.path;
                      await _audioPlayer.play(DeviceFileSource(item.path));
                      setSheetState(() => _isPlayingAudio = true);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  isPlayingThis ? 'Playing ambient evidence recording...' : 'Tap to play audio',
                  style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Preview Video ────────────────────────────
  void _viewVideo(SavedEvidenceItem item) {
    final file = File(item.path);
    final sizeKb = file.existsSync() ? (file.lengthSync() / 1024).toStringAsFixed(1) : '0';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.primary)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 44),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.timestamp.toLocal().toString().split('.')[0]} • ${sizeKb} KB',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                label: const Text('Open in Device Player'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final uri = Uri.file(item.path);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    Get.snackbar('Notice', 'Video path: ${item.path}');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Delete Evidence ──────────────────
  void _confirmDeleteEvidence(int index) {
    final item = _savedEvidence[index];
    Get.defaultDialog(
      title: 'Delete Evidence File?',
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      backgroundColor: AppColors.cardBg,
      middleText: 'Are you sure you want to permanently delete this ${item.type} file from your device?',
      middleTextStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        try {
          final f = File(item.path);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}

        setState(() {
          _savedEvidence.removeAt(index);
        });
        await _saveEvidenceToPrefs();

        Get.back(); // close dialog
        Get.back(); // close sheet
        _showSavedEvidenceDialog(); // re-open refreshed sheet

        Get.snackbar(
          'Deleted',
          'Evidence item removed permanently.',
          backgroundColor: AppColors.cardBg,
          colorText: Colors.white,
        );
      },
    );
  }

  // ── Evidence Vault BottomSheet ────────────────
  void _showSavedEvidenceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Evidence Vault (${_savedEvidence.length})',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back()),
              ],
            ),
            const SizedBox(height: 12),
            if (_savedEvidence.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'No evidence captured yet.\nUse Photo, Video or Audio tabs to record incident proof.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _savedEvidence.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final item = _savedEvidence[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        if (item.type == 'photo') {
                          _viewPhoto(item);
                        } else if (item.type == 'audio') {
                          _playAudio(item);
                        } else {
                          _viewVideo(item);
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Icon(
                          item.type == 'photo'
                              ? Icons.image
                              : (item.type == 'video' ? Icons.videocam : Icons.mic),
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(
                        '${item.timestamp.toLocal().toString().split('.')[0]}\nTap to view / play',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
                            onPressed: () {
                              if (item.type == 'photo') {
                                _viewPhoto(item);
                              } else if (item.type == 'audio') {
                                _playAudio(item);
                              } else {
                                _viewVideo(item);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _confirmDeleteEvidence(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Evidence Capture'),
        actions: [
          IconButton(
            tooltip: 'Evidence Vault',
            icon: const Icon(Icons.folder_shared_rounded, color: AppColors.primary),
            onPressed: _showSavedEvidenceDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab selector ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final isSelected = _selectedTab == i;
                return GestureDetector(
                  onTap: () {
                    if (_isRecordingAudio) return;
                    setState(() => _selectedTab = i);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Main Viewfinder / Recording Area ─
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isRecordingAudio ? Colors.redAccent : AppColors.divider,
                  width: _isRecordingAudio ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isRecordingAudio ? Colors.redAccent : AppColors.primary)
                          .withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      _selectedTab == 0
                          ? Icons.camera_alt_outlined
                          : (_selectedTab == 1
                              ? Icons.videocam_outlined
                              : (_isRecordingAudio ? Icons.mic : Icons.mic_none_outlined)),
                      size: 48,
                      color: _isRecordingAudio ? Colors.redAccent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _selectedTab == 0
                        ? 'Tap below to capture evidence photo'
                        : (_selectedTab == 1
                            ? 'Tap below to record emergency video'
                            : (_isRecordingAudio
                                ? 'Recording Audio: 00:${_audioSeconds.toString().padLeft(2, '0')}'
                                : 'Tap to start recording ambient audio')),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'All photos, videos and sound recordings are saved timestamped directly into your secure device evidence vault.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Capture Action Button
                  GestureDetector(
                    onTap: _onMainCaptureTap,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isRecordingAudio ? Colors.redAccent : AppColors.primary,
                          width: 4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecordingAudio ? Colors.redAccent : AppColors.primary,
                          ),
                          child: Icon(
                            _selectedTab == 2
                                ? (_isRecordingAudio ? Icons.stop_rounded : Icons.mic_rounded)
                                : (_selectedTab == 1 ? Icons.videocam_rounded : Icons.camera_rounded),
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isRecordingAudio) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tap stop when finished',
                      style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Saved Evidence Vault Row ─────────────
          GestureDetector(
            onTap: _showSavedEvidenceDialog,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'View Saved Evidence (${_savedEvidence.length} items)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
