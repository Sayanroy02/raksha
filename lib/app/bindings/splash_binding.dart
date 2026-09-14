import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/sos_service.dart';

/// Registers the core services that every screen needs.
/// Runs before the splash screen is shown.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StorageService(),   permanent: true);
    Get.put(ApiService(),       permanent: true);
    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(SosService(Get.find()), permanent: true);
    Get.put(PermissionService(), permanent: true);
  }
}
