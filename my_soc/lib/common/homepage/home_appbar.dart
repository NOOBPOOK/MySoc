import 'package:flutter/material.dart';

// ---------------------------------------------------------
// UI Component: HomeAppBar
// ---------------------------------------------------------
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String fullName;
  final String wingFlat;
  final String wingFlatCombo;
  final double height;

  const HomeAppBar({
    super.key,
    required this.fullName,
    required this.wingFlat,
    required this.wingFlatCombo,
    required this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF222A54), Color(0xFF151B3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      titleSpacing: 20.0,
      title: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 32, // Prominent font size (2x previous)
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            if (wingFlat.isNotEmpty)
              Text(
                wingFlat,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (wingFlatCombo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x3DFFFFFF), // Translucent white (24% opacity)
                      Color(0x0AFFFFFF), // Translucent white (4% opacity)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(
                        0x4DFFFFFF), // Frosted white border (30% opacity)
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(
                          0x1F222A54), // Subtle dark blue shadow (12% opacity)
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  wingFlatCombo,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 16, // Increased font size from 13 to 16
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 20),
      ],
    );
  }
}
