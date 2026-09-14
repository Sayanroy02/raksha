import 'package:get/get.dart';
import '../controllers/threat_controller.dart';

class ThreatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ThreatController());
  }
}
