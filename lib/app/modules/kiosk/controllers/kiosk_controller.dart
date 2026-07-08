import 'dart:async';
import 'dart:convert';
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

  // Welcome screen is step 1. Steps 2-8 are the queue wizard,
  // 9 is the printed-ticket result, 10 is the directory, 11 is feedback.
  final RxInt currentStep = 1.obs;
  final RxInt timeLeft = 60.obs;
  Timer? _timer;

  // Feedback Data
  final RxInt feedbackRating = 0.obs;
  final RxBool isSubmittingFeedback = false.obs;
  final RxBool isFeedbackSubmitted = false.obs;
  final RxInt feedbackStep = 1.obs;
  // Mirror of feedbackReferenceController text length so the Search button
  // can reactively enable/disable when the user types in the 8-digit field.
  final RxInt feedbackReferenceLength = 0.obs;
  // Looked-up application that matches the reference number typed on step 1.
  // Resolved via GET /api/v1/core/applications?search=<refnum> before we
  // allow the user to advance to step 2 — so the rating they leave is tied
  // to a real submission, not a typo.
  final Rxn<Map<String, dynamic>> feedbackApplication =
      Rxn<Map<String, dynamic>>();
  final RxBool isLookingUpReference = false.obs;

  // Feedback Debug State
  final RxBool showFeedbackDebugPanel = false.obs;
  final Rxn<String> lastFeedbackRequest = Rxn<String>();
  final Rxn<String> lastFeedbackResponse = Rxn<String>();
  final RxBool usePublicApiForFeedback = false.obs;
  final RxInt feedbackTitleTapCount = 0.obs;

  void handleFeedbackTitleTap() {
    feedbackTitleTapCount.value++;
    if (feedbackTitleTapCount.value >= 5) {
      showFeedbackDebugPanel.value = !showFeedbackDebugPanel.value;
      feedbackTitleTapCount.value = 0;
      Get.snackbar(
        showFeedbackDebugPanel.value ? 'Debug Panel Enabled' : 'Debug Panel Disabled',
        showFeedbackDebugPanel.value 
            ? 'Feedback debug tools are now visible on the right.' 
            : 'Feedback debug tools have been hidden.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: showFeedbackDebugPanel.value ? const Color(0xFFF47939) : const Color(0xFF3554A1),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> goToFeedbackStep2() async {
    final refNumber = feedbackReferenceController.text.trim();
    print('🔍 [FEEDBACK_LOOKUP] Initiating lookup for reference number: $refNumber');
    AppLogger.info('🔍 [FEEDBACK_LOOKUP] Initiating lookup for reference number: $refNumber');
    if (refNumber.length != 8) {
      print('⚠️ [FEEDBACK_LOOKUP] Aborted: Reference number must be exactly 8 digits.');
      AppLogger.warning('⚠️ [FEEDBACK_LOOKUP] Aborted: Reference number must be exactly 8 digits.');
      return;
    }
    if (isLookingUpReference.value) {
      print('⚠️ [FEEDBACK_LOOKUP] Aborted: Lookup already in progress.');
      AppLogger.warning('⚠️ [FEEDBACK_LOOKUP] Aborted: Lookup already in progress.');
      return;
    }

    // 1) Dismiss the on-screen keyboard FIRST. Previously we pushed a
    //    Get.dialog loading overlay while the keyboard was still visible,
    //    so the keyboard's dismissal animation (200-300ms) raced with
    //    the dialog route push + AlertDialog layout + animated GIF
    //    raster — three things repainting the same region on the UI
    //    isolate at the same time. The visible result was a stutter on
    //    Search-tap. Unfocusing first lets the keyboard finish coming
    //    down before any overlay work.
    FocusManager.instance.primaryFocus?.unfocus();

    isLookingUpReference.value = true;
    lastFeedbackRequest.value = 'GET ${ApiEndpoints.applications}?search=$refNumber';
    lastFeedbackResponse.value = 'Loading...';
    try {
      print('🌐 [FEEDBACK_LOOKUP] Sending GET request to ${ApiEndpoints.applications} search=$refNumber');
      AppLogger.info('🌐 [FEEDBACK_LOOKUP] Sending GET request to ${ApiEndpoints.applications} search=$refNumber');
      final response = await api.get(
        ApiEndpoints.applications,
        queryParameters: {'search': refNumber},
      );

      print('📥 [FEEDBACK_LOOKUP] Raw Response received: $response');
      AppLogger.info('📥 [FEEDBACK_LOOKUP] Raw Response received: $response');
      lastFeedbackResponse.value = 'Status: 200 OK\nBody:\n${response.toString()}';

      // smart-odsc-core returns { status, message, data: [...applications] }.
      // listApplicationsService maps each row to include `referenceNumber`,
      // so we filter strictly here in case `search` matches partial strings.
      final List<dynamic> rows = (response['data'] is List)
          ? response['data'] as List<dynamic>
          : const <dynamic>[];

      print('📊 [FEEDBACK_LOOKUP] Total applications returned from search: ${rows.length}');
      AppLogger.info('📊 [FEEDBACK_LOOKUP] Total applications returned from search: ${rows.length}');

      final match = rows.firstWhere(
        (a) => a is Map && a['referenceNumber']?.toString() == refNumber,
        orElse: () => null,
      );

      if (match == null) {
        print('❌ [FEEDBACK_LOOKUP] No exact reference match found for: $refNumber in returned list.');
        AppLogger.warning('❌ [FEEDBACK_LOOKUP] No exact reference match found for: $refNumber in returned list.');
        lastFeedbackResponse.value = 'Status: 200 OK (But Reference not found in list)\nBody:\n${response.toString()}';
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'feedback.error.reference_not_found'.tr,
        );
        return;
      }

      print('✅ [FEEDBACK_LOOKUP] Found exact match: $match');
      AppLogger.info('✅ [FEEDBACK_LOOKUP] Found exact match: $match');
      feedbackApplication.value = Map<String, dynamic>.from(match as Map);
      
      print('➡️ [FEEDBACK_LOOKUP] Transitioning from Step 1 to Step 2');
      AppLogger.info('➡️ [FEEDBACK_LOOKUP] Transitioning from Step 1 to Step 2');
      feedbackStep.value = 2;
    } catch (e) {
      print('💥 [FEEDBACK_LOOKUP] Exception occurred: $e');
      AppLogger.error('Feedback reference lookup error: $e');
      if (e is ApiException) {
        print('💥 [FEEDBACK_LOOKUP] ApiException Response: ${e.response}');
        lastFeedbackResponse.value = 'ApiException Code: ${e.statusCode}\nResponse:\n${e.response}\nMessage: ${e.message}';
      } else {
        lastFeedbackResponse.value = 'Error:\n$e';
      }
      
      String errMsg = 'feedback.error.lookup_failed'.tr;
      if (showFeedbackDebugPanel.value) {
        errMsg += '\n\nDebug Info:\n$e';
        if (e is ApiException) {
          errMsg += '\nResponse: ${e.response}';
        }
      }
      
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: errMsg,
      );
    } finally {
      // 2) No modal hideLoading() to call — the Search button shows an
      //    inline spinner driven by isLookingUpReference, which means
      //    the only thing on screen during the lookup is one widget
      //    rebuilding (the button), not a full-screen overlay + GIF.
      isLookingUpReference.value = false;
    }
  }

  void goToFeedbackStep1() {
    feedbackStep.value = 1;
  }

  // Admin Access Logic
  final RxInt adminTapCount = 0.obs;
  Timer? _adminTapTimer;

  void handleAdminTap() {
    adminTapCount.value++;
    _adminTapTimer?.cancel();

    if (adminTapCount.value >= 5) {
      adminTapCount.value = 0;
      // Hidden admin gesture → printer setup screen so staff can
      // (re-)pair the thermal printer without exposing it in the
      // user-facing kiosk flow.
      Get.toNamed('/printer');
    } else {
      _adminTapTimer = Timer(const Duration(seconds: 2), () {
        adminTapCount.value = 0;
      });
    }
  }

  // Booking Data
  final RxString gender = "".obs;
  final RxString ethnicity = "".obs;
  final RxString ageRange = "".obs;
  final RxBool isDisabled = false.obs;
  final RxString visitPurpose = "".obs;
  final RxString selectedServiceId = "".obs;
  final RxString selectedServiceName = "".obs;
  final RxString queueNumber = "".obs;
  final RxString barCodeNumber = "".obs;
  final RxString trackingUrl = "".obs;
  final RxString serviceCenterId = "".obs;

  // When user taps "Skip" on service_choice → they're sent to step 12
  // (print/photo). If they pick "photo", set this true to skip thermal
  // printing on step 9 — the QR on screen is their ticket.
  final RxBool skipPrint = false.obs;

  final RxList<dynamic> services = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  // --- Pagination state for the services grid ---
  //
  // Server-side pagination via GET /services?page=&limit=&search=
  // (smart-odsc-core contract — response has `data` + `pagination.total`).
  // 3x2 = 6 items per page → we send `limit=6`. `services` holds ONLY
  // the current page's rows; `totalItems` is the backend total used to
  // compute totalPages. We remember the active search so paging next/prev
  // preserves the filter.
  static const int servicesPageSize = 6;
  final RxInt currentPage = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxString currentQuery = "".obs;

  // Local filtering based on currentQuery.value
  List<dynamic> get filteredServices {
    if (currentQuery.value.isEmpty) {
      return services;
    }
    final query = currentQuery.value.toLowerCase();
    return services.where((service) {
      final name = (service['name']?.toString() ?? "").toLowerCase();
      return name.contains(query);
    }).toList();
  }

  // Compute total pages from the locally filtered list
  int get totalPages {
    final total = filteredServices.length;
    if (total <= 0) return 1;
    return (total / servicesPageSize).ceil();
  }

  // Slice the locally filtered list for the current page
  List<dynamic> get pagedServices {
    final filtered = filteredServices;
    final start = (currentPage.value - 1) * servicesPageSize;
    if (start >= filtered.length) return [];
    final end = (start + servicesPageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  @override
  void onInit() {
    print('🚀 [KIOSK_BOOT] KioskController onInit successfully executed. Ready for actions.');
    AppLogger.info('🚀 [KIOSK_BOOT] KioskController onInit successfully executed. Ready for actions.');

    ever(currentStep, (step) {
      print('🔄 [KIOSK_FLOW] currentStep transitioned to: $step');
      AppLogger.info('🔄 [KIOSK_FLOW] currentStep transitioned to: $step');
    });

    searchController = TextEditingController();
    feedbackCommentController = TextEditingController();
    feedbackReferenceController = TextEditingController();
    feedbackReferenceController.addListener(() {
      feedbackReferenceLength.value =
          feedbackReferenceController.text.length;
    });
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
    currentQuery.value = query.trim();
    currentPage.value = 1;
  }

  void clearSearch() {
    searchController.clear();
    currentQuery.value = "";
    currentPage.value = 1;
  }

  // Public entry point used by `onInit`. Resets to page 1 with no
  // active search.
  Future<void> fetchServices({String? query}) async {
    currentQuery.value = (query ?? "").trim();
    currentPage.value = 1;
    await _fetchServicesPage();
  }

  // Fetch all active services once from the server (using a high limit to get all)
  Future<void> _fetchServicesPage() async {
    // Only fetch from the server if the local list is empty to avoid redundant hits
    if (services.isNotEmpty) return;

    isLoading.value = true;
    try {
      final Map<String, dynamic> queryParams = {
        'status': true,
        'limit': 200, // Fetch all active services at once
      };

      final response = await api.get(
        ApiEndpoints.services,
        queryParameters: queryParams,
      );
      if (response['data'] != null) {
        services.assignAll(response['data']);
        totalItems.value = services.length;
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
    if (currentStep.value < 9) {
      // Logic for skipping service selection if already selected from Directory (Step 10)
      if (currentStep.value == 6 && selectedServiceId.value.isNotEmpty) {
        submitBooking(selectedServiceId.value, selectedServiceName.value);
        return;
      }

      currentStep.value++;
      if (currentStep.value == 9) {
        startTimer();
        autoPrint();
      }
    }
  }

  void prevStep() {
    if (currentStep.value > 1) {
      if (currentStep.value == 9 ||
          currentStep.value == 10 ||
          currentStep.value == 11) {
        // If coming back from ticket result, Service Directory, or Feedback, reset to welcome
        resetBooking();
      } else if (currentStep.value == 12) {
        // Step 12 is the print/photo choice reached only from Skip on
        // step 7 — go back to service_choice, not 11.
        currentStep.value = 7;
      } else {
        currentStep.value--;
      }
    }
  }

  /// Routes the user to the print/photo choice step. Called when "Skip"
  /// is tapped on service_choice — they still need to decide whether to
  /// receive their ticket on paper or by photographing the QR.
  void goToPrintChoice() {
    currentStep.value = 12;
  }

  void resetBooking() {
    currentStep.value = 1;
    gender.value = "";
    ethnicity.value = "";
    ageRange.value = "";
    isDisabled.value = false;
    visitPurpose.value = "";
    selectedServiceId.value = "";
    selectedServiceName.value = "";
    queueNumber.value = "";
    barCodeNumber.value = "";
    skipPrint.value = false;
    _timer?.cancel();
    // Reset Feedback
    feedbackRating.value = 0;
    feedbackCommentController.clear();
    feedbackReferenceController.clear();
    feedbackReferenceLength.value = 0;
    feedbackStep.value = 1;
    feedbackApplication.value = null;
    isFeedbackSubmitted.value = false;
  }

  void startTimer() {
    // If the user chooses to take a photo of the QR code (skipPrint is true),
    // give them 60 seconds to scan/take a picture, otherwise 5 seconds for normal paper prints.
    timeLeft.value = skipPrint.value ? 60 : 5;
    _timer?.cancel();
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
    CustomDialog.showLoading(message: 'booking.issuing'.tr);

    try {
      final userData = storage.read('user');
      if (userData == null) {
        CustomDialog.hideLoading();
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'booking.error.not_logged_in'.tr,
        );
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

      // If a specific service was selected, organizationId must be resolvable.
      if (serviceId.isNotEmpty && orgId == null) {
        CustomDialog.hideLoading();
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'booking.error.no_organization'.tr,
        );
        return;
      }

      final payload = {
        "gender": gender.value.isEmpty ? "OTHER" : gender.value,
        "ethnicity": ethnicity.value.isEmpty ? "OTHER" : ethnicity.value,
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
        currentStep.value = 9; // Jump to result step
        if (Get.currentRoute != '/kiosk') {
          Get.back(); // Return from ServiceDetailPage if we are there
        }
        startTimer();
        autoPrint();
      } else {
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'booking.error.cannot_issue'.tr,
        );
      }
    } catch (e) {
      CustomDialog.hideLoading();
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: ErrorHandler.getMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> autoPrint() async {
    // User picked "Photo" on the print/photo step — they want to scan
    // the on-screen QR with their phone instead of getting a paper ticket.
    if (skipPrint.value) return;
    try {
      if (await printerService.bluetooth.isConnected ?? false) {
        final Uint8List imageBytes = await screenshotController
            .captureFromWidget(
              PrintableTicket(
                queueNumber: queueNumber.value,
                serviceName: selectedServiceName.value,
                barCodeNumber: barCodeNumber.value,
                qrCodeData: trackingUrl.value,
                ethnicity: ethnicity.value,
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
    print('💬 [FEEDBACK] selectRating: rating=$rating, label="$label"');
    AppLogger.info('💬 [FEEDBACK] selectRating: rating=$rating, label="$label"');
    feedbackRating.value = rating;
    if (rating > 1) {
      feedbackCommentController.text = label;
    } else {
      feedbackCommentController.clear();
      // Keep it at 1 to show the text field in the UI
    }
  }

  Future<bool> submitFeedback() async {
    print('📤 [FEEDBACK_SUBMIT] submitFeedback called');
    AppLogger.info('📤 [FEEDBACK_SUBMIT] submitFeedback called');
    if (feedbackRating.value == 0) {
      print('⚠️ [FEEDBACK_SUBMIT] Aborted: Rating value is 0 (No rating selected)');
      AppLogger.warning('⚠️ [FEEDBACK_SUBMIT] Aborted: Rating value is 0 (No rating selected)');
      return false;
    }

    if (feedbackReferenceController.text.length != 8) {
      print('⚠️ [FEEDBACK_SUBMIT] Aborted: Reference number length is not 8 digits.');
      AppLogger.warning('⚠️ [FEEDBACK_SUBMIT] Aborted: Reference number length is not 8 digits.');
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: 'feedback.error.reference_length'.tr,
      );
      return false;
    }

    isSubmittingFeedback.value = true;
    try {
      final userData = storage.read('user');
      if (userData == null) {
        print('❌ [FEEDBACK_SUBMIT] User data not found in local storage.');
        AppLogger.error('❌ [FEEDBACK_SUBMIT] User data not found in local storage.');
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'booking.error.not_logged_in'.tr,
        );
        return false;
      }
      final user = UserModel.fromJson(userData);

      final profile = user.officerProfile;

      // Always refresh serviceCenterId from the CURRENT user's profile
      // — otherwise a controller instance kept from a previous account
      // would post feedback with the old service-centre id (which the
      // backend rejects → triggers the auth/redirect-to-login flow).
      final scId = profile is Map
          ? _stringValue(profile['serviceCenterId'])
          : null;
      if (scId != null) {
        print('🔄 [FEEDBACK_SUBMIT] Refreshed serviceCenterId: $scId');
        AppLogger.info('🔄 [FEEDBACK_SUBMIT] Refreshed serviceCenterId: $scId');
        serviceCenterId.value = scId;
      }

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
        "type": "QUEUE_APP",
      };

      final apiType = usePublicApiForFeedback.value ? 'Public API (Bypassing Auth Interceptor)' : 'Standard API';
      lastFeedbackRequest.value = 'POST ${ApiEndpoints.feedback} via $apiType\nPayload:\n${jsonEncode(payload)}';
      lastFeedbackResponse.value = 'Loading...';

      print('🚀 [FEEDBACK_SUBMIT] Preparing to POST feedback to endpoint: ${ApiEndpoints.feedback} via $apiType');
      print('📦 [FEEDBACK_SUBMIT] Payload: $payload');
      AppLogger.info('📤 Feedback Payload (about to POST): $payload');
      AppLogger.info('Profile: $profile');

      // Re-enabled the real API call. AuthenticationInterceptor's
      // _skipAuthRedirectPaths already includes /master-data/feedback,
      // so a 401 from this endpoint will surface as a normal error
      // (handled in the catch below) without kicking staff back to
      // /login. Once backend lifts auth from POST /feedback this just
      // starts succeeding with no further change.
      final response = usePublicApiForFeedback.value 
          ? await api.postPublic(ApiEndpoints.feedback, data: payload)
          : await api.post(ApiEndpoints.feedback, data: payload);
      
      print('📥 [FEEDBACK_SUBMIT] Received response from backend: $response');
      AppLogger.info('📥 Feedback Response: $response');
      lastFeedbackResponse.value = 'Status: Success\nResponse:\n${response.toString()}';

      if (response['message'] == 'SUCCESS' || response['status'] == true) {
        print('✅ [FEEDBACK_SUBMIT] Feedback submitted successfully!');
        AppLogger.info('✅ [FEEDBACK_SUBMIT] Feedback submitted successfully!');
        feedbackRating.value = 0;
        feedbackCommentController.clear();
        feedbackReferenceController.clear();
        feedbackReferenceLength.value = 0;
        feedbackStep.value = 1;
        feedbackApplication.value = null;
        isFeedbackSubmitted.value = true;
        return true;
      } else {
        print('❌ [FEEDBACK_SUBMIT] Submission rejected by backend: message/status mismatch');
        AppLogger.warning('❌ [FEEDBACK_SUBMIT] Submission rejected by backend: message/status mismatch');
        CustomDialog.showError(
          title: 'common.error'.tr,
          message: 'feedback.error.network'.tr,
        );
        return false;
      }
    } catch (e) {
      print('💥 [FEEDBACK_SUBMIT] Exception occurred: $e');
      AppLogger.error('Feedback submission error: $e');
      if (e is ApiException) {
        print('💥 [FEEDBACK_SUBMIT] ApiException response body: ${e.response}');
        AppLogger.error('Feedback Error Response: ${e.response}');
        lastFeedbackResponse.value = 'ApiException Code: ${e.statusCode}\nResponse:\n${e.response}\nMessage: ${e.message}';
      } else {
        lastFeedbackResponse.value = 'Error:\n$e';
      }
      
      String errMsg = ErrorHandler.getMessage(e);
      if (showFeedbackDebugPanel.value) {
        errMsg += '\n\nDebug Info:\n$e';
        if (e is ApiException) {
          errMsg += '\nResponse: ${e.response}';
        }
      }
      
      CustomDialog.showError(
        title: 'common.error'.tr,
        message: errMsg,
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
