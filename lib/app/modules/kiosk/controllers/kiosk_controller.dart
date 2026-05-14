import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_odsc_queue/app/data/models/user_model.dart';
import 'package:smart_odsc_queue/app/shared/services/printer_service.dart';
import 'package:smart_odsc_queue/app/shared/widgets/custom_dialog.dart';
import 'package:smart_odsc_queue/app/data/api_helper/api_service.dart';
import 'package:smart_odsc_queue/app/data/constants/api_endpoints.dart';
import 'package:smart_odsc_queue/app/shared/utils/error_handler.dart';
import 'package:smart_odsc_queue/app/shared/utils/logger.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:smart_odsc_queue/app/shared/widgets/printable_ticket.dart';

class KioskController extends GetxController {
  final PrinterService printerService = Get.find<PrinterService>();
  final storage = GetStorage();
  final HelpersApi api = HelpersApi();
  final ScreenshotController screenshotController = ScreenshotController();
  late final TextEditingController searchController;
  late final TextEditingController feedbackCommentController;
  late final TextEditingController feedbackReferenceController;

  final RxInt currentStep =
      1.obs; // Start at welcome step (1), 0 is printer setup
  final RxInt timeLeft = 60.obs;
  Timer? _timer;

  // Feedback Data
  final RxInt feedbackRating = 0.obs;
  final RxBool isSubmittingFeedback = false.obs;
  final RxBool isFeedbackSubmitted = false.obs;

  // Admin Access Logic
  final RxInt adminTapCount = 0.obs;
  Timer? _adminTapTimer;

  void handleAdminTap() {
    adminTapCount.value++;
    _adminTapTimer?.cancel();

    if (adminTapCount.value >= 5) {
      adminTapCount.value = 0;
      goToPrinterSettings();
    } else {
      _adminTapTimer = Timer(const Duration(seconds: 2), () {
        adminTapCount.value = 0;
      });
    }
  }

  // Booking Data
  final RxString gender = "".obs;
  final RxString ageRange = "".obs;
  final RxBool isDisabled = false.obs;
  final RxString visitPurpose = "".obs;
  final RxString selectedServiceId = "".obs;
  final RxString selectedServiceName = "".obs;
  final RxString queueNumber = "".obs;
  final RxString barCodeNumber = "".obs;
  final RxString trackingUrl = "".obs;
  final RxString serviceCenterId = "".obs;

  final RxList<dynamic> services = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    searchController = TextEditingController();
    feedbackCommentController = TextEditingController();
    feedbackReferenceController = TextEditingController();
    super.onInit();
    
    // Initialize serviceCenterId from storage if available
    final userData = storage.read('user');
    if (userData != null) {
      final user = UserModel.fromJson(userData);
      final profile = user.officerProfile;
      final scId = profile is Map ? _stringValue(profile['serviceCenterId']) : null;
      if (scId != null) serviceCenterId.value = scId;
    }
    
