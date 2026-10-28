import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/sos_service.dart';
import '../services/contacts_service.dart';

import '../controllers/auth_controller.dart';
import '../controllers/sos_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/contacts_controller.dart';
import '../controllers/profile_controller.dart';

/// Registers all core services and central controllers permanently
/// so no page ever crashes with 'Controller not found'.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StorageService(), permanent: true);
    Get.put(ApiService(), permanent: true);
    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(SosService(Get.find()), permanent: true);
    Get.put(ContactsService(Get.find()), permanent: true);
    Get.put(PermissionService(), permanent: true);

    // Core Controllers (always available app-wide)
    Get.put(AuthController(Get.find(), Get.find()), permanent: true);
    Get.put(SosController(Get.find()), permanent: true);
    Get.put(LocationController(), permanent: true);
    Get.put(ContactsController(Get.find()), permanent: true);
    Get.put(ProfileController(Get.find()), permanent: true);
  }
}
