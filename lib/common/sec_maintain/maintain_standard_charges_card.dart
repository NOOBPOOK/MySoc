import 'package:flutter/material.dart';
import 'package:my_soc/common/sec_maintain/maintain_widgets.dart';

// ---------------------------------------------------------
// UI Component: MaintainStandardChargesCard
// ---------------------------------------------------------
class MaintainStandardChargesCard extends StatelessWidget {
  final TextEditingController baseAmountController;
  final TextEditingController carAmountController;
  final TextEditingController bikeAmountController;

  const MaintainStandardChargesCard({
    super.key,
    required this.baseAmountController,
    required this.carAmountController,
    required this.bikeAmountController,
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
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Standard Charges",
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
                MaintainAmountField(
                  controller: baseAmountController,
                  label: "Base Maintenance",
                  icon: Icons.home_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Required";
                    if (double.tryParse(val) == null) return "Invalid";
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MaintainAmountField(
                        controller: carAmountController,
                        label: "Car Parking",
                        icon: Icons.directions_car_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: MaintainAmountField(
                        controller: bikeAmountController,
                        label: "Bike Parking",
                        icon: Icons.directions_bike_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid";
                          return null;
                        },
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
}