    fetchServices();
  }

  void onSearch(String query) {
    fetchServices(query: query);
  }

  void clearSearch() {
    searchController.clear();
    fetchServices();
  }

  Future<void> fetchServices({String? query}) async {
    isLoading.value = true;
    try {
      final Map<String, dynamic> queryParams = {'status': true};
      if (query != null && query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }

      final response = await api.get(
        ApiEndpoints.services,
        queryParameters: queryParams,
      );
      if (response['data'] != null) {
        services.assignAll(response['data']);
      }
    } catch (e) {
      AppLogger.error('Error fetching services: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  String? _organizationIdFromProfile(dynamic profile) {
    if (profile is! Map) return null;

    final organizations = profile['organizations'];

    if (organizations is List && organizations.isNotEmpty) {
      final firstOrganization = organizations.first;

      if (firstOrganization is Map) {
        return _stringValue(
          firstOrganization['organizationId'] ?? firstOrganization['id'],
        );
      }
    }

    final organizationIds = profile['organizationIds'];

    if (organizationIds is List && organizationIds.isNotEmpty) {
      return _stringValue(organizationIds.first);
    }

    return _stringValue(profile['organizationId']);
  }

  Map<String, dynamic>? _selectedService(String serviceId) {
    if (serviceId.isEmpty) return null;

    for (final service in services) {
      if (service is Map && _stringValue(service['id']) == serviceId) {
        return Map<String, dynamic>.from(service);
      }
    }

    return null;
  }

  String? _organizationIdFromService(dynamic service) {
    if (service is! Map) return null;

    final directId = _stringValue(service['organizationId']);
    if (directId != null) return directId;

    final organization = service['organization'];
    if (organization is Map) {
      final organizationId = _stringValue(organization['id']);
      if (organizationId != null) return organizationId;
    }

    return _stringValue(service['ministryId'] ?? service['departmentId']);
  }

  Future<String?> _resolveOrganizationId({
    required dynamic profile,
    required String serviceId,
  }) async {
    final profileOrganizationId = _organizationIdFromProfile(profile);

    if (profileOrganizationId != null) return profileOrganizationId;

    final selectedService = _selectedService(serviceId);
    final serviceOrganizationId = _organizationIdFromService(selectedService);

    if (serviceOrganizationId != null) return serviceOrganizationId;

    if (serviceId.isEmpty) return null;

    try {
      final response = await api.get('${ApiEndpoints.services}/$serviceId');
      final detailOrganizationId = _organizationIdFromService(response['data']);

      if (detailOrganizationId != null) return detailOrganizationId;
    } catch (e) {
      AppLogger.error('Error resolving service organization: $e');
    }

    return null;
  }

  void nextStep() {
    if (currentStep.value < 8) {
      // Logic for skipping service selection if already selected from Directory (Step 9)
      if (currentStep.value == 5 && selectedServiceId.value.isNotEmpty) {
        submitBooking(selectedServiceId.value, selectedServiceName.value);
        return;
      }

      currentStep.value++;
      if (currentStep.value == 8) {
        startTimer();
        autoPrint();
      }
    }
  }

  void prevStep() {
    if (currentStep.value > 0) {
      if (currentStep.value == 8 ||
          currentStep.value == 9 ||
          currentStep.value == 10) {
        // If coming back from ticket result, Service Directory, or Feedback, reset to welcome
        resetBooking();
      } else {
        currentStep.value--;
      }
    }
  }

  void goToPrinterSettings() {
    Get.toNamed('/printer');
  }

  void resetBooking() {
    currentStep.value = 1;
    gender.value = "";
    ageRange.value = "";
    isDisabled.value = false;
    visitPurpose.value = "";
    selectedServiceId.value = "";
    selectedServiceName.value = "";
    queueNumber.value = "";
    barCodeNumber.value = "";
    _timer?.cancel();
    // Reset Feedback
    feedbackRating.value = 0;
    feedbackCommentController.clear();
    feedbackReferenceController.clear();
    isFeedbackSubmitted.value = false;
  }

  void startTimer() {
    timeLeft.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        resetBooking();
      }
    });
  }

  String mapPurpose(String purpose) {
    switch (purpose) {
      case "INQUIRY":
        return "INQUIRY";
      case "SERVICE":
        return "SERVICE_USAGE";
      case "CERTIFICATION":
        return "CERTIFICATE_REQUEST";
      default:
        return "SERVICE_USAGE";
    }
  }

  Future<void> submitBooking(String serviceId, String serviceName) async {
    isLoading.value = true;
    CustomDialog.showLoading(message: 'ກຳລັງອອກບັດຄິວ...');

    try {
      final userData = storage.read('user');
      if (userData == null) {
        CustomDialog.hideLoading();
        CustomDialog.showError(title: 'Error', message: 'User not logged in');
        return;
      }
      final user = UserModel.fromJson(userData);
      final profile = user.officerProfile;
      final scId = profile is Map
          ? _stringValue(profile['serviceCenterId'])
          : null;
      if (scId != null) serviceCenterId.value = scId;

      final orgId = await _resolveOrganizationId(
        profile: profile,
        serviceId: serviceId,
      );

      if (serviceCenterId == null) {
        CustomDialog.hideLoading();
        CustomDialog.showError(
          title: 'Error',
          message: 'ບັນຊີນີ້ຍັງບໍ່ມີຂໍ້ມູນສູນ ຫຼື ໜ່ວຍງານທີ່ຜູກກັບບໍລິການ',
        );
        return;
      }

      // If a specific service was selected, organizationId must be resolvable.
      if (serviceId.isNotEmpty && orgId == null) {
        CustomDialog.hideLoading();
        CustomDialog.showError(
          title: 'Error',
          message:
              'ບໍ່ພົບຂໍ້ມູນຫຼັກຂອງບໍລິການ (organization) ສໍາລັບການຈັດລຳດັບ',
        );
        return;
      }

      final payload = {
        "gender": gender.value.isEmpty ? "OTHER" : gender.value,
        "ageRange": ageRange.value.isEmpty ? "AGE_21_35" : ageRange.value,
        "visitPurpose": mapPurpose(visitPurpose.value),
        "serviceCenterId": serviceCenterId.value,
        "isDisabled": isDisabled.value,
        "status": "WAITING",
      };

      // Attach organizationId only when available
      if (orgId != null) {
        payload["organizationId"] = orgId;
      }

      if (serviceId.isNotEmpty) {
        payload["serviceId"] = serviceId;
      }

      final response = await api.post(ApiEndpoints.queues, data: payload);
      CustomDialog.hideLoading();

      if (response['status'] == true && response['data'] != null) {
        final qNumber = response['data']['queueNumber'] ?? "";
        final bcNumber = response['data']['barCodeNumber'] ?? "";
        queueNumber.value = qNumber;
        barCodeNumber.value = bcNumber;
        trackingUrl.value =
            "http://odsc.gov.la/lo/queue-tracking?queueNumber=$qNumber&serviceCenterId=${serviceCenterId.value}";
        selectedServiceId.value = serviceId;
        selectedServiceName.value = serviceName;
        currentStep.value = 8; // Jump to result step
        if (Get.currentRoute != '/kiosk') {
          Get.back(); // Return from ServiceDetailPage if we are there
        }
        startTimer();
        autoPrint();
      } else {
        CustomDialog.showError(
          title: 'Error',
          message: 'ບໍ່ສາມາອອກບັດຄິວໄດ້ໃນເວລານີ້',
        );
      }
    } catch (e) {
      CustomDialog.hideLoading();
      CustomDialog.showError(
        title: 'Error',
        message: ErrorHandler.getMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> autoPrint() async {
    try {
      if (await printerService.bluetooth.isConnected ?? false) {
        final Uint8List? imageBytes = await screenshotController
            .captureFromWidget(
              PrintableTicket(
                queueNumber: queueNumber.value,
                serviceName: selectedServiceName.value,
                barCodeNumber: barCodeNumber.value,
                qrCodeData: trackingUrl.value,
              ),
              delay: const Duration(milliseconds: 100),
              context: Get.context,
              pixelRatio: 3.0, // Increased for sharper thermal printing
            );

        if (imageBytes != null) {
          await printerService.printLaoTextAsImage(imageBytes);
        }
      }
    } catch (e) {
      AppLogger.error('Auto print (Lao Image) error: $e');
    }
  }

  void selectRating(int rating, String label) {
    feedbackRating.value = rating;
    if (rating > 1) {
      feedbackCommentController.text = label;
    } else {
      feedbackCommentController.clear();
      // Keep it at 1 to show the text field in the UI
    }
  }

  Future<bool> submitFeedback() async {
    if (feedbackRating.value == 0) return false;

    if (feedbackReferenceController.text.length != 8) {
      CustomDialog.showError(
        title: 'ຜິດພາດ',
        message: 'ກະລຸນາປ້ອນເລກอ້າງອີງໃຫ້ຄົບ 8 ໂຕ',
      );
      return false;
    }

    isSubmittingFeedback.value = true;
    try {
      final userData = storage.read('user');
      if (userData == null) {
        CustomDialog.showError(title: 'Error', message: 'User not logged in');
        return false;
      }
      final user = UserModel.fromJson(userData);

      final profile = user.officerProfile;

      final officerNo = (profile is Map)
          ? profile['officerNo']?.toString()
          : null;

      final payload = {
        "image": "",
        "description": feedbackCommentController.text,
        "rating": feedbackRating.value,
        "referenceNumber": feedbackReferenceController.text,
        "serviceCenterId":
            serviceCenterId.value.isEmpty ? null : serviceCenterId.value,
        "userId": user.id.isEmpty ? null : user.id,
        "fullName": feedbackReferenceController.text,
      };

      AppLogger.info('Feedback Payload: $payload');
      AppLogger.info('Profile: $profile');

      final response = await api.post(ApiEndpoints.feedback, data: payload);
      AppLogger.info('Feedback Response: $response');

      if (response['message'] == 'SUCCESS' || response['status'] == true) {
        // Reset feedback state
        feedbackRating.value = 0;
        feedbackCommentController.clear();
        feedbackReferenceController.clear();
        isFeedbackSubmitted.value = true;
        return true;
      } else {
        CustomDialog.showError(
          title: 'Error',
          message: 'ບໍ່ສາມາດສົ່ງຄຳຄິດເຫັນໄດ້ໃນເວລານີ້',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Feedback submission error: $e');
      if (e is ApiException) {
        AppLogger.error('Feedback Error Response: ${e.response}');
      }
      CustomDialog.showError(
        title: 'Error',
        message: ErrorHandler.getMessage(e),
      );
      return false;
    } finally {
      isSubmittingFeedback.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _adminTapTimer?.cancel();
    feedbackCommentController.dispose();
    feedbackReferenceController.dispose();
    // searchController.dispose(); // Removed to avoid used-after-disposed during transitions
    super.onClose();
  }
}
