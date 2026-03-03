import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../school/lpo_generator.dart'; 

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('notifications')
          .select()
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('farmer_id', user.id)
            .eq('is_read', false);

        setState(() {
          for (var notif in _notifications) {
            notif['is_read'] = true;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All caught up!'), backgroundColor: Color(0xFF2E7D32)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating notifications: $e');
    }
  }

  // 🔥 NEW: Permanently saves the "read" status to the database
  Future<void> _markSingleAsRead(String notificationId, int index) async {
    // Prevent unnecessary database calls if it's already read
    if (_notifications[index]['is_read'] == true) return;

    // 1. Instantly update the UI so it feels fast
    setState(() {
      _notifications[index]['is_read'] = true;
    });

    // 2. Secretly tell Supabase in the background to make it permanent!
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error updating database: $e');
    }
  }



  // FETCH DATA AND GENERATE LPO DIRECTLY FROM NOTIFICATION 🔥
  Future<void> _openLpoFromNotification(BuildContext context) async {
    // 1. Show a quick loading spinner so the user knows it's working
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
    );

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // 2. Fetch the Farmer's Profile Data
      final profileData = await supabase.from('profiles').select('full_name, phone_number').eq('id', user!.id).maybeSingle();
      
      // 3. Fetch their most recently won bid (since the basic notification doesn't store the tender ID)
      final bidData = await supabase
          .from('bids')
          .select('bid_amount, tenders(id, institution_name, quantity, crop_name, unit)')
          .eq('farmer_id', user.id)
          .inFilter('status', ['won', 'accepted']) // Catches both statuses!
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // 4. Close the loading spinner
      if (mounted) Navigator.pop(context); 

      if (bidData != null && profileData != null) {
        final tender = bidData['tenders'];
        
        // 5. BOOM! Generate the PDF!
        LpoGenerator.generateAndPrintLPO(
          schoolName: tender['institution_name'] ?? 'Unknown School',
          farmerName: profileData['full_name'] ?? 'Authorized Supplier',
          farmerPhone: profileData['phone_number']?.toString() ?? 'N/A',
          cropName: tender['crop_name'] ?? 'Produce',
          quantity: '${tender['quantity']} ${tender['unit'] ?? ''}',
          price: bidData['bid_amount'].toString(),
          tenderId: tender['id'].toString(),
        );
      } else {
        throw Exception('Could not find contract details.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Ensure spinner closes on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating LPO: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getTimeAgo(String dateString) {
    DateTime date = DateTime.parse(dateString);
    Duration diff = DateTime.now().difference(date);

    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  Map<String, dynamic> _getThemeForType(String type) {
    switch (type) {
      case 'won':
      case 'accepted': // Added 'accepted' just in case your database uses that word!
        return {'icon': Icons.emoji_events, 'iconColor': Colors.orange, 'bgColor': Colors.orange.shade50};
      case 'payment':
        return {'icon': Icons.payments, 'iconColor': const Color(0xFF2E7D32), 'bgColor': const Color(0xFFE8F5E9)};
      case 'alert':
        return {'icon': Icons.campaign, 'iconColor': Colors.blue, 'bgColor': Colors.blue.shade50};
      default:
        return {'icon': Icons.info_outline, 'iconColor': Colors.grey.shade600, 'bgColor': Colors.grey.shade200};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No new notifications', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final String type = notif['type'] ?? 'info';
                    final theme = _getThemeForType(type);
                    
                    return _buildNotificationCard(
                      icon: theme['icon'],
                      iconColor: theme['iconColor'],
                      bgColor: theme['bgColor'],
                      title: notif['title'] ?? 'Notice',
                      message: notif['message'] ?? '',
                      time: _getTimeAgo(notif['created_at']),
                      isUnread: !(notif['is_read'] as bool),
                      // 🔥 ADDED TAP LOGIC HERE 🔥
                      onTap: () {
                       // 1. Permanently mark it as read in Supabase!
                        _markSingleAsRead(notif['id'], index);

                        // If it's a winning notification, generate the LPO!
                        if (type == 'won' || type == 'accepted') {
                          _openLpoFromNotification(context);
                        }
                      },
                    );
                  },
                ),
    );
  }

  // --- UPGRADED CARD TO BE CLICKABLE ---
  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required VoidCallback onTap, // Added onTap
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell( // Makes it clickable with a nice ripple effect
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFF2E7D32).withOpacity(0.3) : Colors.grey.shade200,
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: isUnread
                ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                    
                    // Add a tiny hint text so the user knows they can click it!
                    if (title.toLowerCase().contains('won') || title.toLowerCase().contains('accepted'))
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Row(
                           children: const [
                             Icon(Icons.touch_app, size: 12, color: Color(0xFF2E7D32)),
                             SizedBox(width: 4),
                             Text('Tap to view official LPO', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                           ],
                         ),
                       )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}