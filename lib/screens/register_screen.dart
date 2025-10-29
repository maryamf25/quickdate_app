import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/user_details.dart';
import 'home_screen.dart';
import 'verification_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'social_login_service.dart';
import 'LoginActivity.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String? selectedGenderId;
  List<Map<String, String>> genderList = [];
  bool isLoading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    genderList = [
      {'id': '1', 'name': 'Male'},
      {'id': '2', 'name': 'Female'},
      {'id': '3', 'name': 'Other'},
    ];
  }

  Future<void> registerUser() async {
    String fullName = fullNameController.text.trim();
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String? gender = selectedGenderId;
    String birthday = birthdayController.text;

    if ([
          fullName,
          username,
          email,
          password,
          confirmPassword,
          birthday,
        ].any((e) => e.isEmpty) ||
        gender == null) {
      showError("Please fill all fields");
      return;
    }

    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      showError("Invalid email format");
      return;
    }

    if (password != confirmPassword) {
      showError("Passwords do not match");
      return;
    }

    if (UserDetails.deviceId.isEmpty) {
      UserDetails.deviceId =
          "device_" + DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Format birthday YYYY-MM-DD
    List<String> parts = birthday.split('-');
    if (parts.length == 3) {
      birthday =
          "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
    }

    setState(() => isLoading = true);

    try {
      var names = fullName.split(' ');
      var firstName = names.first;
      var lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      var body = {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
        'gender': gender,
        'birthday': birthday,
        'about': "Hello from QuickDate",
        'country_id': "US",
        'language': "en",
        'phone_number': "+10000000000",
        'device_id': UserDetails.deviceId,
        'src': "site",
      };

      final response = await http.post(
        Uri.parse(
          'https://backend.staralign.me/endpoint/v1/models/users/register',
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success_type'] == 'registered') {
          var box = Hive.box('loginBox');
          await box.put('currentUser', data['data']);

          UserDetails.accessToken = data['data']['access_token'] ?? '';
          UserDetails.userId = data['data']['user_id'] ?? 0;
          UserDetails.username = username;
          UserDetails.fullName = fullName;
          UserDetails.email = email;

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (data['success_type'] == 'confirm_account') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VerificationScreen(
                    email: email,
                    userId: data['data']['user_id'],
                  ),
            ),
          );
        } else {
          showError(data['message'] ?? "Unknown error occurred");
        }
      } else {
        showError(data['message'] ?? "Unknown error occurred");
      }
    } catch (e) {
      showError("Failed to connect: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signWithGoogle() async {
    setState(() => isLoading = true);
    final result = await SocialLoginService.signInWithGoogle();
    setState(() => isLoading = false);
    if (result != null)
      await _handleLoginSuccess(result, result['email'] ?? '');
    else
      showError("Google sign up failed or canceled.");
  }

  Future<void> _signWithFacebook() async {
    // Facebook sign-up functionality removed - button kept for UI only
    showError("Facebook sign-up will be available soon.");
  }

  Future<void> _handleLoginSuccess(
    Map<String, dynamic> userData,
    String email,
  ) async {
    UserDetails.accessToken = userData['access_token'] ?? '';
    UserDetails.userId = userData['user_id'] ?? 0;
    UserDetails.username =
        userData['username'] ??
        email; // Fallback to email if username not present
    UserDetails.fullName = userData['first_name'] ?? '';
    UserDetails.email = email;
    var box = Hive.box('loginBox');
    await box.put('currentUser', userData);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      if (now.year - picked.year < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be at least 18 years old")),
        );
      } else {
        birthdayController.text =
            "${picked.day}-${picked.month}-${picked.year}";
      }
    }
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String hint, {
    Widget? prefixIconChild,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3F3),
              shape: BoxShape.circle,
            ),
            child:
                prefixIconChild ??
                const Icon(
                  Icons.person_outline,
                  color: Color(0xFFFF0881),
                  size: 20,
                ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPasswordField(
    TextEditingController controller,
    String hint,
    bool visible,
    VoidCallback toggle,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFFFF0881),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !visible,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: toggle,
          ),
        ],
      ),
    );
  }

  Widget buildDropdownField(
      String hint,
      String? selectedId,
      List<Map<String, String>> items,
      ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3F3),
              shape: BoxShape.circle,
            ),
            // 👇 Changed this icon to show two people instead of one
            child: const Icon(
              Icons.people_alt_outlined,
              color: Color(0xFFFF0881),
              size: 20,
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedId,
              items: items
                  .map(
                    (g) => DropdownMenuItem(
                  value: g['id'],
                  child: Text(g['name']!),
                ),
              )
                  .toList(),
              onChanged: (val) => setState(() => selectedGenderId = val),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildBirthdayField(
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFFFF0881),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: "Birthday",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
              ),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade400)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "continue with",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade400)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildGoogleButton(),
            _buildFacebookButton(),
            _buildWoWonderButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _signWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // pill shape
            side: const BorderSide(color: Colors.grey, width: 0.6),
          ),
          elevation: 2,
          shadowColor: Colors.black12,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/Google_logo.png", // use the colorful G logo
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              "Google",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacebookButton() {
    return SizedBox(
      height: 50,
      width: 50,
      child: GestureDetector(
        onTap: _signWithFacebook,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.facebook,
            color: Color(0xFF1877F2),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildWoWonderButton() {
    return SizedBox(
      height: 50,
      width: 50,
      child: ElevatedButton(
        onPressed: () {
          // TODO: handle WoWonder login here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 2,
          shadowColor: Colors.black12,
        ),
        child: Image.asset(
          "assets/images/wowonder.png",
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            RichText(
              text: const TextSpan(
                text: "Welcome to ",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: "QuickDate",
                    style: TextStyle(color: Color(0xFFB602F5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text("Register to continue", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            buildTextField(fullNameController, "Full Name"),
            const SizedBox(height: 10),
            buildTextField(usernameController, "Username"),
            const SizedBox(height: 10),
            buildTextField(
              emailController,
              "Email",
              prefixIconChild: const Center(
                child: Text(
                  "@",
                  style: TextStyle(
                    color: Color(0xFFFF0881),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildPasswordField(
              passwordController,
              "Password",
              passwordVisible,
              () => setState(() => passwordVisible = !passwordVisible),
            ),
            const SizedBox(height: 10),
            buildPasswordField(
              confirmPasswordController,
              "Confirm Password",
              confirmPasswordVisible,
              () => setState(
                () => confirmPasswordVisible = !confirmPasswordVisible,
              ),
            ),
            const SizedBox(height: 10),
            buildDropdownField("Gender", selectedGenderId, genderList),
            const SizedBox(height: 10),
            buildBirthdayField(birthdayController, pickBirthday),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE40997),
                        Color(0xFFF20489),
                        Color(0xFFDC0C9F),
                        Color(0xFFCA12AF),
                        Color(0xFFBA16C1),
                        Color(0xFFAA1BCD),
                        Color(0xFF9921E0),
                        Color(0xFF8926F0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Create an Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildSocialLoginSection(),
            const SizedBox(height: 20),
            const SizedBox(height: 20),

// Terms of Service
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                text: "By registering you agree to our ",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: "Terms of Service",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

// Already have an account? Login now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  child: const Text(
                    "Login now",
                    style: TextStyle(
                      color: Color(0xFFFF0881), // same as your app icon color
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
