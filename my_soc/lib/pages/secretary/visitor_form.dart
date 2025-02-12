import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class VisitorEntryForm extends StatefulWidget {
  const VisitorEntryForm({super.key});

  @override
  State<VisitorEntryForm> createState() => _VisitorEntryFormState();
}

class _VisitorEntryFormState extends State<VisitorEntryForm> {
  final _formKey = GlobalKey<FormState>();
  bool isForMaintenance = false;
  String selectedWing = 'A';
  String? selectedVisitorType;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController fromWhereController = TextEditingController();
  final TextEditingController peopleCountController = TextEditingController();
  final TextEditingController flatNumberController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  // Visitor type data structure with colors
  final List<Map<String, dynamic>> visitorTypes = [
    {'name': 'Swiggy', 'color': Color(0xFFFC8019)},
    {'name': 'Zomato', 'color': Color(0xFFE23744)},
    {'name': 'Electrician', 'color': Color(0xFF4CAF50)},
    {'name': 'Plumber', 'color': Color(0xFF2196F3)},
    {'name': 'Courriers', 'color': Color(0xFFFFA000)},
  ];

  List<String> wings = ['A', 'B', 'C', 'D'];

  void showWatchmanDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE94560), width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFFE94560),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Current Watchman on Duty',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildWatchmanDetail('Name', 'Rashmi Binkamdar'),
                      _buildWatchmanDetail('Phone', '9845404948'),
                      _buildWatchmanDetail('Shift', 'Morning (8:00 AM)'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchmanDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton.icon(
                              onPressed: showWatchmanDetails,
                              icon: const Icon(
                                Icons.security,
                                color: Color(0xFFE94560),
                              ),
                              label: Text(
                                'Watchman Details',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              WavyAnimatedText(
                                'Add Visitor Entry',
                                textStyle: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            isRepeatingAnimation: false,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: nameController,
                                label: 'Name',
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: fromWhereController,
                                label: 'From Where',
                                icon: Icons.location_on,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: peopleCountController,
                                label: 'People Count',
                                icon: Icons.groups,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedWing,
                                      dropdownColor: const Color(0xFF1A1A2E),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        'Wing',
                                        Icons.apartment,
                                      ),
                                      items: wings.map((wing) {
                                        return DropdownMenuItem(
                                          value: wing,
                                          child: Text('Wing $wing'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => selectedWing = value!);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: flatNumberController,
                                      label: 'Flat No.',
                                      icon: Icons.home,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: visitorTypes.map((type) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                      ),
                                      child: FilterChip(
                                        label: Text(type['name']),
                                        selected:
                                            selectedVisitorType == type['name'],
                                        onSelected: (selected) {
                                          setState(() {
                                            selectedVisitorType =
                                                selected ? type['name'] : null;
                                          });
                                        },
                                        backgroundColor:
                                            type['color'].withOpacity(0.3),
                                        selectedColor: type['color'],
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: selectedVisitorType ==
                                                  type['name']
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: reasonController,
                                label: 'Reason for Visit',
                                icon: Icons.note,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                value: isForMaintenance,
                                onChanged: (value) {
                                  setState(() => isForMaintenance = value!);
                                },
                                title: Text(
                                  'For Building Maintenance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                checkColor: Colors.white,
                                activeColor: const Color(0xFFE94560),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              // Handle form submission
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Visitor entry recorded'),
                                  backgroundColor: Color(0xFFE94560),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Record Entry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return '$label cannot be empty';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      prefixIcon: Icon(icon, color: const Color(0xFFE94560)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
