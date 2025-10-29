import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hive/hive.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  String? selectedCountry;

  @override
  void initState() {
    super.initState();

    // Pre-fill current user details
    usernameController.text = UserDetails.username;
    emailController.text = UserDetails.email;
    selectedCountry = UserDetails.country_txt ?? '';
    countryController.text = selectedCountry ?? '';
    phoneController.text = UserDetails.phone ?? '';
  }

  Future<void> _handleProfileUpdateSuccess({
    required String username,
    required String country,
    required String phone,
  }) async {
    // 1️⃣ Update memory
    UserDetails.username = username;
    UserDetails.country_txt = country;
    UserDetails.phone = phone;

    // 2️⃣ Update UI controllers
    usernameController.text = UserDetails.username;
    countryController.text = UserDetails.country_txt;
    phoneController.text = UserDetails.phone;

    // 3️⃣ Save to Hive
    var box = await Hive.openBox('loginBox');
    Map<String, dynamic> currentUser = Map<String, dynamic>.from(
      box.get('currentUser') ?? {},
    );

    currentUser['user_info'] ??= {};
    currentUser['user_info']['username'] = username;
    currentUser['user_info']['country_txt'] = country;
    currentUser['user_info']['phone_number'] = phone;

    await box.put('currentUser', currentUser);

    print('✅ USER PROFILE UPDATED:');
    print('Username: ${UserDetails.username}');
    print('Country: ${UserDetails.country_txt}');
    print('Phone: ${UserDetails.phone}');
  }

  bool _validateInput(String username, String country, String phone) {
    if (username.isEmpty) {
      showError("Username cannot be empty.");
      return false;
    }

    if (country.isEmpty) {
      showError("Please select a country.");
      return false;
    }

    if (phone.isEmpty) {
      showError("Phone number cannot be empty.");
      return false;
    }

    // Phone number should be digits only, optional starting +
    final phoneRegEx = RegExp(r'^\+?\d{6,15}$');
    if (!phoneRegEx.hasMatch(phone)) {
      showError("Enter a valid phone number (6-15 digits, optional +).");
      return false;
    }

    return true;
  }

  Future<void> updateUserProfile() async {
    String newUsername = usernameController.text.trim();
    String newCountry = countryController.text.trim();
    String newPhone = phoneController.text.trim();

    if (!_validateInput(newUsername, newCountry, newPhone)) return;

    setState(() => isLoading = true);

    try {
      var body = {
        'access_token': UserDetails.accessToken,
        'username': newUsername, // <-- send username
        'country': newCountry,
        'phone_number': newPhone,
      };

      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/update_profile'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        await _handleProfileUpdateSuccess(
          username: newUsername,
          country: newCountry,
          phone: newPhone,
        );
        showSuccess("Profile updated successfully!");
      } else {
        showError(data['errors']?['error_text'] ?? "Update failed");
      }
    } catch (e) {
      showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Username
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),

            // Email (read-only)
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),

            // Country picker
            TextFormField(
              readOnly: true,
              controller: countryController,
              decoration: InputDecoration(
                labelText: "Country",
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: false,
                  onSelect: (Country country) {
                    setState(() {
                      selectedCountry = country.name;
                      countryController.text = country.name;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),

            // Phone
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            const SizedBox(height: 20),

            // Update button
            ElevatedButton(
              onPressed: isLoading ? null : updateUserProfile,
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
