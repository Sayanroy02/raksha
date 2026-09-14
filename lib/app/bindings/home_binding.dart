import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/sos_controller.dart';
import '../services/sos_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SosService(Get.find()));
    Get.lazyPut(() => SosController(Get.find()));
    // AuthController may already exist — findOrPut avoids duplicates
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut(() => AuthController(Get.find(), Get.find()));
    }
  }
}
