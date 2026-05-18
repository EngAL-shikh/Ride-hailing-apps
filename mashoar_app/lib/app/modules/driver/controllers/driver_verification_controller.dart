import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/auth_api.dart';

class DriverVerificationController extends GetxController {
  final AuthApi _authApi;
  DriverVerificationController(this._authApi);

  final nameController = RxString('');
  final bikePlateController = RxString('');
  
  final avatarFile = Rxn<File>();
  final idFrontFile = Rxn<File>();
  final idBackFile = Rxn<File>();

  final currentStep = 0.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (image != null) {
        if (type == 'avatar') avatarFile.value = File(image.path);
        if (type == 'idFront') idFrontFile.value = File(image.path);
        if (type == 'idBack') idBackFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = 'خطأ في التقاط الصورة';
    }
  }

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    } else {
      submit();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> submit() async {
    if (nameController.value.isEmpty || bikePlateController.value.isEmpty) {
      errorMessage.value = 'يرجى إكمال جميع البيانات';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      await _authApi.verifyDriver(
        fullName: nameController.value,
        bikePlate: bikePlateController.value,
        avatarPath: avatarFile.value?.path,
        idCardFrontPath: idFrontFile.value?.path,
        idCardBackPath: idBackFile.value?.path,
      );

      Get.back();
      Get.snackbar(
        'تم الإرسال',
        'تم إرسال بياناتك للمراجعة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إرسال البيانات: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
