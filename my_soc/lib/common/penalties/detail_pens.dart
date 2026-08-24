import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

class PenaltyDetailsPage extends StatefulWidget {
  const PenaltyDetailsPage({super.key});

  @override
  State<PenaltyDetailsPage> createState() => _PenaltyDetailsPageState();
}

class _ManagePenaltyInfoSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ManagePenaltyInfoSection({
    required this.icon,
    required this.label,
    // ignore: unused_element
    required this.value,
    // ignore: unused_element
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF222A54).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF222A54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyDetailsPageState extends State<PenaltyDetailsPage> {
  late Map<String, dynamic> penalty;
  bool _initialized = false;

  // Backend: Friendly Date Formatter
  String _formatFriendlyDate(Timestamp? timestamp) {
    logger.d(
        'PenaltyDetailsPage: _formatFriendlyDate started with timestamp: $timestamp');
    if (timestamp == null) {
      logger.d('PenaltyDetailsPage: _formatFriendlyDate finished. Output: N/A');
      return 'N/A';
    }
    final dt = timestamp.toDate();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthStr = months[dt.month - 1];
    final formatted = "${dt.day} $monthStr ${dt.year}";
    logger.d(
        'PenaltyDetailsPage: _formatFriendlyDate finished. Output: $formatted');
    return formatted;
  }

  // UI: Build Section Card with Header Bar similar to userDetails.dart
  Widget _buildSectionCard({
    required IconData titleIcon,
    required String title,
    required List<Widget> children,
  }) {
    logger.d('PenaltyDetailsPage: _buildSectionCard started for title: $title');
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: const BoxDecoration(
              color: Color(0xFF222A54),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(titleIcon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
    logger
        .d('PenaltyDetailsPage: _buildSectionCard finished for title: $title');
    return card;
  }

  @override
  void didChangeDependencies() {
    logger.d('PenaltyDetailsPage: didChangeDependencies started');
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null && args.containsKey('penalty')) {
        setState(() {
          penalty = Map<String, dynamic>.from(args['penalty']);
        });
        _initialized = true;
        logger.i(
            'PenaltyDetailsPage: didChangeDependencies successfully loaded penalty: ${penalty['id']}');
      } else {
        logger.w(
            'PenaltyDetailsPage: didChangeDependencies args are null or missing penalty key');
      }
    }
  }

  // UI: Show zoomable image dialog for evidence
  void _showImageDialog(BuildContext context, String imageUrl) {
    logger.i('PenaltyDetailsPage: _showImageDialog started for URL: $imageUrl');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withValues(alpha: 0.9),
              ),
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
    logger.d('PenaltyDetailsPage: _showImageDialog finished showing dialog');
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('PenaltyDetailsPage: _buildAppBar started');
    final appBar = AppBar(
      toolbarHeight: 62.0,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF222A54), width: 2.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        "Penalty Details",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 25,
          color: Color(0xFF222A54),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
    logger.d('PenaltyDetailsPage: _buildAppBar finished');
    return appBar;
  }

  // UI: Sticky Header Card
  Widget _buildHeaderCard({
    required String reason,
    required double totalAmt,
    required bool isPaid,
    required dynamic createdAtVal,
  }) {
    logger
        .d('PenaltyDetailsPage: _buildHeaderCard started for reason: $reason');
    final headerCard = Container(
      width: double.infinity,
      padding:
          const EdgeInsets.only(left: 18.0, right: 18.0, top: 14, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF222A54),
            const Color(0xFF222A54).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF222A54).withValues(alpha: 0.2),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reason (wrap it below)
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.white,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 16),
              // Amount & Label Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${totalAmt.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: isPaid
                          ? const Color(0xFF81C784)
                          : const Color(0xFFFFB74D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPaid ? "Amount Paid" : "Amount to be Paid",
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                "Issued at: ${_formatFriendlyDate(createdAtVal as Timestamp?)}",
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    logger.d('PenaltyDetailsPage: _buildHeaderCard finished');
    return headerCard;
  }

  // UI: Resident Info Card
  Widget _buildResidentInfoCard(String residentName, String wing, String flat) {
    logger.d('PenaltyDetailsPage: _buildResidentInfoCard started');
    final card = _buildSectionCard(
      titleIcon: Icons.person_outline,
      title: "Resident Info",
      children: [
        _ManagePenaltyInfoSection(
          icon: Icons.person_outline,
          label: "Resident Name",
          value: residentName,
        ),
        const Divider(height: 8, color: Color(0xFFF1F1F1)),
        _ManagePenaltyInfoSection(
          icon: Icons.home_outlined,
          label: "Wing - Flat",
          value: "$wing - $flat",
        ),
      ],
    );
    logger.d('PenaltyDetailsPage: _buildResidentInfoCard finished');
    return card;
  }

  // UI: Penalty Details Card
  Widget _buildPenaltyDetailsCard(
      String reason, String description, double baseAmt) {
    logger.d('PenaltyDetailsPage: _buildPenaltyDetailsCard started');
    final card = _buildSectionCard(
      titleIcon: Icons.gavel_outlined,
      title: "Penalty Details",
      children: [
        _ManagePenaltyInfoSection(
          icon: Icons.gavel_outlined,
          label: "Reason",
          value: reason,
        ),
        const Divider(height: 8, color: Color(0xFFF1F1F1)),
        _ManagePenaltyInfoSection(
          icon: Icons.description_outlined,
          label: "Description",
          value: description,
        ),
        const Divider(height: 8, color: Color(0xFFF1F1F1)),
        _ManagePenaltyInfoSection(
          icon: Icons.currency_rupee,
          label: "Base Amount",
          value: "₹${baseAmt.toStringAsFixed(0)}",
        ),
      ],
    );
    logger.d('PenaltyDetailsPage: _buildPenaltyDetailsCard finished');
    return card;
  }

  // UI: Timeline Card
  Widget _buildTimelineCard(
      String createdBy, dynamic createdAtVal, dynamic dueDateVal) {
    logger.d('PenaltyDetailsPage: _buildTimelineCard started');
    final card = _buildSectionCard(
      titleIcon: Icons.history_toggle_off_rounded,
      title: "Timeline & Audit Info",
      children: [
        _ManagePenaltyInfoSection(
          icon: Icons.admin_panel_settings_outlined,
          label: "Issued By",
          value: createdBy,
        ),
        const Divider(height: 8, color: Color(0xFFF1F1F1)),
        _ManagePenaltyInfoSection(
          icon: Icons.calendar_today_outlined,
          label: "Issued Date",
          value: _formatFriendlyDate(createdAtVal as Timestamp?),
        ),
        const Divider(height: 8, color: Color(0xFFF1F1F1)),
        _ManagePenaltyInfoSection(
          icon: Icons.hourglass_bottom_outlined,
          label: "Due Date",
          value: _formatFriendlyDate(dueDateVal as Timestamp?),
        ),
      ],
    );
    logger.d('PenaltyDetailsPage: _buildTimelineCard finished');
    return card;
  }

  // UI: Overdue Alert Box
  Widget _buildOverdueAlert(bool isOverdue, int daysPast, double baseAmt,
      double additionalCharge, double totalAmt) {
    logger.d(
        'PenaltyDetailsPage: _buildOverdueAlert started with isOverdue: $isOverdue');
    if (!isOverdue) {
      logger.d(
          'PenaltyDetailsPage: _buildOverdueAlert finished. Output: Empty box');
      return const SizedBox.shrink();
    }
    final box = Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Overdue Alert",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This penalty is overdue by $daysPast days.\n"
                  "• Base Amount: ₹${baseAmt.toStringAsFixed(0)}\n"
                  "• Additional Charge (₹5/day): ₹${additionalCharge.toStringAsFixed(0)}\n"
                  "• Total Amount: ₹${totalAmt.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 12,
                    color: Colors.red.shade900,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    logger.d('PenaltyDetailsPage: _buildOverdueAlert finished');
    return box;
  }

  // UI: Evidence Attachments
  Widget _buildEvidenceSection(List<String> proofImages) {
    logger.d(
        'PenaltyDetailsPage: _buildEvidenceSection started. Count: ${proofImages.length}');
    if (proofImages.isEmpty) {
      logger.d(
          'PenaltyDetailsPage: _buildEvidenceSection finished. Output: Empty box');
      return const SizedBox.shrink();
    }
    final section = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Evidence Attachments",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: proofImages.length,
            itemBuilder: (context, index) {
              final imgUrl = proofImages[index];
              return GestureDetector(
                onTap: () => _showImageDialog(context, imgUrl),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
    logger.d('PenaltyDetailsPage: _buildEvidenceSection finished');
    return section;
  }

  // UI: Bottom Sticky Button
  Widget _buildBottomButton(bool isPaid) {
    logger.d(
        'PenaltyDetailsPage: _buildBottomButton started with isPaid: $isPaid');
    final button = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (isPaid) {
            logger.i("Clicked Payment Details for penalty: ${penalty['id']}");
            CustomToast.show(context,
                type: 1, message: "Payment details viewed.");
          } else {
            logger.i("Clicked Pay Now for penalty: ${penalty['id']}");
            CustomToast.show(context,
                type: 1, message: "Pay Now action logged.");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF222A54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
        child: Text(
          isPaid ? "Payment Details" : "Pay Now",
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
    logger.d('PenaltyDetailsPage: _buildBottomButton finished');
    return button;
  }

  @override
  Widget build(BuildContext context) {
    logger.d('PenaltyDetailsPage: build method started');
    if (!_initialized) {
      logger.d(
          'PenaltyDetailsPage: build method finished rendering (not initialized)');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF222A54)),
        ),
      );
    }

    final reason = penalty['reason'] ?? 'No reason';
    final description = penalty['description'] ?? 'No description';
    final amount = penalty['amount']?.toString() ?? '0';
    final isPaid = penalty['status'] == true;
    final wing = penalty['wing'] ?? 'N/A';
    final flat = penalty['flatNumber'] ?? 'N/A';
    final createdBy = penalty['createdBy'] ?? 'Unknown';
    final residentName = penalty['residentName'] ?? 'Unknown';

    // Parse createdAt
    final createdAtVal = penalty['createdAt'];

    // Parse dueDate and compute overdue fine
    final dueDateVal = penalty['dueDate'];
    double additionalCharge = 0;
    int daysPast = 0;
    bool isOverdue = false;

    if (dueDateVal is Timestamp) {
      final dt = dueDateVal.toDate();
      if (!isPaid) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(dt.year, dt.month, dt.day);
        final difference = today.difference(due).inDays;
        if (difference > 0) {
          isOverdue = true;
          daysPast = difference;
          additionalCharge = 5.0 * daysPast;
        }
      }
    }

    final double baseAmt = double.tryParse(amount) ?? 0.0;
    final double totalAmt = baseAmt + additionalCharge;

    // Proof Images list
    final proofImagesVal = penalty['proofImage'];
    List<String> proofImages = [];
    if (proofImagesVal is List) {
      proofImages = List<String>.from(proofImagesVal);
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 14.0, bottom: 0.0),
        child: Column(
          children: [
            _buildHeaderCard(
              reason: reason,
              totalAmt: totalAmt,
              isPaid: isPaid,
              createdAtVal: createdAtVal,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.05, 0.95, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResidentInfoCard(residentName, wing, flat),
                      _buildPenaltyDetailsCard(reason, description, baseAmt),
                      _buildTimelineCard(createdBy, createdAtVal, dueDateVal),
                      _buildOverdueAlert(isOverdue, daysPast, baseAmt,
                          additionalCharge, totalAmt),
                      _buildEvidenceSection(proofImages),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(isPaid),
    );
    logger.d('PenaltyDetailsPage: build method finished rendering');
    return scaffold;
  }
}
