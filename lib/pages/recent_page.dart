import 'package:flutter/material.dart';

class RecentPage extends StatefulWidget {
  const RecentPage({super.key});

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  // Mock data for recent calls
  final List<Map<String, dynamic>> recentCalls = [
    {
      'name': 'John Doe',
      'time': '2 minutes ago',
      'type': 'outgoing',
      'avatar': '👨',
    },
    {
      'name': 'Jane Smith',
      'time': '15 minutes ago',
      'type': 'incoming',
      'avatar': '👩',
    },
    {
      'name': 'Mike Johnson',
      'time': '1 hour ago',
      'type': 'missed',
      'avatar': '👨',
    },
    {
      'name': 'Sarah Wilson',
      'time': '2 hours ago',
      'type': 'outgoing',
      'avatar': '👩',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: recentCalls.length,
        itemBuilder: (context, index) {
          final call = recentCalls[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                call['avatar'],
                style: const TextStyle(fontSize: 20, fontFamily: 'nothing'),
              ),
            ),
            title: Text(
              call['name'],
              style: const TextStyle(
                fontFamily: 'nothing',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              call['time'],
              style: TextStyle(
                fontFamily: 'nothing',
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              _getCallTypeIcon(call['type']),
              color: _getCallTypeColor(call['type']),
            ),
            onTap: () {
              // Handle call tap
            },
          );
        },
      ),
    );
  }

  IconData _getCallTypeIcon(String type) {
    switch (type) {
      case 'outgoing':
        return Icons.call_made;
      case 'incoming':
        return Icons.call_received;
      case 'missed':
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _getCallTypeColor(String type) {
    switch (type) {
      case 'outgoing':
        return Colors.green;
      case 'incoming':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
