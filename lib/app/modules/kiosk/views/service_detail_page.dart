import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/data/api_helper/api_service.dart';
import 'package:smart_odsc_queue/app/data/constants/api_endpoints.dart';
import 'package:smart_odsc_queue/app/modules/kiosk/controllers/kiosk_controller.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final bool isViewOnly;

  const ServiceDetailPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.isViewOnly = false,
  });

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final HelpersApi api = HelpersApi();
  Map<String, dynamic>? service;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final resp = await api.get(
        '${ApiEndpoints.services}/${widget.serviceId}',
      );
      setState(() {
        service = resp['data'] as Map<String, dynamic>?;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> _getApprovalSteps(Map<String, dynamic> service) {
    final workflows = service['workflows'];
    if (workflows == null || workflows['nodes'] == null) return [];

    List<dynamic> nodes = List.from(workflows['nodes']);

    // Filtering logic
    nodes = nodes.where((node) {
      final data = node['data'];
      final method = data?['method'] ?? node['type'];
      if (method == 'NODE_IF_ELSE') return false;
      if (data?['isShow'] == false) return false;
      return true;
    }).toList();

    // Sorting logic
    nodes.sort((a, b) {
      int ai = a['data']?['index'] ?? 999;
      int bi = b['data']?['index'] ?? 999;
      return ai.compareTo(bi);
    });

    return nodes;
  }

  Map<String, dynamic> _calculateMetrics(Map<String, dynamic> service) {
    final workflows = service['workflows'];
    final List<dynamic> nodes = workflows?['nodes'] ?? [];
    final List<dynamic> approvalSteps = _getApprovalSteps(service);

    int totalDays = 0;
    double totalFees =
        double.tryParse(service['feeAmount']?.toString() ?? '0') ?? 0;
    int fileFieldsCount = 0;
    int sampleDocsCount = 0;

    for (var node in nodes) {
      final data = node['data'];
      totalDays += int.tryParse(data?['estimatedDays']?.toString() ?? '0') ?? 0;

      final method = data?['method'] ?? node['type'];
      if (method == 'NODE_PAYMENT') {
        final List<dynamic> items = data?['paymentItems'] ?? [];
        for (var item in items) {
          if (item['priceType'] == 'fixed' || item['priceType'] == null) {
            double price =
                double.tryParse(item['price']?.toString() ?? '0') ?? 0;
            int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            totalFees += (price * qty);
          }
        }
        totalFees +=
            double.tryParse(data?['feeAmount']?.toString() ?? '0') ?? 0;
      }

      if (method == 'NODE_START') {
        final List<dynamic> inputFields = data?['inputFields'] ?? [];
        fileFieldsCount = inputFields.where((f) => f['type'] == 'file').length;

        final List<dynamic> sampleDocuments = data?['sampleDocuments'] ?? [];
        sampleDocsCount = sampleDocuments
            .where((d) => d['isPrivate'] != true)
            .length;
      }
    }

    return {
      'totalDays': totalDays,
      'totalFees': totalFees,
      'totalSteps': approvalSteps.length,
      'requiredDocs': fileFieldsCount + sampleDocsCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final kioskController = Get.find<KioskController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.serviceName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.mainCorlor,
              ),
            )
          : (error != null || service == null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(error ?? 'Failed to load'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchDetail,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(service!),
                      const SizedBox(height: 24),
                      _buildStats(_calculateMetrics(service!)),
                      const SizedBox(height: 24),
                      _buildMainContent(service!),
                    ],
                  ),
                ),
                _buildBottomAction(kioskController),
              ],
            ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> service) {
    String? orgName;
    if (service['ministry'] != null) {
      orgName = service['ministry']['name'];
    } else if (service['organization'] != null) {
      orgName = service['organization']['name'];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(12),
            child:
                service['icon'] != null && service['icon'].toString().isNotEmpty
                ? Image.network(
                    "https://storage-console.odsc.gov.la/odsc-public-storage/images/original/${service['icon']}",
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.blueGrey,
                    ),
                  )
                : const Icon(Icons.business, size: 40, color: Colors.blueGrey),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] ?? widget.serviceName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                if (service['shortDescription'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    service['shortDescription'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: ColorConstants.mainCorlor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        orgName ?? 'ຫ້ອງການລັດຖະບານ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.mainCorlor,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> metrics) {
    final currencyFormat = NumberFormat("#,###", "lo_LA");

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.access_time_rounded,
          label: 'ເວລາຄາດການ',
          value: '${metrics['totalDays']} ວັນ',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.payments_outlined,
          label: 'ຄ່າທຳນຽມທັງໝົດ',
          value: '${currencyFormat.format(metrics['totalFees'])} ກີບ',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.layers_outlined,
          label: 'ຂັ້ນຕອນທັງໝົດ',
          value: '${metrics['totalSteps']} ຂັ້ນຕອນ',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.description_outlined,
          label: 'ເອກະສານທີ່ຕ້ອງມີ',
          value: '${metrics['requiredDocs']} ລາຍການ',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey[300]),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400],
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> service) {
    final steps = _getApprovalSteps(service);

    final startNode = (service['workflows']?['nodes'] as List?)?.firstWhere(
      (n) => n['data']?['method'] == 'NODE_START',
      orElse: () => null,
    );
    final fileFields =
        (startNode?['data']?['inputFields'] as List?)
            ?.where((f) => f['type'] == 'file')
            .toList() ??
        [];
    final sampleDocs =
        (startNode?['data']?['sampleDocuments'] as List?)
            ?.where((d) => d['isPrivate'] != true)
            .toList() ??
        [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'ລາຍລະອຽດບໍລິການ',
                child: Html(
                  data: service['description'] ?? 'ບໍ່ມີຂໍ້ມູນລາຍລະອຽດ',
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      color: const Color(0xFF475569),
                      lineHeight: const LineHeight(1.6),
                      margin: Margins.zero,
                    ),
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildFeeSection(service),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'ຂັ້ນຕອນການອະນຸມັດ',
                child: steps.isEmpty
                    ? const Center(child: Text('ບໍ່ມີຂໍ້ມູນຂັ້ນຕອນ'))
                    : Column(
                        children: List.generate(steps.length, (index) {
                          final node = steps[index];
                          return _buildStepItem(
                            index: index + 1,
                            title:
                                node['data']?['label'] ??
                                node['name'] ??
                                'ຂັ້ນຕອນ',
                            description: node['data']?['description'],
                            days: int.tryParse(
                              node['data']?['estimatedDays']?.toString() ?? '0',
                            ),
                            isLast: index == steps.length - 1,
                          );
                        }),
                      ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'ເອກະສານທີ່ຈຳເປັນ',
                child: (fileFields.isEmpty && sampleDocs.isEmpty)
                    ? const Center(child: Text('ບໍ່ມີເອກะສານທີ່ຈຳເປັນ'))
                    : Column(
                        children: [
                          ...fileFields.map(
                            (f) => _buildDocItem(f['label'] ?? 'ເອກະສານ'),
                          ),
                          ...sampleDocs.map(
                            (d) => _buildDocItem(d['name'] ?? 'ຕົວຢ່າງເອກະສານ'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: ColorConstants.mainCorlor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFeeSection(Map<String, dynamic> service) {
    final metrics = _calculateMetrics(service);
    final currencyFormat = NumberFormat("#,###", "lo_LA");
    final feeType = service['feeType'] ?? 'FREE';

    Widget feeIcon;
    String feeLabel;
    String feeDesc;

    if (feeType == 'FREE' || feeType == 'NONE') {
      feeIcon = const Icon(Icons.money_off_rounded, color: Colors.blueGrey);
      feeLabel = 'ບໍ່ມີຄ່າທຳນຽມ';
      feeDesc = 'ບໍລິການນີ້ບໍ່ມີການເກັບຄ່າທຳນຽມ';
    } else if (feeType == 'FIXED') {
      feeIcon = const Icon(Icons.payments_rounded, color: Colors.blueGrey);
      feeLabel = 'ຄ່າທຳນຽມຄົງທີ່';
      feeDesc = 'ມີການເກັບຄ່າທຳນຽມໃນອັດຕາຄົງທີ່';
    } else {
      feeIcon = const Icon(Icons.calculate_rounded, color: Colors.blueGrey);
      feeLabel = 'ຄ່າທຳນຽມຕາມການໃຊ້ງານ';
      feeDesc = 'ຄ່າທຳນຽມອາດປ່ຽນແປງຕາມເງື່ອນໄຂ';
    }

    return _buildSection(
      title: 'ຂໍ້ມູນຄ່າທຳນຽມ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: feeIcon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      feeDesc,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metrics['totalFees'] > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ລວມທັງໝົດ',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    '${currencyFormat.format(metrics['totalFees'])} ກີບ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: ColorConstants.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String title,
    String? description,
    int? days,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x403B82F6),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(1),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (days != null && days > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ເວລາຄາດການ: $days ວັນ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.file_present_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(KioskController kioskController) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SizedBox(
          height: 70,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.isViewOnly) {
                // If coming from Directory (Step 9), we pre-select service and start booking flow
                kioskController.selectedServiceId.value = widget.serviceId;
                kioskController.selectedServiceName.value = widget.serviceName;
                kioskController.currentStep.value = 2; // Go to Gender step
                Get.back(); // Close detail page
              } else {
                kioskController.submitBooking(
                  widget.serviceId,
                  widget.serviceName,
                );
              }
            },
            icon: const Icon(Icons.touch_app_rounded, size: 28),
            label: const Text(
              'ກົດບັດຄິວ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.mainCorlor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
