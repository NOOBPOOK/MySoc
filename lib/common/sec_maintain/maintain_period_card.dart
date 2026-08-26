import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/common/sec_maintain/maintain_widgets.dart';

// ---------------------------------------------------------
// UI Component: MaintainPeriodCard
// ---------------------------------------------------------
class MaintainPeriodCard extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? tillDate;
  final VoidCallback onSelectFromDate;
  final VoidCallback onSelectTillDate;

  const MaintainPeriodCard({
    super.key,
    required this.fromDate,
    required this.tillDate,
    required this.onSelectFromDate,
    required this.onSelectTillDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF222A54),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Billing Period",
                  style: TextStyle(
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
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: MaintainDatePickerTarget(
                    label: "From Date",
                    value: fromDate != null ? DateFormat('dd/MM/yyyy').format(fromDate!) : "Select Date",
                    icon: Icons.calendar_today_rounded,
                    onTap: onSelectFromDate,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: MaintainDatePickerTarget(
                    label: "Till Date",
                    value: tillDate != null ? DateFormat('dd/MM/yyyy').format(tillDate!) : "Select Date",
                    icon: Icons.calendar_today_rounded,
                    onTap: onSelectTillDate,
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
