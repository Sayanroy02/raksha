import 'package:get/get.dart';
import '../controllers/contacts_controller.dart';
import '../services/contacts_service.dart';

class ContactsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ContactsService(Get.find()));
    Get.lazyPut(() => ContactsController(Get.find()));
  }
}
