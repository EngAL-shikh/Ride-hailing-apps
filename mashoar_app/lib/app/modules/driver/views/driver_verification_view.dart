import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../controllers/driver_verification_controller.dart';
import '../../../theme/app_theme.dart';

class DriverVerificationView extends GetView<DriverVerificationController> {
  const DriverVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827), // Midnight deep background
        appBar: AppBar(
          title: const Text('توثيق الحساب'),
          elevation: 0,
          backgroundColor: const Color(0xFF1F2937), // Matches stepper header
          foregroundColor: Colors.white,
        ),
        body: Obx(() {
          return Column(
            children: [
              // Progress Indicator
              _buildProgressHeader(),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (controller.currentStep.value == 0) _buildStep1(),
                      if (controller.currentStep.value == 1) _buildStep2(),
                      if (controller.currentStep.value == 2) _buildStep3(),
                      
                      const SizedBox(height: 32),
                      
                      if (controller.errorMessage.value != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            controller.errorMessage.value!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              _buildBottomButtons(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(0, 'البيانات', Iconsax.user_edit),
          _buildConnector(0),
          _buildStepIndicator(1, 'الصور', Iconsax.camera),
          _buildConnector(1),
          _buildStepIndicator(2, 'المستندات', Iconsax.document_text_1),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = controller.currentStep.value >= step;
    final isCurrent = controller.currentStep.value == step;
    
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF10B981) : const Color(0xFF374151),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int afterStep) {
    final isCompleted = controller.currentStep.value > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF374151),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أخبرنا عنك قليلاً',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'الاسم الرباعي يساعد الركاب على الوثوق بك أكثر.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          label: 'الاسم الرباعي',
          hint: 'أدخل اسمك الكامل',
          icon: Iconsax.user,
          onChanged: (v) => controller.nameController.value = v,
          initialValue: controller.nameController.value,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'رقم لوحة الدراجة',
          hint: 'مثال: 1234 ص - أ',
          icon: Iconsax.driving,
          onChanged: (v) => controller.bikePlateController.value = v,
          initialValue: controller.bikePlateController.value,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'صورتك الشخصية',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'الصورة الواضحة تزيد من فرصة قبول رحلاتك بنسبة 40%.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: GestureDetector(
            onTap: () => controller.pickImage('avatar'),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F2937),
                border: Border.all(
                  color: controller.avatarFile.value != null 
                    ? const Color(0xFF10B981) 
                    : Colors.white.withOpacity(0.1),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: controller.avatarFile.value != null
                  ? DecorationImage(
                      image: FileImage(controller.avatarFile.value!),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: controller.avatarFile.value == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.camera,
                        size: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة صورة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'مستندات الهوية',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'سنقوم بالتحقق من هويتك لضمان أمان الجميع.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        _buildImagePickerBox(
          label: 'وجه الهوية / الجواز',
          file: controller.idFrontFile.value,
          onTap: () => controller.pickImage('idFront'),
          icon: Iconsax.card_pos,
        ),
        const SizedBox(height: 20),
        _buildImagePickerBox(
          label: 'خلفية الهوية',
          file: controller.idBackFile.value,
          onTap: () => controller.pickImage('idBack'),
          icon: Iconsax.card_send,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerBox({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: file != null ? const Color(0xFF10B981) : Colors.white.withOpacity(0.05),
                width: file != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              image: file != null
                ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                : null,
            ),
            child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط للالتقاط',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, Get.context!.mediaQueryPadding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.currentStep.value > 0)
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: controller.previousStep,
                child: const Text(
                  'السابق',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          if (controller.currentStep.value > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF10B981).withOpacity(0.4),
              ),
              child: controller.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    controller.currentStep.value == 2 ? 'إرسال المعلومات' : 'المتابعة',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
