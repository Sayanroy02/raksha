// ─────────────────────────────────────────────
//  profile_controller.dart
//  Manages the Profile screen state.
// ─────────────────────────────────────────────
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../routes/app_routes.dart';

class ProfileController extends GetxController {
  final StorageService _storage;
  ProfileController(this._storage);

  final Rx<UserModel?> user = Rx(null);

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final json = await _storage.getUserData();
    if (json != null) {
      user.value = UserModel.fromJsonString(json);
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    Get.offAllNamed(AppRoutes.login);
  }
}
