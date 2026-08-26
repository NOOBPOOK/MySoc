import 'package:flutter/material.dart';

// ---------------------------------------------------------
// UI Component: MaintainFieldLabel
// ---------------------------------------------------------
class MaintainFieldLabel extends StatelessWidget {
  final String label;
  const MaintainFieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF222A54),
          fontFamily: "Poppins",
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: MaintainDatePickerTarget
// ---------------------------------------------------------
class MaintainDatePickerTarget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const MaintainDatePickerTarget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MaintainFieldLabel(label: label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF222A54).withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222A54).withOpacity(0.12), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222A54),
                  ),
                ),
                Icon(icon, size: 16, color: const Color(0xFF222A54)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: MaintainAmountField
// ---------------------------------------------------------
class MaintainAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;

  const MaintainAmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MaintainFieldLabel(label: label),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222A54),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF222A54), size: 18),
            prefixText: "₹ ",
            prefixStyle: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
            ),
            filled: true,
            fillColor: const Color(0xFF222A54).withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
