import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/notification.dart';

class NotificationIconBadge extends StatelessWidget {
  final Color iconColor; // 🔥 Add this line

  // 🔥 Update the constructor
  const NotificationIconBadge({Key? key, this.iconColor = Colors.black87})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Icon(Icons.notifications_outlined, color: iconColor);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id']).eq('farmer_id', user.id),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          final notifications = snapshot.data!;
          unreadCount =
              notifications.where((notif) => notif['is_read'] == false).length;
        }

        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            '$unreadCount',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          offset: const Offset(-4, 4),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: iconColor), // 🔥 Use the custom color here!
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        );
      },
    );
  }
}
