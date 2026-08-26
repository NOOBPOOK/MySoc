import 'package:flutter/material.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';

// ---------------------------------------------------------
// UI Component: AnalyticsView
// ---------------------------------------------------------
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  // UI: Build visual KPI Summary Card
  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
              fontFamily: "Poppins",
            ),
          ),
        ],
      ),
    );
  }

  // UI: Draw trend chart bar using pure Flutter Containers
  Widget _buildTrendBar(String month, double heightPercent, String amount) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amount,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF222A54)),
          ),
          const SizedBox(height: 4),
          // Interactive visual bar
          Container(
            height: 120.0 * heightPercent,
            width: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF222A54), Color(0xFF3F4E99)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF222A54).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            month,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadedScrollMask(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid Section
            const Text(
              "Collection Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222A54),
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildKPICard(
                  title: "Total Collected",
                  value: "₹92,800",
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                  subtitle: "+12% MoM",
                ),
                _buildKPICard(
                  title: "Total Pending",
                  value: "₹18,500",
                  icon: Icons.hourglass_empty_rounded,
                  color: Colors.orange,
                  subtitle: "-4% MoM",
                ),
                _buildKPICard(
                  title: "Collection Rate",
                  value: "83.4%",
                  icon: Icons.donut_large_rounded,
                  color: Colors.blue,
                  subtitle: "Target 90%",
                ),
                _buildKPICard(
                  title: "Defaulters",
                  value: "7 Flats",
                  icon: Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  subtitle: "Urgent Action",
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Visual Chart Section: Trend Chart
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Collection Trend (₹)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTrendBar("Mar", 0.6, "60K"),
                        _buildTrendBar("Apr", 0.75, "75K"),
                        _buildTrendBar("May", 0.7, "70K"),
                        _buildTrendBar("Jun", 0.9, "90K"),
                        _buildTrendBar("Jul", 0.82, "82K"),
                        _buildTrendBar("Aug", 0.92, "92K"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
