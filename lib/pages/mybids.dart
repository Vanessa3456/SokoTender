import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({Key? key}) : super(key: key);

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeBids = [];
  List<Map<String, dynamic>> _wonBids = [];
  List<Map<String, dynamic>> _lostBids = [];

  @override
  void initState() {
    super.initState();
    _fetchMyBids();
  }

  Future<void> _fetchMyBids() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('bids')
          .select(
              'id, bid_amount, status, created_at, tenders(institution_name, quantity, crop_name)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> active = [];
      List<Map<String, dynamic>> won = [];
      List<Map<String, dynamic>> lost = [];

      for (var row in response) {
        final tender = row['tenders'] ?? {};

        final String quantity = tender['quantity']?.toString() ?? '';
        final String crop = tender['crop_name']?.toString() ?? 'Unknown Item';
        final String itemString = '$quantity $crop'.trim();

        final rawDate = row['created_at'] != null
            ? DateTime.parse(row['created_at'])
            : DateTime.now();
        final String dateString =
            "${rawDate.year}-${rawDate.month.toString().padLeft(2, '0')}-${rawDate.day.toString().padLeft(2, '0')}";

        final String status =
            row['status']?.toString().toLowerCase() ?? 'pending';

        final formattedBid = {
          'id': row['id'].toString(),
          'institution': tender['institution_name'] ?? 'Unknown Institution',
          'item': itemString,
          'dateApplied': dateString,
          'myBid': 'KES ${row['bid_amount']}',
          'status': status.toUpperCase(),
          'rawStatus': status,
        };

        if (status == 'pending') {
          active.add(formattedBid);
        } else if (status == 'won' ||
            status == 'accepted' ||
            status == 'delivered' ||
            status == 'paid') {
          won.add(formattedBid);
        } else {
          lost.add(formattedBid);
        }
      }

      if (mounted) {
        setState(() {
          _activeBids = active;
          _wonBids = won;
          _lostBids = lost;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error loading bids: $e'),
            backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text('My Bids',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Won'),
              Tab(text: 'Lost'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : TabBarView(
                children: [
                  _buildBidsList(
                    bids: _activeBids
                        .map((bid) => _buildBidCard(
                              institution: bid['institution'],
                              item: bid['item'],
                              dateApplied: bid['dateApplied'],
                              myBid: bid['myBid'],
                              status: bid['status'],
                              rawStatus: bid['rawStatus'],
                              statusColor: Colors.orange,
                            ))
                        .toList(),
                  ),
                  _buildBidsList(
                    bids: _wonBids.map((bid) {
                      Color badgeColor = const Color(0xFF2E7D32);
                      if (bid['rawStatus'] == 'delivered')
                        badgeColor = Colors.blue;
                      if (bid['rawStatus'] == 'paid') badgeColor = Colors.teal;

                      return _buildBidCard(
                        institution: bid['institution'],
                        item: bid['item'],
                        dateApplied: bid['dateApplied'],
                        myBid: bid['myBid'],
                        status: bid['status'],
                        rawStatus: bid['rawStatus'],
                        statusColor: badgeColor,
                        isActionable: true,
                      );
                    }).toList(),
                  ),
                  _buildBidsList(
                    bids: _lostBids
                        .map((bid) => _buildBidCard(
                              institution: bid['institution'],
                              item: bid['item'],
                              dateApplied: bid['dateApplied'],
                              myBid: bid['myBid'],
                              status: bid['status'],
                              rawStatus: bid['rawStatus'],
                              statusColor: Colors.red,
                            ))
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBidsList({required List<Widget> bids}) {
    if (bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No bids in this category.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => bids[index],
    );
  }

  Widget _buildBidCard({
    required String institution,
    required String item,
    required String dateApplied,
    required String myBid,
    required String status,
    required String rawStatus,
    required Color statusColor,
    bool isActionable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(institution,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5))),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.shopping_basket_outlined,
                size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(item,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800))
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('Applied: $dateApplied',
                style: const TextStyle(fontSize: 12, color: Colors.grey))
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Bid',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(myBid,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              // 🔥 NEW UI: Informational Text instead of a Button
              if (isActionable)
                if (rawStatus == 'won' || rawStatus == 'accepted')
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('Awaiting School Receipt',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  )
                else if (rawStatus == 'delivered')
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('Delivery Verified',
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  )
                else if (rawStatus == 'paid')
                  const Text('Payment Received',
                      style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13))
            ],
          ),
        ],
      ),
    );
  }
}
