import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;

  double _unpaidInvoices = 0.0;
  double _clearedPayments = 0.0;
  double _expectedEarnings = 0.0;

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

      final response = await supabase
          .from('bids')
          .select(
              'bid_amount, status, created_at, tenders(institution_name, crop_name)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      double unpaid = 0.0;
      double cleared = 0.0;
      double expected = 0.0;
      List<Map<String, dynamic>> fetchedTransactions = [];

      for (var row in response) {
        double amount = double.tryParse(row['bid_amount'].toString()) ?? 0.0;
        String status = row['status']?.toString().toLowerCase() ?? 'pending';

        final tender = row['tenders'] ?? {};
        String institution =
            tender['institution_name'] ?? 'Unknown Institution';
        String crop = tender['crop_name'] ?? 'Tender';

        final rawDate = row['created_at'] != null
            ? DateTime.parse(row['created_at'])
            : DateTime.now();
        final String dateString =
            "${rawDate.year}-${rawDate.month.toString().padLeft(2, '0')}-${rawDate.day.toString().padLeft(2, '0')}";

        if (status == 'delivered') {
          unpaid += amount;
          fetchedTransactions.add({
            'title': institution,
            'subtitle': 'Invoice Unpaid - $crop',
            'date': dateString,
            'amount': 'KES ${amount.toStringAsFixed(0)}',
            'status': 'unpaid',
          });
        } else if (status == 'paid') {
          cleared += amount;
          fetchedTransactions.add({
            'title': institution,
            'subtitle': 'Payment Cleared - $crop',
            'date': dateString,
            'amount': '+KES ${amount.toStringAsFixed(0)}',
            'status': 'paid',
          });
        } else if (status == 'won' || status == 'accepted') {
          expected += amount;
          fetchedTransactions.add({
            'title': institution,
            'subtitle': 'LPO Issued - $crop',
            'date': dateString,
            'amount': 'KES ${amount.toStringAsFixed(0)}',
            'status': 'expected',
          });
        }
      }

      if (mounted) {
        setState(() {
          _unpaidInvoices = unpaid;
          _clearedPayments = cleared;
          _expectedEarnings = expected;
          _transactions = fetchedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading ledger: $e'),
              backgroundColor: Colors.red),
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
          'Financial Ledger',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: _fetchWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Ledger Card (Back to clean Green)
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
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Total Unpaid Invoices',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'KES ${_unpaidInvoices.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),

                          // Sleek White Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _unpaidInvoices > 0
                                  ? () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Payment reminder sent to respective schools.'),
                                          backgroundColor: Color(0xFF2E7D32),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFF2E7D32)),
                              label: const Text(
                                'Send Payment Reminder',
                                style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Financial Summary Row (Cleaned up)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Cleared (Paid)',
                            amount:
                                'KES ${_clearedPayments.toStringAsFixed(0)}',
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Expected (LPOs)',
                            amount:
                                'KES ${_expectedEarnings.toStringAsFixed(0)}',
                            icon: Icons.schedule,
                            iconColor: Colors.grey.shade700,
                            bgColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Transaction History',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Transactions List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: _transactions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Text('No contract history yet.',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                      height: 1, color: Color(0xFFEEEEEE)),
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                return _buildTransactionTile(
                                  title: tx['title'],
                                  subtitle: tx['subtitle'],
                                  date: tx['date'],
                                  amount: tx['amount'],
                                  status: tx['status'],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
      {required String title,
      required String amount,
      required IconData icon,
      required Color iconColor,
      required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(amount,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
      {required String title,
      required String subtitle,
      required String date,
      required String amount,
      required String status}) {
    // Minimalist styling: Only use Green for money actually received. Everything else is clean grey/black.
    Color iconColor;
    Color bgColor;
    IconData icon;
    Color amountColor;

    if (status == 'paid') {
      iconColor = const Color(0xFF2E7D32);
      bgColor = const Color(0xFFE8F5E9);
      icon = Icons.check_circle;
      amountColor = const Color(0xFF2E7D32);
    } else if (status == 'unpaid') {
      iconColor = Colors.grey.shade700;
      bgColor = Colors.grey.shade100;
      icon = Icons.receipt_long;
      amountColor = Colors.black87;
    } else {
      iconColor = Colors.grey.shade400;
      bgColor = Colors.grey.shade50;
      icon = Icons.schedule;
      amountColor = Colors.grey.shade500;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Text(
        amount,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: amountColor),
      ),
    );
  }
}
