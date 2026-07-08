import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_odsc_queue/app/data/api_helper/api_service.dart';
import 'package:smart_odsc_queue/app/data/constants/api_endpoints.dart';
import 'package:smart_odsc_queue/app/modules/kiosk/controllers/kiosk_controller.dart';
import 'package:smart_odsc_queue/app/shared/constants/app_constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:smart_odsc_queue/app/shared/widgets/loading_indicator.dart';
// .tr extension comes from the `get` import above.

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
          ? const Center(child: LoadingIndicator(size: 120))
          : (error != null || service == null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(error ?? 'common.failed_to_load'.tr),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchDetail,
                    child: Text('common.retry'.tr),
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
          SizedBox(
            width: 80,
            height: 80,
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
                        orgName ?? 'detail.org_fallback'.tr,
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
          label: 'detail.stat.duration'.tr,
          value: '${metrics['totalDays']} ${'detail.unit.days'.tr}',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.payments_outlined,
          label: 'detail.stat.total_fee'.tr,
          value:
              '${currencyFormat.format(metrics['totalFees'])} ${'detail.unit.kip'.tr}',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.layers_outlined,
          label: 'detail.stat.total_steps'.tr,
          value: '${metrics['totalSteps']} ${'detail.unit.steps'.tr}',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.description_outlined,
          label: 'detail.stat.required_docs'.tr,
          value: '${metrics['requiredDocs']} ${'detail.unit.items'.tr}',
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
                title: 'detail.section.description'.tr,
                child: Html(
                  data: service['description'] ?? 'detail.description.empty'.tr,
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
                title: 'detail.section.approval_steps'.tr,
                child: steps.isEmpty
                    ? Center(child: Text('detail.steps.empty'.tr))
                    : Column(
                        children: List.generate(steps.length, (index) {
                          final node = steps[index];
                          return _buildStepItem(
                            index: index + 1,
                            title:
                                node['data']?['label'] ??
                                node['name'] ??
                                'detail.step.fallback_title'.tr,
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
                title: 'detail.section.required_docs'.tr,
                child: (fileFields.isEmpty && sampleDocs.isEmpty)
                    ? Center(child: Text('detail.docs.empty'.tr))
                    : Column(
                        children: [
                          ...fileFields.map(
                            (f) => _buildDocItem(
                              title:
                                  f['label']?.toString() ??
                                  'detail.doc.fallback_label'.tr,
                              sample: f['sampleFile'] is Map
                                  ? Map<String, dynamic>.from(f['sampleFile'])
                                  : null,
                            ),
                          ),
                          ...sampleDocs.map(
                            (d) => _buildDocItem(
                              title:
                                  (d['name'] != null &&
                                      d['name'].toString().isNotEmpty)
                                  ? d['name'].toString()
                                  : 'detail.doc.sample_fallback_label'.tr,
                              // sampleDocuments may carry their own
                              // `file` object (mirrors fileFields' shape)
                              // or a top-level `url`. Try both.
                              sample: d['file'] is Map
                                  ? Map<String, dynamic>.from(d['file'])
                                  : (d['url'] != null
                                        ? {
                                            'url': d['url'],
                                            'name': d['name'],
                                            'type': d['type'],
                                          }
                                        : null),
                            ),
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
      feeLabel = 'detail.fee.free.label'.tr;
      feeDesc = 'detail.fee.free.desc'.tr;
    } else if (feeType == 'FIXED') {
      feeIcon = const Icon(Icons.payments_rounded, color: Colors.blueGrey);
      feeLabel = 'detail.fee.fixed.label'.tr;
      feeDesc = 'detail.fee.fixed.desc'.tr;
    } else {
      feeIcon = const Icon(Icons.calculate_rounded, color: Colors.blueGrey);
      feeLabel = 'detail.fee.variable.label'.tr;
      feeDesc = 'detail.fee.variable.desc'.tr;
    }

    return _buildSection(
      title: 'detail.section.fees'.tr,
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
                  Text(
                    'detail.fee.total'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${currencyFormat.format(metrics['totalFees'])} ${'detail.unit.kip'.tr}',
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
                          '${'detail.step.duration_prefix'.tr}: $days ${'detail.unit.days'.tr}',
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

  Widget _buildDocItem({
    required String title,
    Map<String, dynamic>? sample,
  }) {
    final String? url = sample?['url']?.toString();
    final bool hasPreview = url != null && url.isNotEmpty;

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
          if (hasPreview)
            _DocPreviewEyeButton(
              onTap: () => _showDocumentPreview(
                context: context,
                title: title,
                sample: sample!,
              ),
            ),
        ],
      ),
    );
  }

  void _showDocumentPreview({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> sample,
  }) {
    final String url = sample['url']?.toString() ?? '';
    final String mimeType = sample['type']?.toString() ?? '';
    final bool isImage = mimeType.startsWith('image/');

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
              maxHeight: 700,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPreviewHeader(ctx, title),
                Expanded(child: _buildPreviewBody(url: url, isImage: isImage)),
                _buildPreviewFooter(ctx),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewHeader(BuildContext ctx, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: ColorConstants.mainCorlor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'detail.doc.preview_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.close_rounded, size: 24),
            color: const Color(0xFF64748B),
            tooltip: 'detail.doc.preview_close'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody({required String url, required bool isImage}) {
    return Container(
      color: const Color(0xFFF1F5F9),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: isImage
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => _previewError(),
                ),
              )
            : _previewError(noInline: true),
      ),
    );
  }

  Widget _previewError({bool noInline = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          noInline
              ? Icons.insert_drive_file_rounded
              : Icons.broken_image_rounded,
          size: 72,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          noInline
              ? 'detail.doc.preview_no_inline'.tr
              : 'detail.doc.preview_none'.tr,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPreviewFooter(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Text(
            '1 ${'detail.doc.preview_files_one'.tr}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEC4899),
              side: const BorderSide(color: Color(0xFFFCE7F3), width: 1.5),
              backgroundColor: const Color(0xFFFDF2F8),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'detail.doc.preview_close'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
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
            label: Text(
              'detail.cta.get_ticket'.tr,
              style: const TextStyle(
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

class _DocPreviewEyeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DocPreviewEyeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.remove_red_eye_rounded,
            color: ColorConstants.mainCorlor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
