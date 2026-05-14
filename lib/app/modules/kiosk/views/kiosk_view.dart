import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:barcode/barcode.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import '../controllers/kiosk_controller.dart';
import 'service_detail_page.dart';

class KioskView extends GetView<KioskController> {
  const KioskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Background Pattern
            Opacity(
              opacity: 0,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/line-nam-bg.png'),
                    repeat: ImageRepeat.repeat,
                    scale: 0.5,
                  ),
                ),
              ),
            ),

            // Main Content
            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SizedBox.expand(
                  key: ValueKey(controller.currentStep.value),
                  child: _buildStep(controller.currentStep.value),
                ),
              ),
            ),

            // Progress Indicator
            Obx(() {
              if (controller.currentStep.value > 1 &&
                  controller.currentStep.value < 8) {
                return Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      int step = index + 1;
                      bool isActive = step == controller.currentStep.value;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 10,
                        width: isActive ? 40 : 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ColorConstants.mainCorlor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Hidden Admin Tap Area (Top-Right)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: controller.handleAdminTap,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
            // Back Button (Top-Left)
            Obx(() {
              if (controller.currentStep.value > 0) {
                return Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: Colors.black87,
                      onPressed: controller.prevStep,
                      tooltip: 'Back',
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildPrinterSetup();
      case 1:
        return _buildWelcomeStep();
      case 2:
        return _buildGenderStep();
      case 3:
        return _buildAgeStep();
      case 4:
        return _buildDisabilityStep();
      case 5:
        return _buildPurposeStep();
      case 6:
        return _buildServiceChoiceStep();
      case 7:
        return _buildServiceStep();
      case 8:
        return _buildTicketResultStep();
      case 9:
        return _buildServiceStep(isViewOnly: true);
      case 10:
        return _buildFeedbackStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step UI Implementation ---

  Widget _buildStepContainer({
    required String title,
    String? subtitle,
    required Widget child,
    bool isScrollable = false,
    bool compactHeader = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 40,
        vertical: compactHeader ? 10 : 20,
      ),
      child: Column(
        children: [
          if (!compactHeader) const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/main-logo.jpg',
                  height: compactHeader ? 50 : 80,
                ),
              ),
            ],
          ),
          SizedBox(height: compactHeader ? 12 : 24),
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: compactHeader ? 32 : 42,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            SizedBox(height: compactHeader ? 4 : 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: compactHeader ? 18 : 22,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: compactHeader ? 16 : 32),
          if (isScrollable) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return _buildStepContainer(
      title: 'Smart ODSC',
      subtitle: 'ຍິນດີຕ້ອນຮັບສູ່ ບໍລິການປະຕູດຽວຂອງລັດຖະບານ ສປປ ລາວ',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWelcomeButton(
            label: 'ຄຳຕິຊົມ',
            icon: Icons.chat_outlined,
            color: Colors.orange,
            onTap: () {
              controller.currentStep.value = 10;
            },
          ),
          const SizedBox(width: 40),
          _buildShimmerWelcomeButton(
            label: 'ກົດບັດຄິວ',
            icon: Icons.touch_app_rounded,
            color: ColorConstants.mainCorlor,
            onTap: controller.nextStep,
          ),
          const SizedBox(width: 40),
          _buildWelcomeButton(
            label: 'ລາຍການບໍລິການ',
            icon: Icons.grid_view_rounded,
            color: Colors.blue,
            onTap: () {
              controller.currentStep.value = 9;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color.withOpacity(0.9),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerWelcomeButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _ShimmerButton(label: label, icon: icon, color: color, onTap: onTap);
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      title: 'ເພດຂອງທ່ານ',
      subtitle: 'ກະລຸນາເລືອກເພດຂອງທ່ານ',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            label: 'ຊາຍ',
            icon: Icons.male,
            color: Colors.blue,
            onTap: () {
              controller.gender.value = "MALE";
              controller.nextStep();
            },
          ),
          const SizedBox(width: 40),
          _buildOptionCard(
            label: 'ຍິງ',
            icon: Icons.female,
            color: Colors.pink,
            onTap: () {
              controller.gender.value = "FEMALE";
              controller.nextStep();
            },
          ),
          const SizedBox(width: 40),
          _buildOptionCard(
            label: 'ອື່ນໆ',
            icon: Icons.transgender,
            color: Colors.purple,
            onTap: () {
              controller.gender.value = "OTHER";
              controller.nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeStep() {
    final ages = [
      {'label': '0 - 12 ປີ', 'value': 'AGE_0_12'},
      {'label': '13 - 20 ປີ', 'value': 'AGE_13_20'},
      {'label': '21 - 35 ປີ', 'value': 'AGE_21_35'},
      {'label': '36 - 45 ປີ', 'value': 'AGE_36_45'},
      {'label': '46 - 60 ປີ', 'value': 'AGE_46_60'},
      {'label': '60 ປີ ຂຶ້ນໄປ', 'value': 'AGE_60_UP'},
    ];

    return _buildStepContainer(
      title: 'ອາຍຸຂອງທ່ານ',
      subtitle: 'ກະລຸນາເລືອກຊ່ວງອາຍຸຂອງທ່ານ',
      child: SizedBox(
        width: 800,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.8,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
          ),
          itemCount: ages.length,
          itemBuilder: (context, index) {
            final age = ages[index];
            return _buildWideButton(
              label: age['label']!,
              onTap: () {
                controller.ageRange.value = age['value']!;
                controller.nextStep();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDisabilityStep() {
    return _buildStepContainer(
      title: 'ທ່ານມີຄວາມພິການບໍ່?',
      subtitle: '',
      child: Column(
        children: [
          // PROMINENT "NO" BUTTON (Majority case)
          InkWell(
            onTap: () {
              controller.isDisabled.value = false;
              controller.nextStep();
            },
            child: Container(
              width: 500,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'ບໍ່ແມ່ນ (ຂ້ອຍບໍ່ພິການ)',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
          // SUBTLE "YES" OPTION
          InkWell(
            onTap: () {
              controller.isDisabled.value = true;
              controller.nextStep();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.accessible, color: Colors.orange, size: 30),
                  SizedBox(width: 16),
                  Text(
                    'ແມ່ນ, ຂ້ອຍມີຄວາມພິການ (ຕ້ອງການຄວາມຊ່ວຍເຫຼືອ)',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeStep() {
    return _buildStepContainer(
      title: 'ຈຸດປະສົງ',
      subtitle: 'ກະລຸນາເລືອກຈຸດປະສົງການມາໃນຄັ້ງນີ້',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            label: 'ສອບຖາມຂໍ້ມູນ',
            icon: Icons.help_outline,
            color: Colors.blue,
            onTap: () {
              controller.visitPurpose.value = 'INQUIRY';
              controller.nextStep();
            },
          ),
          const SizedBox(width: 40),
          _buildOptionCard(
            label: 'ມາໃຊ້ບໍລິການ',
            icon: Icons.business_center,
            color: Colors.green,
            onTap: () {
              controller.visitPurpose.value = 'SERVICE';
              controller.nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChoiceStep() {
    return _buildStepContainer(
      title: 'ເລືອກບໍລິການ',
      subtitle: 'ທ່ານຕ້ອງການເລຶອກບໍລິການບໍ່?',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ທ່ານຕ້ອງການເລຶອກບໍລິການບໍ່ (ຫຼືຖ້າຍັງບໍ່ແນ່ໃຈສາມາດຂ້າມຂັ້ນຕອນນີ້ໄດ້)',
              style: const TextStyle(fontSize: 28, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionCard(
                label: 'ເລືອກບໍລິການ',
                icon: Icons.list_alt,
                color: ColorConstants.mainCorlor,
                onTap: controller.nextStep,
              ),
              const SizedBox(width: 60),
              _buildOptionCard(
                label: 'ຂ້າມຂັ້ນຕອນນີ້',
                icon: Icons.skip_next,
                color: Colors.orange,
                onTap: () => controller.submitBooking(
                  "",
                  "ບໍ່ລະບຸບໍລິການ",
                ), // Empty ID for unspecified
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStep({bool isViewOnly = false}) {
    return _buildStepContainer(
      title: 'ລາຍການບໍລິການ',
      subtitle: isViewOnly
          ? 'ທ່ານສາມາດເບິ່ງຂໍ້ມູນບໍລິການທັງໝົດໄດ້ທີ່ນີ້'
          : 'ກະລຸນາເລືອກບໍລິການທີ່ທ່ານຕ້ອງການ',
      isScrollable: true,
      child: Column(
        children: [
          // PREMIUM SEARCH BAR
          Container(
            width: 800,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onSubmitted: controller.onSearch,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາບໍລິການທີ່ນີ້...',
                hintStyle: TextStyle(fontSize: 22, color: Colors.grey[400]),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 15),
                  child: Icon(
                    Icons.search_rounded,
                    size: 36,
                    color: ColorConstants.mainCorlor,
                  ),
                ),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 28),
                        onPressed: controller.clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 22),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: ColorConstants.mainCorlor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: ColorConstants.mainCorlor,
                  ),
                );
              }

              if (controller.services.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ບໍ່ພົບຂໍ້ມູນບໍລິການ',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: controller.clearSearch,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'ລຶບການຄົ້ນຫາ',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RawScrollbar(
                thumbColor: ColorConstants.mainCorlor.withOpacity(0.35),
                thickness: 10,
                radius: const Radius.circular(10),
                thumbVisibility: true,
                interactive: true,
                child: GridView.builder(
                  padding: const EdgeInsets.only(right: 25, bottom: 40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8, // Slightly more square/professional
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: controller.services.length,
                  itemBuilder: (context, index) {
                    final service = controller.services[index];
                    final serviceId = service['id']?.toString() ?? "";
                    final serviceName =
                        service['name']?.toString() ?? "ບໍ່ລະບຸຊື່ບໍລິການ";

                    return _buildServiceCard(
                      label: serviceName,
                      icon: service['icon']?.toString(),
                      onTap: () => Get.to(
                        () => ServiceDetailPage(
                          serviceId: serviceId,
                          serviceName: serviceName,
                          isViewOnly: isViewOnly,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String label,
    String? icon,
    required VoidCallback onTap,
  }) {
    final String iconUrl = icon != null && icon.isNotEmpty
        ? "https://storage-console.odsc.gov.la/odsc-public-storage/images/original/$icon"
        : "";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  // background removed so icon/image displays without colored bg
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.account_balance_rounded,
                            color: ColorConstants.mainCorlor,
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.account_balance_rounded,
                          color: ColorConstants.mainCorlor,
                          size: 32,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketResultStep() {
    return _buildStepContainer(
      title: 'ສຳເລັດແລ້ວ!',
      subtitle: 'ກະລຸນາຮັບບັດຄິວຂອງທ່ານ',
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 850,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // LEFT SIDE: Queue Info
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 60,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'ບັດຄິວຂອງທ່ານ',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            Obx(
                              () => Text(
                                controller.queueNumber.value,
                                style: const TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Obx(
                              () => Text(
                                controller.selectedServiceName.value,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(
                        thickness: 1.5,
                        color: Colors.grey,
                        indent: 20,
                        endIndent: 20,
                      ),
                      // RIGHT SIDE: Tracking Info
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ສະແກນເພື່ອຕິດຕາມຄິວ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '(Scan to Track Status)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: BarcodeWidget(
                                  barcode: Barcode.qrCode(),
                                  data: controller.trackingUrl.value,
                                  width: 140,
                                  height: 140,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildWideButton(
                label: 'ກັບຄືນຫາໜ້າຫຼັກ',
                onTap: controller.resetBooking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterSetup() {
    return _buildStepContainer(
      title: 'ຕັ້ງຄ່າເຄື່ອງພິມ',
      subtitle: 'ກະລຸນາເຊື່ອມຕໍ່ເຄື່ອງພິມກ່ອນເລີ່ມຕົ້ນ',
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => Get.toNamed('/printer'),
            child: const Text('ໄປທີ່ໜ້າຕັ້ງຄ່າເຄື່ອງພິມ'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.nextStep,
            child: const Text('ຂ້າມໄປກ່ອນ'),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 80, color: color),
                ),
                const SizedBox(height: 24),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[100]!, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackStep() {
    return _buildStepContainer(
      title: 'ຄຳຕິຊົມ',
      subtitle: 'ທ່ານສາມາດສະແດງຄວາມຄິດເຫັນເພື່ອປັບປຸງບໍລິການຂອງພວກເຮົາ',
      isScrollable: true,
      compactHeader: true,
      child: Obx(() {
        if (controller.isFeedbackSubmitted.value) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Success Icon
                  Container(
                    width: 180,
                    height: 180,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF455C91).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt_rounded, // Similar to "Like" icon
                      size: 100,
                      color: Color(0xFFF49D79),
                    ),
                  ),
                  const Text(
                    'ຂອບໃຈສຳລັບຄວາມຄິດເຫັນຂອງທ່ານ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF455C91),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: Text(
                      'ເປັນສ່ວນໜຶ່ງທີ່ຊ່ວຍໃຫ້ພວກເຮົາພັດທະນາໃຫ້ດີຂຶ້ນກວ່າເກົ່າ ຂໍຂອບໃຈ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xB3455C91),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: 400,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => controller.resetBooking(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF47939),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'ສຳເລັດ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: SingleChildScrollView(
            child: Container(
              width: 800,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Step 1: Reference Number
                  const Text(
                    'ຂັ້ນຕອນທີ 1: ກະລຸນາປ້ອນ ເລກອ້າງອີງຂອງທ່ານ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF455C91),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 500,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF455C91).withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF455C91).withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                      child: TextField(
                        controller: controller.feedbackReferenceController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF455C91),
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'XXXXXXXX',
                          counterText: "",
                          hintStyle: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            letterSpacing: 1,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                        ),
                      ),
                  ),
                  const SizedBox(height: 50),

                  // Step 2 Label
                  const Text(
                    'ຂັ້ນຕອນທີ 2: ໃຫ້ຄະແນນຄວາມເພິ່ງພໍໃຈ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF455C91),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Satisfaction Buttons
                  Obx(() {
                    final levels = [
                      {
                        'label': 'ດີເລີດ',
                        'rating': 5,
                        'icon': Icons.sentiment_very_satisfied_rounded,
                        'color': const Color(0xFF4CAF50),
                      },
                      {
                        'label': 'ດີ',
                        'rating': 4,
                        'icon': Icons.sentiment_satisfied_alt_rounded,
                        'color': const Color(0xFF8BC34A),
                      },
                      {
                        'label': 'ປານກາງ',
                        'rating': 3,
                        'icon': Icons.sentiment_neutral_rounded,
                        'color': const Color(0xFFFFC107),
                      },
                      {
                        'label': 'ຄວນປັບປຸງ',
                        'rating': 2,
                        'icon': Icons.sentiment_dissatisfied_rounded,
                        'color': const Color(0xFFFF9800),
                      },
                      {
                        'label': 'ບໍ່ພໍໃຈ',
                        'rating': 1,
                        'icon': Icons.sentiment_very_dissatisfied_rounded,
                        'color': const Color(0xFFF44336),
                      },
                    ];

                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: levels.map((level) {
                        final bool isSelected =
                            controller.feedbackRating.value == level['rating'];
                        final Color color = level['color'] as Color;

                        return GestureDetector(
                          onTap: () {
                            controller.selectRating(
                              level['rating'] as int,
                              level['label'] as String,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 140,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : color.withOpacity(0.2),
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  level['icon'] as IconData,
                                  size: 60,
                                  color: isSelected ? Colors.white : color,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  level['label'] as String,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  // Optional Comment Area
                  Obx(() {
                    // Show comment area only after a rating is selected
                    if (controller.feedbackRating.value == 0) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 48),
                        const Text(
                          'ເພີ່ມເຕີມ (ຖ້າມີ)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF455C91),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF455C91).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: controller.feedbackCommentController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ພິມຂໍ້ຄວາມຂອງທ່ານທີ່ນີ້...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Submit Button
                        Obx(
                          () => SizedBox(
                            width: 400,
                            height: 80,
                            child: ElevatedButton(
                              onPressed: controller.isSubmittingFeedback.value
                                  ? null
                                  : () async {
                                      final success = await controller
                                          .submitFeedback();
                                      if (!success) {
                                        CustomDialog.showError(
                                          title: 'ຜິດພາດ',
                                          message:
                                              'ບໍ່ສາມາດສົ່ງຄຳຕິຊົມໄດ້ ກະລຸນາລອງໃໝ່',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF47939),
                                disabledBackgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                              ),
                              child: controller.isSubmittingFeedback.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'ສົ່ງຄຳຕິຊົມ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ShimmerButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShimmerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<_ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double value = _controller.value * 4.0 - 2.0; // -2.0 to 2.0 range
        // Pulse effect tied to the shimmer cycle
        double scale =
            1.0 + (0.03 * (1.0 - (value.abs() / 2.0).clamp(0.0, 1.0)));

        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, size: 120, color: Colors.white),
                          const SizedBox(height: 24),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Shimmer Light Effect (Sharper for metallic look)
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(-1.0 + value, -1.0),
                            end: Alignment(1.0 + value, 1.0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.6), // Brighter center
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.0),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 0.45, 0.5, 0.55, 0.6, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcOver,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
