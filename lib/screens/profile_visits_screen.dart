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
        visits = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
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
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.visibility_off, size: 50, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No visits yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
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
