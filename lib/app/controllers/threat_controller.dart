// ─────────────────────────────────────────────
//  threat_controller.dart
//  Simulates AI threat detection scanning —
//  cycles through detection checks with animated
//  status updates and a spinning ring animation.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:get/get.dart';

/// Status of a single detection check
enum CheckStatus { pending, scanning, done }

class ThreatCheck {
  final String label;
  final Rxn<CheckStatus> status;
  ThreatCheck(this.label) : status = Rxn(CheckStatus.pending);
}

class ThreatController extends GetxController {
  // ── Scanning state ───────────────────────────
  final RxBool   isScanning    = false.obs;
  final RxDouble ringAngle     = 0.0.obs; // drives the rotating ring animation
  final RxString statusText    = 'Tap to scan surroundings'.obs;
  final RxBool   threatFound   = false.obs;

  // The four detection checks shown in the UI
  late final List<ThreatCheck> checks;

  Timer? _rotateTimer;
  Timer? _scanTimer;

  @override
  void onInit() {
    super.onInit();
    checks = [
      ThreatCheck('Audio analysis'),
      ThreatCheck('Visual pattern detection'),
      ThreatCheck('Location risk level'),
      ThreatCheck('Crowd behaviour'),
    ];
  }

  // ── Public API ───────────────────────────────

  void startScan() {
    if (isScanning.value) return;
    isScanning.value = true;
    statusText.value = 'Analyzing surroundings for potential threats...';
    threatFound.value = false;

    // Reset all checks
    for (final c in checks) {
      c.status.value = CheckStatus.pending;
    }

    // Spin the ring
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      ringAngle.value = (ringAngle.value + 2) % 360;
    });

    // Sequentially mark checks as scanning → done with 1.2 s delay each
    _runChecksSequentially();
  }

  void stopScan() {
    _rotateTimer?.cancel();
    _scanTimer?.cancel();
    isScanning.value = false;
    statusText.value = 'Scan complete';
    ringAngle.value  = 0;
  }

  // ── Private ──────────────────────────────────

  Future<void> _runChecksSequentially() async {
    for (int i = 0; i < checks.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!isScanning.value) break;
      checks[i].status.value = CheckStatus.scanning;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!isScanning.value) break;
      checks[i].status.value = CheckStatus.done;
    }
    // Finished
    if (isScanning.value) {
      _rotateTimer?.cancel();
      isScanning.value = false;
      // Randomly simulate "safe" result for demo
      threatFound.value = false;
      statusText.value  = 'Area appears safe. Stay alert.';
    }
  }

  @override
  void onClose() {
    _rotateTimer?.cancel();
    _scanTimer?.cancel();
    super.onClose();
  }
}
