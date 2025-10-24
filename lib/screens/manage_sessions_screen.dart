import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart'; // Contains UserDetails.accessToken etc.
import 'social_login_service.dart';

class ManageSessionsScreen extends StatefulWidget {
  const ManageSessionsScreen({super.key});

  @override
  State<ManageSessionsScreen> createState() => _ManageSessionsScreenState();
}

class _ManageSessionsScreenState extends State<ManageSessionsScreen> {
  List<dynamic> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/list_sessions');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': UserDetails.accessToken},
      );

      print('List Sessions Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          setState(() {
            sessions = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch sessions")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching sessions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  // Function to show the logout confirmation dialog
  // Function to show the logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Text(
            "Warning",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to log out from this device?",
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "CANCEL",
                style: TextStyle(
                    color: Colors.pink.shade400, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(
                    color: Colors.pink.shade400, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteSession(sessionId); // Call the API
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _deleteSession(String sessionId) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/delete_session');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'sid': sessionId,
        },
      );

      print('Delete Session Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Session deleted.")),
          );

          // Remove deleted session from the local list instantly
          setState(() {
            sessions.removeWhere((session) => session['id'].toString() == sessionId);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${data['message'] ?? 'Unknown error'}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error deleting session: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for app bar
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Manage Sessions",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // Align title to the left
      ),
      backgroundColor: Colors.white, // Ensure scaffold background is white
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
          ? const Center(child: Text("No active sessions found."))
          : ListView.separated(
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const Divider(height: 1), // Thin separator
        itemBuilder: (context, index) {
          final session = sessions[index];
          // Use 'os' for the display, default to 'Unknown'
          final String osDisplayName = session['os'] ?? 'Unknown';
          final String browserDisplayName = session['name'] ?? 'web'; // Assuming 'name' is the browser type
          final String timeText = session['time_text'] ?? 'Unknown time'; // time_text from API
          final String sessionId = session['id'].toString(); // Get session ID for termination

          return InkWell(
            onTap: () {
              // TODO: Handle tap if needed
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.pink.shade100, // Light pink background
                    child: Text(
                      osDisplayName.isNotEmpty ? osDisplayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          osDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Browser : $browserDisplayName",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Last seen : $timeText",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.pink.shade400, size: 28), // Larger, matching pink
                    onPressed: () {
                      _showLogoutConfirmationDialog(context, sessionId); // Show the dialog
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}