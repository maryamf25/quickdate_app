import 'package:flutter/material.dart';
import 'api_service.dart';

class ProfileVisitsPage extends StatefulWidget {
  final String accessToken;
  const ProfileVisitsPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<ProfileVisitsPage> createState() => _ProfileVisitsPageState();
}

class _ProfileVisitsPageState extends State<ProfileVisitsPage> {
  List<Map<String, dynamic>> visits = [];
  bool isLoading = true;

  // Dummy fallback visits
  final List<Map<String, dynamic>> dummyVisits = [
    {
      'username': 'Ayesha Khan',
      'location': 'Lahore, Pakistan',
      'avater': 'https://randomuser.me/api/portraits/women/44.jpg',
      'created_at': '2 hours ago',
    },
    {
      'username': 'Ali Raza',
      'location': 'Karachi, Pakistan',
      'avater': 'https://randomuser.me/api/portraits/men/33.jpg',
      'created_at': '1 day ago',
    },
    {
      'username': 'Fatima Ahmed',
      'location': 'Islamabad, Pakistan',
      'avater': 'https://randomuser.me/api/portraits/women/21.jpg',
      'created_at': '3 days ago',
    },
    {
      'username': 'Usman Malik',
      'location': 'Faisalabad, Pakistan',
      'avater': 'https://randomuser.me/api/portraits/men/72.jpg',
      'created_at': '5 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    try {
      final result = await ApiService.getProfileVisits(
        accessToken: widget.accessToken,
        limit: 10,
        offset: 0,
      );

      setState(() {
        // Use API data if available, otherwise fallback to dummy data
        visits = result.isNotEmpty ? result : dummyVisits;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        visits = dummyVisits; // fallback on error
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading visits. Showing dummy data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Visits')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : visits.isEmpty
          ? const Center(child: Text('No visits yet.'))
          : ListView.builder(
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final v = visits[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(v['avater'] ?? ''),
            ),
            title: Text(v['username'] ?? 'Unknown'),
            subtitle: Text(v['location'] ?? 'Unknown location'),
            trailing: Text(
              v['created_at'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
