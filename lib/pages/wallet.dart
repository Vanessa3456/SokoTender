import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  double _availableBalance = 0.0;
  double _totalPending = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      // Fetch the farmer's bids and join the tender info for the transaction history
      final response = await supabase
          .from('bids')
          .select('bid_amount, status, created_at, tenders(institution_name, crop_name)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      double earned = 0.0;
      double pending = 0.0;
      List<Map<String, dynamic>> fetchedTransactions = [];

      for (var row in response) {
        double amount = double.tryParse(row['bid_amount'].toString()) ?? 0.0;
        String status = row['status']?.toString().toLowerCase() ?? 'pending';
        
        final tender = row['tenders'] ?? {};
        String institution = tender['institution_name'] ?? 'Unknown Institution';
        String crop = tender['crop_name'] ?? 'Tender';

        // Format Date (YYYY-MM-DD)
        final rawDate = row['created_at'] != null ? DateTime.parse(row['created_at']) : DateTime.now();
        final String dateString = "${rawDate.year}-${rawDate.month.toString().padLeft(2, '0')}-${rawDate.day.toString().padLeft(2, '0')}";

        if (status == 'won' || status == 'accepted') {
          earned += amount;
          // Add won bids to the transaction history
          fetchedTransactions.add({
            'title': institution,
            'subtitle': 'Tender Payment - $crop',
            'date': dateString,
            'amount': '+KES ${amount.toStringAsFixed(0)}',
            'isCredit': true,
          });
        } else if (status == 'pending') {
          pending += amount;
        }
      }

      if (mounted) {
        setState(() {
          // Since we don't have a 'withdrawals' table yet, Available Balance = Total Earned
          _availableBalance = earned; 
          _totalPending = pending;
          _transactions = fetchedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallet: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KES ${_availableBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Withdraw Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Withdrawal feature coming soon!'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone_android, color: Color(0xFF2E7D32)),
                            label: const Text(
                              'Withdraw to M-Pesa',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Financial Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Earned',
                          amount: 'KES ${_availableBalance.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pending',
                          amount: 'KES ${_totalPending.toStringAsFixed(0)}',
                          icon: Icons.hourglass_empty,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Transaction History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Transactions List
                  Container(
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
                    child: _transactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No completed transactions yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              return _buildTransactionTile(
                                title: tx['title'],
                                subtitle: tx['subtitle'],
                                date: tx['date'],
                                amount: tx['amount'],
                                isCredit: tx['isCredit'],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget for the small summary cards
  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper widget for individual transactions
  Widget _buildTransactionTile({
    required String title,
    required String subtitle,
    required String date,
    required String amount,
    required bool isCredit,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward, // Arrow down means money IN
          color: isCredit ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isCredit ? Colors.green.shade700 : Colors.black87,
        ),
      ),
    );
  }
}