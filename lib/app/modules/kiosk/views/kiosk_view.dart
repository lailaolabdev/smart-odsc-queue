import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:barcode/barcode.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import 'package:smart_odsc_queue/app/shared/widgets/language_switcher.dart';
import 'package:smart_odsc_queue/app/shared/widgets/loading_indicator.dart';
import '../controllers/kiosk_controller.dart';
import 'service_detail_page.dart';

class KioskView extends GetView<KioskController> {
  const KioskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Let the keyboard *overlay* the kiosk page instead of shrinking
      // it. Default `true` was causing a transient "bottom overflowed
      // by 18 pixels" on the services-list step when the Lao on-screen
      // keyboard slid up: the Column had to redistribute height while
      // the search bar and grid were still measuring. With overlay, the
      // body stays the same size — search bar stays put at the top, the
      // keyboard simply covers the lower portion of the grid, and there
      // is no layout shift to fail.
      resizeToAvoidBottomInset: false,
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

            // Main Content — instant swap (no cross-fade) so fast taps
            // don't produce eye-straining overlap between steps.
            Obx(
              () => SizedBox.expand(
                child: _buildStep(controller.currentStep.value),
              ),
            ),

            // Progress Indicator
            //
            // Step 8 (services list) has its own page-1/2 pagination row at
            // the bottom — showing the step-indicator dots there as well
            // stacks two pagination-looking widgets on top of each other.
            // So we hide the indicator on step 8 (and on step 12, the
            // print/photo choice, which is reached via Skip and shouldn't
            // pretend to be part of the linear flow).
            Obx(() {
              final step = controller.currentStep.value;
              if (step > 1 && step < 8) {
                return Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(8, (index) {
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

            // Hidden Admin Tap Area (Top-Right).
            //
            // 140x140 so staff can hit it reliably on a large kiosk
            // display, and `HitTestBehavior.opaque` so we *win* the
            // gesture arena against the outer body GestureDetector
            // (the unfocus handler). With `translucent`, both
            // recognizers competed for the same tap and the outer one
            // would sometimes claim it, swallowing the admin gesture.
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: controller.handleAdminTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 140,
                  height: 140,
                  color: Colors.transparent,
                ),
              ),
            ),
            // Back Button (Top-Left) — hidden on the welcome step (1)
            // because there is nothing to go back to once the kiosk is
            // the app's root route. White pill + soft shadow so it
            // never gets visually swallowed by step content sitting near
            // the top of the page (titles, logos, service cards).
            Obx(() {
              if (controller.currentStep.value > 1) {
                return Positioned(
                  top: 24,
                  left: 24,
                  child: SafeArea(
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.18),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: controller.prevStep,
                        child: Tooltip(
                          message: 'common.back'.tr,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xFF1A1A1A),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
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
      case 1:
        return _buildWelcomeStep();
      case 2:
        return _buildGenderStep();
      case 3:
        return _buildAgeStep();
      case 4:
        return _buildEthnicityStep();
      case 5:
        return _buildDisabilityStep();
      case 6:
        return _buildPurposeStep();
      case 7:
        return _buildServiceChoiceStep();
      case 8:
        return _buildServiceStep();
      case 9:
        return _buildTicketResultStep();
      case 10:
        return _buildServiceStep(isViewOnly: true);
      case 11:
        return _buildFeedbackStep();
      case 12:
        return _buildPrintChoiceStep();
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
    bool showLogo = true,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 40,
        vertical: compactHeader ? 10 : 20,
      ),
      child: Column(
        children: [
          if (showLogo) ...[
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
          ] else
            // Keep top padding consistent when the logo is hidden so the
            // title doesn't slam into the back-button row.
            SizedBox(height: compactHeader ? 24 : 60),
          if (title.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (title == 'feedback.title'.tr) {
                  Get.find<KioskController>().handleFeedbackTitleTap();
                }
              },
              child: Text(
                title,
                style: TextStyle(
                  fontSize: compactHeader ? 32 : 42,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
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
    // Language switcher floats at top-right OF the welcome step (not the
    // outer Stack) so it disappears as soon as the user advances past
    // step 1 — keeping the queue flow itself uncluttered.
    return Stack(
      children: [
        _buildStepContainer(
          title: 'welcome.title'.tr,
          subtitle: 'welcome.subtitle'.tr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWelcomeButton(
                label: 'welcome.feedback_button'.tr,
                icon: Icons.chat_outlined,
                color: Colors.orange,
                onTap: () {
                  controller.currentStep.value = 11;
                },
              ),
              const SizedBox(width: 40),
              _buildShimmerWelcomeButton(
                label: 'welcome.queue_button'.tr,
                icon: Icons.touch_app_rounded,
                color: ColorConstants.mainCorlor,
                onTap: controller.nextStep,
              ),
              const SizedBox(width: 40),
              _buildWelcomeButton(
                label: 'welcome.directory_button'.tr,
                icon: Icons.grid_view_rounded,
                color: Colors.blue,
                onTap: () {
                  controller.currentStep.value = 10;
                },
              ),
            ],
          ),
        ),
        // Language toggle pinned top-right. Offset 160px from the right
        // edge so it doesn't sit on top of the 140x140 hidden admin tap
        // zone in the outer Stack (140 zone width + 20px breathing room).
        const Positioned(
          top: 24,
          right: 160,
          child: SafeArea(child: LanguageSwitcher()),
        ),
      ],
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
      title: 'step.gender.title'.tr,
      subtitle: 'step.gender.subtitle'.tr,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildChoiceTile(
                label: 'gender.male'.tr,
                icon: Icons.male_rounded,
                accent: const Color(0xFF4A90E2),
                onTap: () {
                  controller.gender.value = "MALE";
                  controller.nextStep();
                },
              ),
              _buildChoiceTile(
                label: 'gender.female'.tr,
                icon: Icons.female_rounded,
                accent: const Color(0xFFE91E63),
                onTap: () {
                  controller.gender.value = "FEMALE";
                  controller.nextStep();
                },
              ),
              _buildChoiceTile(
                label: 'gender.other'.tr,
                icon: Icons.transgender_rounded,
                accent: const Color(0xFF7E57C2),
                onTap: () {
                  controller.gender.value = "OTHER";
                  controller.nextStep();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Premium gender card — round accent-gradient badge + slate label
  // + decorative underline + tap hint. Wrap-driven so 3 fit at 1080px
  // portrait kiosk and gracefully wrap at narrower test screens.
  Widget _buildChoiceTile({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    const Color slate = Color(0xFF455C91);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: accent.withOpacity(0.12),
        highlightColor: accent.withOpacity(0.06),
        child: Ink(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: slate.withOpacity(0.10), width: 2),
            boxShadow: [
              BoxShadow(
                color: slate.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accent.withOpacity(0.85), accent],
                    radius: 0.75,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Icon(icon, size: 88, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: slate,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'common.tap_to_select'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: slate.withOpacity(0.55),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEthnicityStep() {
    final ethnicities = [
      {'label': 'ethnicity.lao'.tr, 'value': 'LAO'},
      {'label': 'ethnicity.khmu'.tr, 'value': 'KHMU'},
      {'label': 'ethnicity.hmong'.tr, 'value': 'HMONG'},
      {'label': 'ethnicity.other'.tr, 'value': 'OTHER'},
    ];

    return _buildStepContainer(
      title: 'step.ethnicity.title'.tr,
      subtitle: 'step.ethnicity.subtitle'.tr,
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
          itemCount: ethnicities.length,
          itemBuilder: (context, index) {
            final item = ethnicities[index];
            return _buildWideButton(
              label: item['label']!,
              onTap: () {
                controller.ethnicity.value = item['value']!;
                controller.nextStep();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    final ages = [
      {'label': 'age.0_12'.tr, 'value': 'AGE_0_12'},
      {'label': 'age.13_20'.tr, 'value': 'AGE_13_20'},
      {'label': 'age.21_35'.tr, 'value': 'AGE_21_35'},
      {'label': 'age.36_45'.tr, 'value': 'AGE_36_45'},
      {'label': 'age.46_60'.tr, 'value': 'AGE_46_60'},
      {'label': 'age.60_up'.tr, 'value': 'AGE_60_UP'},
    ];

    return _buildStepContainer(
      title: 'step.age.title'.tr,
      subtitle: 'step.age.subtitle'.tr,
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
      title: 'step.disability.title'.tr,
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
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'step.disability.no'.tr,
                    style: const TextStyle(
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.accessible, color: Colors.orange, size: 30),
                  const SizedBox(width: 16),
                  Text(
                    'step.disability.yes'.tr,
                    style: const TextStyle(
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
      title: 'step.purpose.title'.tr,
      subtitle: 'step.purpose.subtitle'.tr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            label: 'purpose.inquiry'.tr,
            icon: Icons.help_outline,
            color: Colors.blue,
            onTap: () {
              controller.visitPurpose.value = 'INQUIRY';
              controller.nextStep();
            },
          ),
          const SizedBox(width: 40),
          _buildOptionCard(
            label: 'purpose.service_usage'.tr,
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
      title: 'step.service_choice.title'.tr,
      subtitle: 'step.service_choice.subtitle'.tr,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'step.service_choice.helper'.tr,
              style: const TextStyle(fontSize: 28, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionCard(
                label: 'step.service_choice.pick'.tr,
                icon: Icons.list_alt,
                color: ColorConstants.mainCorlor,
                onTap: controller.nextStep,
              ),
              const SizedBox(width: 60),
              _buildOptionCard(
                label: 'step.service_choice.skip'.tr,
                icon: Icons.skip_next,
                color: Colors.orange,
                onTap: controller.goToPrintChoice,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrintChoiceStep() {
    return _buildStepContainer(
      title: 'step.print_choice.title'.tr,
      subtitle: 'step.print_choice.subtitle'.tr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            label: 'step.print_choice.print'.tr,
            icon: Icons.print_rounded,
            color: ColorConstants.mainCorlor,
            onTap: () {
              controller.skipPrint.value = false;
              controller.submitBooking(
                "",
                'step.service_choice.unspecified'.tr,
              );
            },
          ),
          const SizedBox(width: 60),
          _buildOptionCard(
            label: 'step.print_choice.photo'.tr,
            icon: Icons.qr_code_2,
            color: Colors.orange,
            onTap: () {
              controller.skipPrint.value = true;
              controller.submitBooking(
                "",
                'step.service_choice.unspecified'.tr,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStep({bool isViewOnly = false}) {
    // Custom layout (not _buildStepContainer) because the user wants:
    //   • title + subtitle CENTERED on the page (true page-center, not
    //     "center of the slot left after the logo")
    //   • logo pinned to the TOP-RIGHT, smaller than before
    //   • search bar centered, with the search button INSIDE the field
    //
    // A Stack layers a Center'd title block under an Align'd logo on
    // the right — so the title is truly page-centered while the logo
    // floats over the top-right corner without pushing the text.
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER — title centered, logo pinned right.
          SizedBox(
            height: 100,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'step.service.title'.tr,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isViewOnly
                            ? 'step.service.subtitle.view'.tr
                            : 'step.service.subtitle.pick'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/main-logo.jpg',
                      height: 80,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SEARCH BAR — centered, search button lives INSIDE the
          // field as a suffix so there is only one visual unit
          // labelled "search".
          Center(
            child: Container(
              width: 760,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchController,
                onSubmitted: controller.onSearch,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'step.service.search_hint'.tr,
                  hintStyle: TextStyle(
                    fontSize: 19,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.search_rounded,
                      size: 28,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            onPressed: controller.clearSearch,
                            color: Colors.grey[500],
                          ),
                        _SearchActionButton(
                          onTap: () => controller.onSearch(
                            controller.searchController.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 60,
                    maxWidth: 220,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: ColorConstants.mainCorlor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // GRID + PAGINATION
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: LoadingIndicator(size: 120));
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
                        'step.service.empty'.tr,
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
                        label: Text(
                          'step.service.clear_search'.tr,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 3x2 grid, cells sized from the *real* available height
              // via LayoutBuilder so two rows always fit exactly.
              // Card content min is ~161px (see _buildServiceCard
              // breakdown) so as long as the grid area is ≥ ~360px
              // we're safe — for a 1080p kiosk we get ≈ 600px here,
              // giving each cell ~290px and 130px of slack.
              final paged = controller.pagedServices;
              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 20.0;
                        const minCell = 180.0;
                        final h = constraints.maxHeight;
                        final cellHeight = h.isFinite && h > minCell * 2
                            ? (h - spacing) / 2
                            : minCell;
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisExtent: cellHeight,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                              ),
                          itemCount: paged.length,
                          itemBuilder: (context, index) {
                            final service = paged[index];
                            final serviceId = service['id']?.toString() ?? "";
                            final serviceName =
                                service['name']?.toString() ??
                                'step.service.unnamed'.tr;

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
                        );
                      },
                    ),
                  ),
                  // Server now paginates — `services` only holds the
                  // current page (≤ pageSize). Use totalPages (from
                  // backend `pagination.total`) to decide whether the
                  // pagination bar is needed.
                  if (controller.totalPages > 1) _buildPaginationBar(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: controller.prevPage,
            enabled: controller.currentPage.value > 1,
          ),
          const SizedBox(width: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '${'step.service.page_prefix'.tr} ${controller.currentPage.value} / ${controller.totalPages}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 28),
          _PageNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: controller.nextPage,
            enabled: controller.currentPage.value < controller.totalPages,
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
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.account_balance_rounded,
                                color: ColorConstants.mainCorlor,
                                size: 32,
                              ),
                        )
                      : const Icon(
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
      title: 'result.title'.tr,
      subtitle: controller.skipPrint.value
          ? 'result.subtitle.photo'.tr
          : 'result.subtitle'.tr,
      isScrollable: true,
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
                            Text(
                              'result.your_ticket'.tr,
                              style: const TextStyle(
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
                            Text(
                              'result.scan_to_track'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'result.scan_to_track_en'.tr,
                              style: const TextStyle(
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
              const SizedBox(height: 12),
              Obx(() {
                if (controller.skipPrint.value) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.mainCorlor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: ColorConstants.mainCorlor.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                value: controller.timeLeft.value / 60.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorConstants.mainCorlor,
                                ),
                                backgroundColor:
                                    ColorConstants.mainCorlor.withOpacity(0.2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${'result.auto_return'.tr} ${controller.timeLeft.value} ${'result.seconds'.tr}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.mainCorlor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              SizedBox(
                width: 320,
                height: 60,
                child: ElevatedButton(
                  onPressed: controller.resetBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.mainCorlor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                    shadowColor: ColorConstants.mainCorlor.withOpacity(0.3),
                  ),
                  child: Text(
                    'result.back_to_home'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return Obx(() {
      final bool showDebug = controller.showFeedbackDebugPanel.value;
      
      final Widget mainWizard = Obx(() {
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
                  Text(
                    'feedback.thanks.title'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF455C91),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Text(
                      'feedback.thanks.body'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                      child: Text(
                        'feedback.thanks.cta'.tr,
                        style: const TextStyle(
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

        // Wizard: render Step 1 or Step 2 based on controller.feedbackStep.
        return Obx(() {
          if (controller.feedbackStep.value == 1) {
            return _buildFeedbackStep1();
          }
          return _buildFeedbackStep2();
        });
      });

      if (showDebug) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _buildStepContainer(
                title: 'feedback.title'.tr,
                subtitle: 'feedback.subtitle'.tr,
                isScrollable: true,
                compactHeader: true,
                child: mainWizard,
              ),
            ),
            Container(
              width: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            Expanded(
              flex: 2,
              child: _buildFeedbackDebugPanel(),
            ),
          ],
        );
      }

      return _buildStepContainer(
        title: 'feedback.title'.tr,
        subtitle: 'feedback.subtitle'.tr,
        isScrollable: true,
        compactHeader: true,
        child: mainWizard,
      );
    });
  }

  Widget _buildFeedbackStep1() {
    // Extracted into a separate widget so we can:
    //   * Use MediaQuery.viewInsetsOf locally (subscribes only to
    //     viewInsets, not all MediaQuery aspects).
    //   * Cache the heavy card+shadows via RepaintBoundary INSIDE.
    //
    // Perf history: the old version used `Builder` + MediaQuery.of +
    // AnimatedPadding(200ms). The keyboard inset changes every frame as
    // it animates, so AnimatedPadding's target moved every frame and
    // re-triggered a fresh 200ms animation that never settled, while two
    // BoxShadow layers (40px + 15px blur) repainted in lock-step. Plain
    // Padding with viewInsetsOf is enough — Flutter already interpolates
    // the keyboard inset smoothly per frame, so no extra animator needed.
    return const _FeedbackStep1View();
  }

  Widget _buildFeedbackStep2() {
    // Layout constants — single rhythm: card width 960, inner padding 32,
    // 32px between major sections, 16px between sub-elements.
    const double cardWidth = 960;
    const Color accent = Color(0xFF455C91);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: cardWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reference banner — calm reassurance of WHAT the user is
              // rating. Back navigation removed (forward-only flow).
              Center(child: _buildFeedbackReferenceBanner(accent)),
              const SizedBox(height: 24),

              // 2) The form card — purely about the question, the answer,
              //    and the submit. No navigation chrome inside.
              Container(
                padding: const EdgeInsets.all(32),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section A: Question block (kicker + bold question)
                    _buildFeedbackStep2Heading(accent),
                    const SizedBox(height: 32),

                    // Section B: Rating row — exactly one row of 5 cards
                    _buildFeedbackRatingRow(),

                    // Section C: Comment + submit (revealed after pick)
                    Obx(() {
                      if (controller.feedbackRating.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          _buildFeedbackCommentBlock(accent),
                          const SizedBox(height: 24),
                          Center(child: _buildFeedbackSubmitButton()),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reference banner (centered, dignified) ───────────────────────────────
  Widget _buildFeedbackReferenceBanner(Color accent) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.18), width: 1.5),
        ),
        child: Text(
          '${'feedback.step2.reference_label'.tr}: ${controller.feedbackReferenceController.text}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF455C91),
            // 0 letterSpacing for Lao — see _buildFeedbackStep2Heading.
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  // ─── Step 2 heading: kicker + bold question ───────────────────────────────
  Widget _buildFeedbackStep2Heading(Color accent) {
    return Column(
      children: [
        // Kicker — small, muted, all-caps-feel, sets context.
        // letterSpacing must stay 0 for Lao: positive tracking pulls
        // combining tone/vowel marks (ັ ້) away from their base letter
        // (ຂ) and the word ຂັ້ນ visibly fractures.
        Text(
          'feedback.step2.kicker'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: accent.withOpacity(0.55),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        // Question — dominant, bold, the user's actual task.
        Text(
          'feedback.step2.question'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF455C91),
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  // ─── Rating row: five cards on a single line ──────────────────────────────
  Widget _buildFeedbackRatingRow() {
    // 5 × 168 + 4 × 14 = 896 = card interior (960 − 32 − 32). Fits cleanly.
    const double cardW = 168;
    const double gap = 14;

    final levels = <Map<String, Object>>[
      {
        'label': 'feedback.rating.excellent'.tr,
        'rating': 5,
        'icon': Icons.sentiment_very_satisfied_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': 'feedback.rating.good'.tr,
        'rating': 4,
        'icon': Icons.sentiment_satisfied_alt_rounded,
        'color': const Color(0xFF8BC34A),
      },
      {
        'label': 'feedback.rating.neutral'.tr,
        'rating': 3,
        'icon': Icons.sentiment_neutral_rounded,
        'color': const Color(0xFFFFC107),
      },
      {
        'label': 'feedback.rating.needs_improvement'.tr,
        'rating': 2,
        'icon': Icons.sentiment_dissatisfied_rounded,
        'color': const Color(0xFFFF9800),
      },
      {
        'label': 'feedback.rating.poor'.tr,
        'rating': 1,
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'color': const Color(0xFFF44336),
      },
    ];

    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            _buildRatingCard(
              level: levels[i],
              isSelected:
                  controller.feedbackRating.value == levels[i]['rating'],
              width: cardW,
            ),
          ],
        ],
      );
    });
  }

  Widget _buildRatingCard({
    required Map<String, Object> level,
    required bool isSelected,
    required double width,
  }) {
    final Color color = level['color'] as Color;
    return GestureDetector(
      onTap: () {
        controller.selectRating(
          level['rating'] as int,
          level['label'] as String,
        );
      },
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.2),
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
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
              const SizedBox(height: 10),
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
      ),
    );
  }

  // ─── Comment block: "(ຖ້າມີ)" visually demoted ────────────────────────────
  Widget _buildFeedbackCommentBlock(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading with demoted "(optional)" tail — same line, different weight.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${'feedback.comment.label'.tr} ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF455C91),
                ),
              ),
              TextSpan(
                text: 'feedback.comment.optional'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: accent.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.18), width: 1.5),
          ),
          child: TextField(
            controller: controller.feedbackCommentController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'feedback.comment.hint'.tr,
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Submit button ────────────────────────────────────────────────────────
  Widget _buildFeedbackSubmitButton() {
    return Obx(
      () => SizedBox(
        width: 360,
        height: 80,
        child: ElevatedButton(
          onPressed: controller.isSubmittingFeedback.value
              ? null
              : () async {
                  final success = await controller.submitFeedback();
                  if (!success) {
                    CustomDialog.showError(
                      title: 'common.error'.tr,
                      message: 'feedback.error.submit_failed'.tr,
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
              ? const LoadingIndicator(size: 48)
              : Text(
                  'feedback.submit'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFeedbackDebugPanel() {
    final KioskController controller = Get.find<KioskController>();
    return Container(
      color: const Color(0xFF1E293B), // Slate 800 dark mode bg
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'FEEDBACK DEBUG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => controller.showFeedbackDebugPanel.value = false,
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          
          // Switch to toggle Public vs Private API
          Obx(() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Slate 900
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Public API',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bypasses JWT/Auth interceptor',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: controller.usePublicApiForFeedback.value,
                    onChanged: (val) {
                      controller.usePublicApiForFeedback.value = val;
                    },
                    activeThumbColor: Colors.orange,
                    activeTrackColor: Colors.orange.withOpacity(0.4),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Help/Autofill Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.feedbackReferenceController.text = '12345678';
                        controller.feedbackReferenceLength.value = 8;
                      },
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Autofill Ref', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.lastFeedbackRequest.value = null;
                        controller.lastFeedbackResponse.value = null;
                      },
                      icon: const Icon(Icons.clear_all, size: 16, color: Colors.white),
                      label: const Text('Clear Logs', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  controller.feedbackReferenceController.text = '99999999';
                  controller.feedbackReferenceLength.value = 8;
                  controller.feedbackApplication.value = {
                    'id': 'debug-app-id',
                    'referenceNumber': '99999999',
                    'serviceName': 'Debug Test Service',
                    'serviceCenterId': controller.serviceCenterId.value.isEmpty 
                        ? 'debug-service-center-id' 
                        : controller.serviceCenterId.value,
                  };
                  controller.feedbackStep.value = 2;
                },
                icon: const Icon(Icons.skip_next, size: 18, color: Colors.white),
                label: const Text('Bypass Step 1 (Force Step 2)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Request Section
          const Text(
            'LAST REQUEST DETAILS:',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Obx(() {
                  final req = controller.lastFeedbackRequest.value;
                  return Text(
                    req ?? '(No request recorded yet)',
                    style: TextStyle(
                      color: req != null ? Colors.cyanAccent : Colors.grey,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  );
                }),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Response Section
          const Text(
            'LAST RESPONSE DETAILS:',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Obx(() {
                  final resp = controller.lastFeedbackResponse.value;
                  Color textColor = Colors.grey;
                  if (resp != null) {
                    if (resp.contains('Error') || resp.contains('ApiException')) {
                      textColor = Colors.redAccent;
                    } else {
                      textColor = Colors.greenAccent;
                    }
                  }
                  return Text(
                    resp ?? '(No response recorded yet)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact gradient pill placed INSIDE the search field as its
/// suffix — so the field reads as one visual unit: "[ field with
/// built-in search action ]". Padding and font sizes are tuned to
/// fit within the TextField's `suffixIconConstraints` (60 high).
class _SearchActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: ColorConstants.mainCorlor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'step.service.search_button'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _PageNavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: enabled ? ColorConstants.mainCorlor : Colors.grey[200],
            borderRadius: BorderRadius.circular(36),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ColorConstants.mainCorlor.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 40,
            color: enabled ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
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

// ─── Feedback step 1 (reference entry) ────────────────────────────────────
//
// Pulled out of KioskView so MediaQuery.viewInsetsOf only invalidates this
// subtree (not the entire kiosk). The card with its two BoxShadow layers
// sits behind a RepaintBoundary so the GPU caches its raster across
// rebuilds.
class _FeedbackStep1View extends StatelessWidget {
  const _FeedbackStep1View();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: const Center(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            child: _FeedbackStep1Card(),
          ),
        ),
      ),
    );
  }
}

class _FeedbackStep1Card extends StatelessWidget {
  const _FeedbackStep1Card();

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    Color? color,
    Color? borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: ColorConstants.mainCorlor.withOpacity(0.08),
        highlightColor: ColorConstants.mainCorlor.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? const Color(0xFF455C91).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildCustomKeypad(KioskController controller) {
    const double btnAspectRatio = 2.6; // Stretches the buttons horizontally
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1, 2, 3
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '1',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '1';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '2',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '2';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '3',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '3';
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 2: 4, 5, 6
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '4',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '4';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '5',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '5';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '6',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '6';
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 3: 7, 8, 9
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '7',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '7';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '8',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '8';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '9',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '9';
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Last Row: C, 0, Backspace
        Row(
          children: [
            // Clear (C) button
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  color: const Color(0xFFFFEBEE),
                  borderColor: const Color(0xFFFFCDD2),
                  child: const Text(
                    'C',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  onTap: () {
                    controller.feedbackReferenceController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 0 button
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  child: const Text(
                    '0',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.mainCorlor,
                    ),
                  ),
                  onTap: () {
                    if (controller.feedbackReferenceController.text.length < 8) {
                      controller.feedbackReferenceController.text += '0';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Backspace button
            Expanded(
              child: AspectRatio(
                aspectRatio: btnAspectRatio,
                child: _buildKeypadButton(
                  color: const Color(0xFFFFF3E0),
                  borderColor: const Color(0xFFFFE0B2),
                  child: const Icon(
                    Icons.backspace_outlined,
                    size: 28,
                    color: Color(0xFFE65100),
                  ),
                  onTap: () {
                    final text = controller.feedbackReferenceController.text;
                    if (text.isNotEmpty) {
                      controller.feedbackReferenceController.text =
                          text.substring(0, text.length - 1);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final KioskController controller = Get.find<KioskController>();
    return Container(
      width: 800, // Return to original width
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => controller.handleFeedbackTitleTap(),
            child: Text(
              'feedback.step1.title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ColorConstants.mainCorlor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stretched Search Bar Row (TextField + Search Button side-by-side)
          SizedBox(
            width: 700, // Matching keyboard width beautifully
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ColorConstants.mainCorlor.withOpacity(0.35),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.mainCorlor.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        // Left breathing room to balance the icon on the right for perfect text centering
                        const SizedBox(width: 68),
                        Expanded(
                          child: TextField(
                            controller: controller.feedbackReferenceController,
                            readOnly: true, // Prevents OS keyboard from popping up
                            showCursor: false, // Hides cursor for custom keypad look
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: ColorConstants.mainCorlor,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: 'XXXXXXXX',
                              counterText: "",
                              hintStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.3),
                                letterSpacing: 8,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () => _openQRScanner(context, controller),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 36,
                                color: ColorConstants.mainCorlor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Search button placed next to TextField
                Obx(() {
                  final bool isLookingUp = controller.isLookingUpReference.value;
                  final bool canAdvance =
                      controller.feedbackReferenceLength.value == 8 && !isLookingUp;
                  return SizedBox(
                    width: 180,
                    height: 75,
                    child: ElevatedButton(
                      onPressed: canAdvance ? controller.goToFeedbackStep2 : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.orange,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: canAdvance ? 4 : 0,
                        shadowColor: ColorConstants.orange.withOpacity(0.4),
                        padding: EdgeInsets.zero, // Allow text to fit perfectly
                      ),
                      child: isLookingUp
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'feedback.step1.search'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Custom on-screen numeric keypad (Stretched horizontally to match)
          SizedBox(
            width: 700,
            child: _buildCustomKeypad(controller),
          ),
        ],
      ),
    );
  }

  // Parses scanned QR code content to extract exactly 8 digits representing the reference number.
  String? _extractReference(String text) {
    final regex = RegExp(r'\b\d{8}\b');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  // Opens a beautiful camera scanner dialog using front camera by default for easy kiosk interaction.
  Future<void> _openQRScanner(BuildContext context, KioskController controller) async {
    final status = await Permission.camera.request();
    if (!context.mounted) return;
    if (!status.isGranted) {
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'camera.permission_denied'.tr,
      );
      return;
    }

    final scannerController = ms.MobileScannerController(
      facing: ms.CameraFacing.front,
      detectionSpeed: ms.DetectionSpeed.noDuplicates,
    );

    // Show beautiful scanning dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 500,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'feedback.step1.scan_title'.tr,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.mainCorlor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 28),
                        onPressed: () {
                          scannerController.dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                // Camera View Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          ms.MobileScanner(
                            controller: scannerController,
                            onDetect: (capture) {
                              final List<ms.Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final String? rawValue = barcode.rawValue ?? barcode.displayValue;
                                if (rawValue != null) {
                                  final ref = _extractReference(rawValue);
                                  if (ref != null) {
                                    scannerController.dispose();
                                    Navigator.of(context).pop();
                                    
                                    // Populate input field
                                    controller.feedbackReferenceController.text = ref;
                                    controller.feedbackReferenceLength.value = 8;
                                    
                                    // Auto submit after a brief 300ms delay for visual feedback
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      controller.goToFeedbackStep2();
                                    });
                                    break;
                                  }
                                }
                              }
                            },
                          ),
                          // Beautiful scanning overlay (laser line & corner brackets)
                          const _ScannerOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Controls footer
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => scannerController.switchCamera(),
                        icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                        label: Text(
                          'feedback.step1.switch_camera'.tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.mainCorlor,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => scannerController.toggleTorch(),
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                        label: Text(
                          'feedback.step1.flash'.tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Beautiful scanning cutout overlay with corner brackets and animated laser scanning line.
class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay();

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double rectSize = 290.0;
        final double top = (constraints.maxHeight - rectSize) / 2;
        final double left = (constraints.maxWidth - rectSize) / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerCutoutPainter(),
              ),
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: top + 10 + ((rectSize - 20) * _animationController.value),
                  left: left + 10,
                  right: left + 10,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: ColorConstants.mainCorlor,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.mainCorlor.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'ແນໃສ່ QR ໂຄດຂອງທ່ານ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const double rectSize = 290.0;
    final double left = (size.width - rectSize) / 2;
    final double top = (size.height - rectSize) / 2;
    final rect = Rect.fromLTWH(left, top, rectSize, rectSize);

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    
    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = ColorConstants.mainCorlor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;
    const double radius = 24.0;

    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..quadraticBezierTo(left, top, left + radius, top)
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + rectSize - cornerLength, top)
        ..lineTo(left + rectSize - radius, top)
        ..quadraticBezierTo(left + rectSize, top, left + rectSize, top + radius)
        ..lineTo(left + rectSize, top + cornerLength),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left, top + rectSize - cornerLength)
        ..lineTo(left, top + rectSize - radius)
        ..quadraticBezierTo(left, top + rectSize, left + radius, top + rectSize)
        ..lineTo(left + cornerLength, top + rectSize),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + rectSize - cornerLength, top + rectSize)
        ..lineTo(left + rectSize - radius, top + rectSize)
        ..quadraticBezierTo(left + rectSize, top + rectSize, left + rectSize, top + rectSize - radius)
        ..lineTo(left + rectSize, top + rectSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
