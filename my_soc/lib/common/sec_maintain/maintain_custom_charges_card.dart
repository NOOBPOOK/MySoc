import 'package:flutter/material.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: MaintainCustomChargesCard
// ---------------------------------------------------------
class MaintainCustomChargesCard extends StatelessWidget {
  final List<Map<String, dynamic>> customCharges;
  final VoidCallback onAddCustomCharge;
  final Function(int) onRemoveCustomCharge;

  const MaintainCustomChargesCard({
    super.key,
    required this.customCharges,
    required this.onAddCustomCharge,
    required this.onRemoveCustomCharge,
  });

  @override
  Widget build(BuildContext context) {
    logger.d('MaintainCustomChargesCard build triggered. Items count: ${customCharges.length}');

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
                Icon(Icons.add_box_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Custom Charges",
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
                if (customCharges.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222A54).withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF222A54).withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "No custom charges added yet.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customCharges.length,
                    itemBuilder: (context, index) {
                      final item = customCharges[index];
                      final bool isEditing = item['isEditing'] ?? false;

                      if (!isEditing) {
                        // Display committed custom charge card
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A54).withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF222A54).withOpacity(0.12),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222A54).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF222A54), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['resolvedKey'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF222A54),
                                      ),
                                    ),
                                    Text(
                                      "Additional Charge",
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "₹ ${item['resolvedValue'] ?? ''}",
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF222A54),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                onPressed: () => onRemoveCustomCharge(index),
                              ),
                            ],
                          ),
                        );
                      }

                      // Display active editing card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222A54).withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF222A54).withOpacity(0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Custom Charge #${index + 1} (Editing)",
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF222A54),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () => onRemoveCustomCharge(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Stacked input 1: Charge Name
                            TextFormField(
                              controller: item['key'] as TextEditingController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: "Enter Charge Name (e.g. Lift, Security)",
                                labelText: "Charge Name",
                                labelStyle: const TextStyle(fontFamily: "Poppins", fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF222A54)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Name required";
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Stacked input 2: Amount
                            TextFormField(
                              controller: item['value'] as TextEditingController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                prefixText: "₹ ",
                                prefixStyle: const TextStyle(fontFamily: "Poppins", fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF222A54)),
                                hintText: "Enter Amount",
                                labelText: "Amount",
                                labelStyle: const TextStyle(fontFamily: "Poppins", fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF222A54)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFF222A54).withOpacity(0.12)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Required";
                                if (double.tryParse(val) == null) return "Invalid";
                                return null;
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onAddCustomCharge,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text(
                      "Add Custom Charge",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF222A54),
                      side: const BorderSide(color: Color(0xFF222A54), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
