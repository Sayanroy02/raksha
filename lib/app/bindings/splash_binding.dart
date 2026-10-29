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

/// Registers all core services and sets up lazy, resilient controllers
/// with fenix: true so nothing blocks startup on the splash screen,
/// and controllers are always available across all page transitions.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StorageService(), permanent: true);
    Get.put(ApiService(), permanent: true);
    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(SosService(Get.find()), permanent: true);
    Get.put(ContactsService(Get.find()), permanent: true);
    Get.put(PermissionService(), permanent: true);

    // Lazy load controllers with fenix: true.
    // They are instantiated ONLY when a page actually accesses them, preventing
    // premature network requests or GPS permission dialogs on splash screen!
    Get.lazyPut(() => AuthController(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => SosController(Get.find()), fenix: true);
    Get.lazyPut(() => LocationController(), fenix: true);
    Get.lazyPut(() => ContactsController(Get.find()), fenix: true);
    Get.lazyPut(() => ProfileController(Get.find()), fenix: true);
  }
}
