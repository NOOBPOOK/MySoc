import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/common/sec_maintain/maintain_widgets.dart';

// ---------------------------------------------------------
// UI Component: MaintainDueDetailsCard
// ---------------------------------------------------------
class MaintainDueDetailsCard extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onSelectDueDate;
  final TextEditingController descriptionController;

  const MaintainDueDetailsCard({
    super.key,
    required this.dueDate,
    required this.onSelectDueDate,
    required this.descriptionController,
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
                Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Finalization & Due Date",
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaintainDatePickerTarget(
                  label: "Payment Due Date",
                  value: dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : "Select Date",
                  icon: Icons.calendar_today_rounded,
                  onTap: onSelectDueDate,
                ),
                const SizedBox(height: 14),
                const MaintainFieldLabel(label: "Custom Billing Notes"),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Enter billing details, special terms or notes...",
                    filled: true,
                    fillColor: const Color(0xFF222A54).withOpacity(0.02),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.8),
                    ),
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
