import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soko_tender/components/notification_badge.dart';
import 'package:soko_tender/pages/bidding.dart';
import 'package:soko_tender/pages/mybids.dart';
import 'package:soko_tender/pages/notification.dart';
import 'package:soko_tender/pages/profile.dart';
import 'package:soko_tender/pages/tender_screen.dart';
import 'package:soko_tender/pages/wallet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // 1. Create a list of the screens you want to navigate between
  final List<Widget> _screens = [
    const HomeDashboard(),
    const MyBidsScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. The body now simply displays whichever screen is currently selected
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // 3. Updating the state here triggers the UI to rebuild and show the new screen
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'My Bids'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String _selectedCategory = 'Vegetables';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  String _firstName = '';
  String? _avatarUrl;
  List<Map<String, dynamic>> _tenders = [];

  double _totalEarnings = 0.0;
  int _pendingBidsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // username
        final profileData = await supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        // 1. Fetch Farmer's Bids for Stats
        final myBidsResponse = await supabase
            .from('bids')
            .select('bid_amount,status')
            .eq('farmer_id', user.id);

        double calcEarnings = 0.0;
        int calcPending = 0;

        for (var bid in myBidsResponse) {
          if (bid['status'] == 'won' || bid['status'] == 'accepted') {
            calcEarnings +=
                double.tryParse(bid['bid_amount'].toString()) ?? 0.0;
          } else if (bid['status'] == 'pending') {
            calcPending++;
          }
        }

        // 2. Fetch active tenders AND their associated bids to calculate the highest bid
        final tendersResponse = await supabase
            .from('tenders')
            .select('*, bids(bid_amount)')
            .eq('status', 'open')
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _totalEarnings = calcEarnings;
            _pendingBidsCount = calcPending;
            // set the first name
            if (profileData != null && profileData['full_name'] != null) {
              _firstName =
                  // profileData['full_name'].split(' ')[0]; // Get the first name
                  profileData['full_name'];
            } else {
              _firstName = 'Farmer';
            }
            _avatarUrl = profileData?['avatar_url'] ?? '';

            _tenders = (tendersResponse as List).map((tender) {
              // calculate the highest bid
              List bids = tender['bids'] ?? [];
              double maxBid = 0;
              for (var bid in bids) {
                double amount =
                    double.tryParse(bid['bid_amount'].toString()) ?? 0;
                if (amount > maxBid) maxBid = amount;
              }
              String highestBidText = maxBid > 0
                  ? 'KES ${maxBid.toStringAsFixed(2)}'
                  : 'No bids yet';

              //  time remainin
              String timeRemaining = 'Closing soon';
              Color badgeColor = Colors.orange;
              if (tender['closing_date'] != null) {
                final closingDate = DateTime.parse(tender['closing_date']);
                final difference = closingDate.difference(DateTime.now());

                if (difference.isNegative) {
                  timeRemaining = 'Closed';
                  badgeColor = Colors.red;
                } else if (difference.inDays > 0) {
                  timeRemaining = '${difference.inDays} Days left';
                  badgeColor = Colors.green;
                } else {
                  timeRemaining = '${difference.inHours}h left';
                  badgeColor = Colors.orange;
                }
              }

              // MAPPING CATEGORIES AND ICONS BASED ON CROP_NAME
              String category = tender['category'] ?? 'Vegetables';
              IconData icon = Icons.eco;
              Color iconColor = Colors.green;
              Color iconBg = const Color(0xFFE8EAF6);

              if (category == 'Grains') {
                icon = Icons.grass;
                iconColor = Colors.orange;
                iconBg = const Color(0xFFFFF3E0);
              } else if (category == 'Fruits') {
                icon = Icons.apple;
                iconColor = Colors.redAccent;
                iconBg = const Color(0xFFFCE4EC);
              } else if (category == 'Dairy') {
                icon = Icons.egg;
                iconColor = Colors.cyan;
                iconBg = const Color(0xFFE0F7FA);
              }

              return {
                'id': tender['id'],
                'institution':
                    tender['institution_name'] ?? 'Unknown Institution',
                'quantity': tender['quantity'].toString() +
                    ' ' +
                    (tender['unit'] ?? ''),
                'item': tender['crop_name'] ?? 'Unknown Crop',
                'category': category,
                'distance':
                    '5km away', // Placeholder, calculate based on user location and institution location
                'highestBid': highestBidText,
                'badgeText': timeRemaining,
                'badgeColor': badgeColor,
                'iconData': icon,
                'iconColor': iconColor,
                'iconContainerColor': iconBg,
              };
            }).toList();

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading tenders: $e'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    List<Map<String, dynamic>> filteredTenders = _tenders.where((tender) {
      final matchesCategory = tender['category'] == _selectedCategory;
      final matchesSearch = tender['item']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          tender['institution']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Overlapping Stats Card
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const NetworkImage(
                                        'https://i.pravatar.cc/150?img=44')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_firstName,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle),
                        // 🔥 YOUR NEW BADGE GOES HERE! 🔥
                        child: const NotificationIconBadge(
                            iconColor: Colors.white),
                      )
                    ],
                  ),
                ),

                // Floating Stats Card
                Padding(
                  padding: const EdgeInsets.only(top: 140, left: 20, right: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL EARNINGS',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('KES ${_totalEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                            width: 1, height: 40, color: Colors.grey.shade300),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PENDING BIDS',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('$_pendingBidsCount',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tenders, schools...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : const Icon(Icons.tune, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Categories (Filter Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryChip('Vegetables'),
                  _buildCategoryChip('Grains'),
                  _buildCategoryChip('Fruits'),
                  _buildCategoryChip('Dairy'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // // Latest Tenders Header
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: const [
            //       Text('Latest Tenders',
            //           style:
            //               TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //       Text('View All',
            //           style: TextStyle(
            //               color: Color(0xFF2E7D32),
            //               fontWeight: FontWeight.w600)),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 16),

            // 4. Render the Filtered Tender Cards List dynamically
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: filteredTenders.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'No tenders available in this category.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : Column(
                      children: filteredTenders.map((tender) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildTenderCard(
                            context: context,
                            tenderId: tender['id'].toString(),
                            institution: tender['institution'],
                            quantity: tender['quantity'],
                            item: tender['item'],
                            distance: tender['distance'],
                            highestBid: tender['highestBid'],
                            badgeText: tender['badgeText'],
                            badgeColor: tender['badgeColor'],
                            iconContainerColor: tender['iconContainerColor'],
                            iconData: tender['iconData'],
                            iconColor: tender['iconColor'],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 5. Updated Category Chip to handle taps
  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label; // Updates the state and rebuilds UI
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildTenderCard({
    required BuildContext context,
    required String institution,
    required String quantity,
    required String item,
    required String distance,
    required String highestBid,
    required String badgeText,
    required Color badgeColor,
    required Color iconContainerColor,
    required IconData iconData,
    required Color iconColor,
    required String tenderId,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: iconContainerColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData, color: iconColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(institution,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(quantity,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ),
                        const SizedBox(width: 8),
                        Text(item,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(distance,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Highest Bid:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(highestBid,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TenderDetailsScreen(
                        tenderId: tenderId,
                        institutionName: institution,
                        itemName: item,
                        quantity: quantity,
                        // We are now passing the extra details to the new screen
                        distance: distance,
                        highestBid: highestBid,
                        timeRemaining: badgeText,
                        icon: '📦', // Placeholder emoji for the big circle
                        bgColor: iconContainerColor,
                      ),
                    ),
                  );

                  //(This runs the moment the user comes back to this screen!)
                  _fetchDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('BID NOW',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---  NEW SHIMMER METHOD ---
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Mock Header & Stats Card area
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mock Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mock Category Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                    4,
                    (index) => Container(
                          margin: const EdgeInsets.only(right: 12),
                          height: 40,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        )),
              ),
            ),
            const SizedBox(height: 40),

            // Mock Tender Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(
                    3,
                    (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            height:
                                140, // Approximate height of your tender card
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
