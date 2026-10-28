// ─────────────────────────────────────────────
//  profile_controller.dart
//  Manages the Profile screen state.
// ─────────────────────────────────────────────
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class ProfileController extends GetxController {
  final StorageService _storage;
  ProfileController(this._storage);

  final Rx<UserModel?> user = Rx(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    // 1. Instant local cache load
    final json = await _storage.getUserData();
    if (json != null) {
      try {
        user.value = UserModel.fromJsonString(json);
      } catch (_) {}
    }

    // 2. Fetch fresh profile from backend
    if (Get.isRegistered<AuthService>()) {
      try {
        final resp = await Get.find<AuthService>().getMe();
        if (resp.statusCode == 200 && resp.data != null) {
          final u = UserModel.fromJson(resp.data as Map<String, dynamic>);
          user.value = u;
          await _storage.saveUserData(u.toJsonString());
        }
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
