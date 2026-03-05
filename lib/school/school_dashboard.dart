import 'package:flutter/material.dart';
import 'package:soko_tender/school/lpo_generator.dart';
import 'package:soko_tender/school/school_login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolDashboardScreen extends StatefulWidget {
  const SchoolDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoadingDashboard = true;
  List<Map<String, dynamic>> _activeTenders = [];
  int _completedOrdersCount = 0;
  String _schoolName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SchoolLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      if (user == null) throw Exception('No user is logged in');

      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      final currentSchoolName = profile['full_name'] ?? 'Unknown Institution';

      // fetch tenders for this specific school and count the bids
      final response = await supabase
          .from('tenders')
          .select('*,bids(id, bid_amount)')
          .eq('institution_name', currentSchoolName)
          .eq('status', 'open') // Only show active tenders on the dashboard
          .order('created_at', ascending: false);

      // 2. Fetch CLOSED tenders to count the completed orders!
      final closedResponse = await supabase
          .from('tenders')
          .select('id')
          .eq('institution_name', currentSchoolName)
          .eq('status', 'closed');

      if (mounted) {
        setState(() {
          _schoolName = currentSchoolName;
          _activeTenders = List<Map<String, dynamic>>.from(response);
          _completedOrdersCount = List.from(closedResponse).length;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Row(
        children: [
          // 1. THE SIDEBAR (Left side)
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  color: const Color(0xFF2E7D32),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOKO TENDER',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Institution Portal',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Navigation Items
                _buildSidebarItem(
                    icon: Icons.dashboard, title: 'Dashboard', index: 0),
                _buildSidebarItem(
                    icon: Icons.add_box, title: 'Post a Tender', index: 1),
                _buildSidebarItem(
                    icon: Icons.gavel, title: 'Review Bids', index: 2),
                _buildSidebarItem(
                    icon: Icons.history, title: 'Order History', index: 3),

                const Spacer(),

                // Bottom Settings & Logout
                const Divider(),
                _buildSidebarItem(
                    icon: Icons.settings, title: 'Settings', index: 4),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _handleLogout();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 2. MAIN CONTENT AREA (Right side)
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPageTitle(), // Dynamic title based on sidebar selection
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.grey),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.account_balance,
                                color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_schoolName,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('Procurement Office',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // Dynamic Scrollable Content based on Sidebar Selection
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NAVIGATION HELPERS ---
  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Post a New Tender';
      case 2:
        return 'Review Active Bids';
      case 3:
        return 'Order History';
      default:
        return 'Settings';
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const PostTenderForm();
      case 2:
        return const ReviewBidsView();
      case 3:
        return const OrderHistoryView();
      default:
        return const Center(
          child: Text('This screen is coming soon!',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
        );
    }
  }

  // --- SIDEBAR WIDGET ---
  Widget _buildSidebarItem(
      {required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            _fetchDashboardData();
          }
        },
      ),
    );
  }

  // --- DASHBOARD OVERVIEW (Index 0) ---
  Widget _buildDashboardOverview() {
    if (_isLoadingDashboard) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    // Calculate dynamic stats
    int totalTenders = _activeTenders.length;
    int totalBids = 0;
    for (var t in _activeTenders) {
      totalBids += (t['bids'] as List?)?.length ?? 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Active Tenders', '$totalTenders',
                      Icons.campaign, Colors.blue)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildStatCard('Total Bids Received', '$totalBids',
                      Icons.gavel, Colors.orange)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildStatCard(
                      'Completed Orders',
                      '$_completedOrdersCount',
                      Icons.check_circle,
                      Colors.green)),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Active Tenders',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Post New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if (_activeTenders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                        child: Text('You have not posted any tenders yet.',
                            style: TextStyle(color: Colors.grey))),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54),
                      columns: const [
                        DataColumn(label: Text('Item Needed')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Closing Date')),
                        DataColumn(label: Text('Bids')), // Hidden prices!
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: _activeTenders.map((tender) {
                        final dateStr = tender['closing_date'] != null
                            ? tender['closing_date'].toString().split('T')[0]
                            : 'N/A';

                        final bidsCount =
                            (tender['bids'] as List?)?.length ?? 0;

                        final rawStatus = tender['status'] ?? 'open';
                        final status =
                            rawStatus[0].toUpperCase() + rawStatus.substring(1);

                        return _buildDataRow(
                            tender['crop_name'] ?? 'Unknown',
                            '${tender['quantity']} ${tender['unit'] ?? ''}',
                            dateStr,
                            bidsCount.toString(),
                            status, () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        });
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String item, String quantity, String date, String bids,
      String status, VoidCallback onReviewPressed) {
    return DataRow(
      cells: [
        DataCell(
            Text(item, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(quantity)),
        DataCell(Text(date)),
        DataCell(Text(bids,
            style: const TextStyle(
                color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Open'
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Open' ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          TextButton(
            onPressed: onReviewPressed,
            child: const Text('Review', style: TextStyle(color: Colors.blue)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// THE "POST A TENDER" FORM WIDGET
// ==========================================
class PostTenderForm extends StatefulWidget {
  const PostTenderForm({Key? key}) : super(key: key);

  @override
  State<PostTenderForm> createState() => _PostTenderFormState();
}

class _PostTenderFormState extends State<PostTenderForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Dropdown selections
  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'Kg';

  // The Date the school wants the tender to close
  DateTime _closingDate = DateTime.now().add(const Duration(days: 7));
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 10)); // 🔥 NEW

  bool _isSubmitting = false;

  final List<String> _categories = ['Vegetables', 'Grains', 'Fruits', 'Dairy'];
  final List<String> _units = ['Kg', 'Bags', 'Liters', 'Crates', 'Pieces'];

  Future<void> _submitTender() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user!.id)
          .single();

      // Send the data to the 'tenders' table in Supabase!
      await supabase.from('tenders').insert({
        'institution_name': profile['full_name'], // Use the fetched school name
        'crop_name': _itemController.text.trim(),
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text.trim()),
        'unit': _selectedUnit,
        'closing_date': _closingDate.toIso8601String(),
        'expected_delivery_date': _expectedDeliveryDate.toIso8601String(),
        'status': 'open',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tender successfully posted to farmers!'),
              backgroundColor: Color(0xFF2E7D32)),
        );
        // Clear the form after success
        _itemController.clear();
        _quantityController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error posting tender: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        constraints: const BoxConstraints(
            maxWidth: 800), // Keeps form from getting too wide
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tender Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Provide the specifics of the produce your institution requires.',
                  style: TextStyle(color: Colors.grey)),
              const Divider(height: 40),

              // ITEM & CATEGORY ROW
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                        'Produce Name (e.g. Dry Maize, Cabbages)',
                        _itemController,
                        Icons.agriculture),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: _buildDropdown(
                        'Category',
                        _categories,
                        _selectedCategory,
                        (val) => setState(() => _selectedCategory = val!)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // QUANTITY & UNIT ROW
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                        'Quantity Required', _quantityController, Icons.scale,
                        isNumber: true),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: _buildDropdown(
                        'Unit of Measurement',
                        _units,
                        _selectedUnit,
                        (val) => setState(() => _selectedUnit = val!)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

            // --- 🔥 DATES ROW (CLOSING & DELIVERY) ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bidding Closing Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context, initialDate: _closingDate,
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _closingDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.gavel, color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Text('${_closingDate.day}/${_closingDate.month}/${_closingDate.year}', style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected Delivery Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context, initialDate: _expectedDeliveryDate,
                              firstDate: _closingDate, lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _expectedDeliveryDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5)), color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping, color: Color(0xFF2E7D32), size: 20),
                                const SizedBox(width: 12),
                                Text('${_expectedDeliveryDate.day}/${_expectedDeliveryDate.month}/${_expectedDeliveryDate.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTender,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PUBLISH TENDER',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers for form fields
  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (val) =>
              val == null || val.isEmpty ? 'Required field' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2E7D32), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2E7D32), width: 2)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// THE "REVIEW BIDS" WIDGET
// ==========================================
class ReviewBidsView extends StatefulWidget {
  const ReviewBidsView({super.key});

  @override
  State<ReviewBidsView> createState() => _ReviewBidsViewState();
}

class _ReviewBidsViewState extends State<ReviewBidsView> {
  bool _isLoadingBids = true;
  List<Map<String, dynamic>> _tenders = [];
  Map<String, dynamic>?
      _selectedTender; // If null, show list of tenders. If set, show bids.
  List<Map<String, dynamic>> _currentBids = [];
  String _schoolName = '';

  @override
  void initState() {
    super.initState();
    _fetchTenders(); // This tells the screen to actually grab the data!
  }

  // fetch all the active tenders for this school
  Future<void> _fetchTenders() async {
    setState(() {
      _isLoadingBids = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user!.id)
          .single();
      _schoolName = profile['full_name'] ?? 'Unknown Institution';

      final response = await supabase
          .from('tenders')
          .select('*, bids(id)')
          .eq('institution_name', _schoolName)
          .eq('status', 'open') // Only show open tenders
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tenders = List<Map<String, dynamic>>.from(response);
          _isLoadingBids = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenders for bids: $e');
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  // fetch specific bids for a clicked tender
  Future<void> _FetchBidsForTender(Map<String, dynamic> tender) async {
    setState(() {
      _selectedTender = tender;
      _isLoadingBids = true;
    });

    try {
      final supabase = Supabase.instance.client;
      // We fetch the bids AND join the farmer's profile data to get their name
      final response = await supabase
          .from('bids')
          .select('*, profiles:farmer_id(*)')
          .eq('tender_id', tender['id'])
          .order('bid_amount', ascending: true); // Show cheapest bids first!
      if (mounted) {
        setState(() {
          _currentBids = List<Map<String, dynamic>>.from(response);
          _isLoadingBids = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bids: $e');
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  // accept the winning bid
  Future<void> _acceptBid(Map<String, dynamic> winningBid) async {
    setState(() => _isLoadingBids = true);
    try {
      final supabase = Supabase.instance.client;
      final tenderId = _selectedTender!['id'];
      final winnerId = winningBid['farmer_id'];

      // A. Mark this specific bid as 'accepted'
      await supabase
          .from('bids')
          .update({'status': 'won'}).eq('id', winningBid['id']);

      // B. Mark all other bids for this tender as 'rejected'
      await supabase
          .from('bids')
          .update({'status': 'lost'})
          .eq('tender_id', tenderId)
          .neq('id', winningBid['id']);

      // C. Close the Tender so no one else can bid
      await supabase
          .from('tenders')
          .update({'status': 'closed'}).eq('id', tenderId);

      // D. Send a Notification to the winning Farmer!
      await supabase.from('notifications').insert({
        'farmer_id': winnerId,
        'title': 'Tender Won! 🎉',
        'message':
            '$_schoolName accepted your bid of KES ${winningBid['bid_amount']} for ${_selectedTender!['crop_name']}. Please check your orders.',
        'type': 'won'
      });

      // E. FETCH ALL LOSING BIDS AND NOTIFY THEM
      final losingBids = await supabase
          .from('bids')
          .select('farmer_id')
          .eq('tender_id', tenderId)
          .neq('farmer_id', winnerId);

      for (var loser in losingBids) {
        await supabase.from('notifications').insert({
          'farmer_id': loser['farmer_id'],
          'title': 'Tender Update',
          'message':
              'Thank you for bidding. Unfortunately, another offer was selected for ${_selectedTender!['crop_name']}. Keep bidding!',
          'type': 'info' // Creates a grey/blue notification instead of green
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bid Accepted! The farmer has been notified.'),
              backgroundColor: Color(0xFF2E7D32)),
        );
        // Go back to the main list
        setState(() {
          _selectedTender = null;
          _currentBids = [];
        });
        _fetchTenders(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error accepting bid: $e');
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBids) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    // If a tender is selected, show its bids. Otherwise, show the list of tenders.
    if (_selectedTender != null) {
      return _buildBidsList();
    } else {
      return _buildTendersList();
    }
  }

  // --- VIEW 1: SELECT A TENDER ---
  Widget _buildTendersList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select a Tender to Review',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Click "View Bids" to see offers from local farmers.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          if (_tenders.isEmpty)
            const Center(
                child: Text('No open tenders available to review.',
                    style: TextStyle(color: Colors.grey)))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: DataTable(
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54),
                columns: const [
                  DataColumn(label: Text('Produce')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Total Bids')),
                  DataColumn(label: Text('Action')),
                ],
                rows: _tenders.map((tender) {
                  final bidsCount = (tender['bids'] as List?)?.length ?? 0;
                  return DataRow(
                    cells: [
                      DataCell(Text(tender['crop_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          '${tender['quantity']} ${tender['unit'] ?? ''}')),
                      DataCell(Text('$bidsCount offers',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold))),
                      DataCell(
                        ElevatedButton(
                          onPressed: bidsCount > 0
                              ? () => _FetchBidsForTender(tender)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bidsCount > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                            foregroundColor: bidsCount > 0
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                          child: const Text('View Bids'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- VIEW 2: REVIEW SPECIFIC BIDS ---
// --- VIEW 2: REVIEW SPECIFIC BIDS ---
  Widget _buildBidsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => setState(() => _selectedTender = null),
              ),
              const SizedBox(width: 8),
              Text('Reviewing bids for: ${_selectedTender!['crop_name']}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          if (_currentBids.isEmpty)
            const Center(
                child: Text('No bids have been placed yet.',
                    style: TextStyle(color: Colors.grey)))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: DataTable(
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54),
                columns: const [
                  DataColumn(label: Text('Supplier')),
                  DataColumn(label: Text('Bid Date')), // 🔥 NEW
                  DataColumn(label: Text('Offer (KES)')),
                  DataColumn(label: Text('Compliance')), // 🔥 NEW
                  DataColumn(label: Text('Action')),
                ],
                rows: _currentBids.map((bid) {
                  final farmer = bid['profiles'] ?? {};
                  final farmerName = farmer['full_name'] ?? 'Unknown Farmer';

                  // Format the bid date
                  final bidDate = bid['created_at'] != null
                      ? DateTime.parse(bid['created_at'])
                          .toString()
                          .substring(0, 16)
                      : 'Unknown Date';

                  return DataRow(
                    cells: [
                      // 🔥 FIX: Added constraints and Flexible to prevent text overflow!
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFE8F5E9),
                                  child: Icon(Icons.person,
                                      size: 14, color: Color(0xFF2E7D32))),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  farmerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow
                                      .ellipsis, // Adds "..." if name is too long
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(bidDate,
                          style: const TextStyle(color: Colors.grey))),
                      DataCell(Text('KES ${bid['bid_amount']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold))),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _showFarmerKYCDialog(farmer),
                          icon: const Icon(Icons.verified_user,
                              size: 16, color: Colors.blue),
                          label: const Text('View Profile',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAcceptConfirmation(bid, farmerName),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Award Contract'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

// --- 🔥 THE UPGRADED KYC VERIFICATION DIALOG ---
  void _showFarmerKYCDialog(Map<String, dynamic> farmer) {
    // Pull the document URLs
    final kraPinUrl = farmer['kra_certificate_url'];
    final tccUrl = farmer['tcc_url'];

    // Pull the text details
    final location = farmer['home_county'] ??
        farmer['farm_location'] ??
        'Pending Verification';
    final nationalId =
        farmer['national_id'] ?? 'Not Provided'; // 🔥 Grab the ID string!

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Supplier Verification Dossier',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(height: 30),

              // 🔥 MOVED THE ID TO THE TEXT DETAILS SECTION
              _buildKYCRow(Icons.person, 'Full Legal Name',
                  farmer['full_name'] ?? 'N/A'),
              _buildKYCRow(Icons.badge, 'National ID No.',
                  nationalId), // Looks great right here!
              _buildKYCRow(Icons.phone, 'Registered Phone',
                  farmer['phone_number']?.toString() ?? 'N/A'),
              _buildKYCRow(Icons.location_on, 'Location / County', location),

              const SizedBox(height: 24),
              const Text('Statutory Documents (PPADA Compliant)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),

              // 🔥 ONLY ACTUAL FILES GO IN THE VIEWER NOW
              _buildDocCheck('KRA PIN Certificate', kraPinUrl != null,
                  () => _showDocumentViewer('KRA PIN Certificate', kraPinUrl)),
              _buildDocCheck(
                  'Tax Compliance Certificate (TCC)',
                  tccUrl != null,
                  () => _showDocumentViewer(
                      'Tax Compliance Certificate', tccUrl)),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87),
                  child: const Text('Close Dossier'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 🔥 THE REAL SECURE DOCUMENT VIEWER ---
  void _showDocumentViewer(String documentTitle, String? documentUrl) {
    // Safety check: Web can only load http/https URLs, not local phone file:/// paths
    bool isValidUrl = documentUrl != null && documentUrl.startsWith('http');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 600,
          height: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Viewing: $documentTitle',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isValidUrl
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            documentUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF2E7D32)));
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Text(
                                  'Error loading image.\nMake sure your Supabase Bucket is public.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    color: Colors.grey, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  documentUrl != null && documentUrl.isNotEmpty
                                      ? 'Cannot load image on Web.\n\nThe database has a local phone path instead of a cloud link:\n\n$documentUrl'
                                      : 'No document link provided.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.grey, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download Copy'))
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the KYC Dialog
  Widget _buildKYCRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🔥 UPGRADED: Helper for Document Checklist
  Widget _buildDocCheck(
      String docName, bool isVerified, VoidCallback onViewDocument) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(docName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            if (isVerified)
              TextButton.icon(
                onPressed: onViewDocument,
                icon: const Icon(Icons.visibility,
                    size: 16, color: Color(0xFF2E7D32)),
                label: const Text('View Document',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.green.shade200))),
              )
            else
              Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pending',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              )
          ],
        ),
      ),
    );
  }

// --- CONFIRMATION DIALOG ---
  void _showAcceptConfirmation(Map<String, dynamic> bid, String farmerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Acceptance'),
        content: Text(
            'Are you sure you want to accept the bid from $farmerName for KES ${bid['bid_amount']}? This will close the tender and reject all other bids.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _acceptBid(bid); // Trigger the database logic
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Yes, Accept Bid',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// THE "ORDER HISTORY" WIDGET
// ==========================================
// ==========================================
// THE "ORDER HISTORY" WIDGET (WITH B2B DELIVERY CONFIRMATION)
// ==========================================
class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _closedTenders = [];

  String _schoolName = 'Unknown Institution';

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user!.id)
          .single();

      _schoolName = profile['full_name'] ?? 'Unknown Institution';

      // Fetch closed tenders and pull in the bids + farmer profiles
      final response = await supabase
          .from('tenders')
          .select('*, bids(*, profiles(*))')
          .eq('institution_name', _schoolName)
          .eq('status', 'closed') // ONLY get the finished ones!
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _closedTenders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 🔥 NEW B2B FUNCTION: School Confirms Receipt ---
  Future<void> _confirmDelivery(String bidId, String farmerId) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Update Bid Status
      await supabase
          .from('bids')
          .update({'status': 'delivered'}).eq('id', bidId);

      // 2. Send a Notification to the Farmer!
      await supabase.from('notifications').insert({
        'farmer_id': farmerId,
        'title': 'Delivery Verified ✅',
        'message':
            '$_schoolName has confirmed receipt of your goods. Payment processing initiated.',
        'type': 'payment' // Use payment icon styling
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Goods Receipt Confirmed! Farmer notified.'),
              backgroundColor: Color(0xFF2E7D32)),
        );
        _fetchOrderHistory(); // Refresh the table
      }
    } catch (e) {
      debugPrint('Error confirming delivery: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: const Color(0xFF2E7D32)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order History & Deliveries',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
              'Track your accepted tenders, generate LPOs, and confirm goods receipt.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          if (_closedTenders.isEmpty)
            const Center(
                child: Text('You have no completed orders yet.',
                    style: TextStyle(color: Colors.grey)))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: DataTable(
                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54),
                  columns: const [
                    DataColumn(label: Text('Produce')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Winning Farmer')),
                    DataColumn(label: Text('Agreed Price')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: _closedTenders.map((tender) {
                    final bids = tender['bids'] as List<dynamic>? ?? [];
                    Map<String, dynamic>? winningBid;

                    for (var currentBid in bids) {
                      // Grab ANY successful state to show in this table
                      if (currentBid['status'] == 'won' ||
                          currentBid['status'] == 'accepted' ||
                          currentBid['status'] == 'delivered') {
                        winningBid = currentBid as Map<String, dynamic>;
                        break;
                      }
                    }

                    String farmerName = 'Unknown';
                    String price = 'N/A';
                    String bidStatus = 'unknown';
                    String bidId = '';
                    String farmerId = '';
                    String phone = 'N/A';

                    if (winningBid != null) {
                      price = 'KES ${winningBid['bid_amount']}';
                      bidStatus = winningBid['status'] ?? 'unknown';
                      bidId = winningBid['id'];
                      farmerId = winningBid['farmer_id'];

                      if (winningBid['profiles'] != null) {
                        farmerName = winningBid['profiles']['full_name'] ??
                            'Unknown Farmer';
                        phone = winningBid['profiles']['phone_number']
                                ?.toString() ??
                            'N/A';
                      }
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(tender['crop_name'] ?? 'Unknown',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(
                            '${tender['quantity']} ${tender['unit'] ?? ''}')),
                        DataCell(Row(
                          children: [
                            const Icon(Icons.verified_user,
                                color: Color(0xFF2E7D32), size: 16),
                            const SizedBox(width: 8),
                            Text(farmerName),
                          ],
                        )),
                        DataCell(Text(price,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),

                        // 🔥 THE NEW ACTION COLUMN
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. PDF GENERATOR
                           // 1. PDF GENERATOR
                              IconButton(
                                tooltip: 'Print LPO',
                                onPressed: () {
                                  // 🔥 GRAB THE REAL DATE FROM DB
                                  final rawDate = tender['expected_delivery_date'];
                                  final deliveryDate = rawDate != null ? DateTime.parse(rawDate) : DateTime.now().add(const Duration(days: 3));
                                  final formattedDate = "${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}";

                                  LpoGenerator.generateAndPrintLPO(
                                    schoolName: _schoolName, farmerName: farmerName, farmerPhone: phone,
                                    cropName: tender['crop_name'] ?? 'Unknown',
                                    quantity: '${tender['quantity']} ${tender['unit'] ?? ''}',
                                    price: price.replaceAll('KES ', ''), tenderId: tender['id'].toString(),
                                    deliveryDate: 'Before 9:00 AM on $formattedDate', // 🔥 PASS IT IN!
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                              ),
                              const SizedBox(width: 8),

                              // 2. DYNAMIC DELIVERY BUTTON
                              if (bidStatus == 'won' || bidStatus == 'accepted')
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _confirmDelivery(bidId, farmerId),
                                  icon: const Icon(Icons.check_box, size: 16),
                                  label: const Text('Confirm Receipt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else if (bidStatus == 'delivered')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Goods Received',
                                      style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                )
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList()),
            ),
        ],
      ),
    );
  }
}
