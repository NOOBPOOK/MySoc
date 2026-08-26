import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/common/members/kysociety.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

class RoleSelectionSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> member;

  const RoleSelectionSheet({
    super.key,
    required this.member,
  });

  @override
  ConsumerState<RoleSelectionSheet> createState() => _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends ConsumerState<RoleSelectionSheet> {
  // Backend: Update user designation in Firestore
  Future<void> _updateUserRole(String memberId, int newDesignation) async {
    logger.i('_RoleSelectionSheetState: _updateUserRole started with memberId: $memberId, newDesignation: $newDesignation');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .update({'designation': newDesignation});
      
      logger.i('_RoleSelectionSheetState: _updateUserRole successfully updated memberId: $memberId to $newDesignation');
      
      if (mounted) {
        CustomToast.show(
          context,
          type: 1,
          message: 'Role updated successfully',
        );
      }
    } catch (e) {
      logger.e('_RoleSelectionSheetState: _updateUserRole error: $e');
      if (mounted) {
        CustomToast.show(
          context,
          type: -1,
          message: 'Failed to update role: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.d('_RoleSelectionSheetState: build started');
    final currentRole = widget.member['designation'] ?? 0;

    final sheetContent = SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select New Role',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF222A54),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the designation for ${widget.member['firstName'] ?? 'user'}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: designationMap.entries
                      .where((entry) => entry.key != 4) // Remove 'Secretary' from list
                      .map((entry) {
                    final roleValue = entry.key;
                    final roleName = entry.value;
                    final isSelected = roleValue == currentRole;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF222A54).withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF222A54)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            logger.i('_RoleSelectionSheetState: Selected role $roleValue ($roleName) for user ${widget.member['id']}');
                            Navigator.pop(context);

                            // Backend: Even if in logic, if user selects Treasurer (2) or Chairman (3), 
                            // it doesn't change anything, and we display an error toast 'Functionality not available'.
                            if (roleValue == 2 || roleValue == 3) {
                              CustomToast.show(
                                context,
                                type: -1,
                                message: 'Functionality not available',
                              );
                              logger.w('_RoleSelectionSheetState: Cannot change to $roleName ($roleValue) - Functionality not available');
                              return;
                            }

                            _updateUserRole(widget.member['id'], roleValue);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSelected
                                          ? const Color(0xFF222A54)
                                          : Colors.grey.shade100,
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.person_outline,
                                        size: 18,
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      roleName,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 15,
                                        color: isSelected ? const Color(0xFF222A54) : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222A54),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    logger.d('_RoleSelectionSheetState: build completed');
    return sheetContent;
  }
}
