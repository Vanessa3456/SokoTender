import 'package:flutter/material.dart';
import 'package:soko_tender/pages/bidding.dart'; // Make sure this path points to your bidding screen

class TenderDetailsScreen extends StatelessWidget {
  final String tenderId;
  final String institutionName;
  final String itemName;
  final String quantity;
  final String distance;
  final String highestBid;
  final String timeRemaining;
  final String icon;
  final Color bgColor;

  const TenderDetailsScreen({
    Key? key,
    required this.tenderId,
    required this.institutionName,
    required this.itemName,
    required this.quantity,
    required this.distance,
    required this.highestBid,
    required this.timeRemaining,
    required this.icon,
    required this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Tender Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // STICKY BOTTOM BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to the Bidding Input Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BiddingScreen(
                    tenderId:tenderId,
                    institutionName: institutionName,
                    itemName: itemName,
                    quantity: quantity,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'PLACE BID NOW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$quantity $itemName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        institutionName,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QUICK STATS ROW
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Current Highest Bid',
                    value: highestBid,
                    icon: Icons.payments,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Time Remaining',
                    value: timeRemaining,
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // REQUIREMENTS SECTION
            const Text(
              'Buyer Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequirementRow(
                    icon: Icons.calendar_today,
                    title: 'Delivery Date',
                    detail: 'Thursday, 5th March 2026 before 9:00 AM',
                  ),
                  const Divider(height: 30),
                  _buildRequirementRow(
                    icon: Icons.check_circle_outline,
                    title: 'Quality Standard',
                    detail: 'Produce must be fresh, clean, and packed in proper delivery crates.',
                  ),
                  const Divider(height: 30),
                  _buildRequirementRow(
                    icon: Icons.local_shipping_outlined,
                    title: 'Transport',
                    detail: 'Seller is responsible for transport costs to the institution gate.',
                  ),
                  const Divider(height: 30),
                  _buildRequirementRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment Terms',
                    detail: 'Payment will be sent directly to your M-Pesa within 24 hours of successful delivery and inspection.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20), // Bottom padding before sticky button
          ],
        ),
      ),
    );
  }

  // Helper Widget for the small stat cards (Highest Bid / Time Left)
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper Widget for the requirement rows
  Widget _buildRequirementRow({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}