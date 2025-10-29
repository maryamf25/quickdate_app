import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../utils/user_details.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'social_login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFDFBFC),
              Color(0xFFFDF8FA),
              Color(0xFFFEEEF7),
              Color(0xFFFDDDED),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 56),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Welcome to ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "QuickDate",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBF01FD),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Login to continue", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                _buildInputBox(
                  emailController,
                  "Email",
                  Icons.alternate_email_outlined,
                ),
                const SizedBox(height: 15),
                _buildPasswordBox(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                    child: const Text(
                      "Forgot your password?",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 15),
                _buildSocialLoginSection(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Not a member? ",
                      style: TextStyle(fontSize: 14),
                    ),
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF92FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1F3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF41BD)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFFF41BD)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: passwordController,
              obscureText: !passwordVisible,
              decoration: const InputDecoration(
                hintText: "Password",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => passwordVisible = !passwordVisible),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE40997), Color(0xFF8926F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child:
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
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
                "Continue",
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
          children: [_buildFacebookButton(), _buildGoogleButton()],
        ),
      ],
    );
  }

  Widget _buildFacebookButton() {
    return SizedBox(
      height: 50,
      width: 50,
      child: GestureDetector(
        onTap: _loginWithFacebook,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: GestureDetector(
        onTap: _loginWithGoogle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  "Google",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    String username = emailController.text.trim();
    String password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showDialog("Error", "Please enter your email and password.");
      return;
    }
    setState(() => isLoading = true);
    try {
      var body = {
        'username': username,
        'password': password,
        'mobile_device_id': UserDetails.deviceId,
      };
      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        await _handleLoginSuccess(data['data'], username);
      } else {
        _showDialog(
          "Login Failed",
          data['message'] ?? 'Invalid login credentials',
        );
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect to server: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    final result = await SocialLoginService.signInWithGoogle();
    setState(() => isLoading = false);
    if (result != null)
      await _handleLoginSuccess(result, result['email'] ?? '');
    else
      _showDialog("Error", "Google login failed or canceled.");
  }

  Future<void> _loginWithFacebook() async {
    setState(() => isLoading = true);
    final result = await SocialLoginService.signInWithFacebook();
    setState(() => isLoading = false);
    if (result != null)
      await _handleLoginSuccess(result, result['email'] ?? '');
    else
      _showDialog("Error", "Facebook login failed or canceled.");
  }

  Future<void> _handleLoginSuccess(
    Map<String, dynamic> userData,
    String username,
  ) async {
    UserDetails.accessToken = userData['access_token'] ?? '';
    UserDetails.userId = userData['user_id'] ?? 0;

    // ✅ Read user_info safely
    Map<String, dynamic>? userInfoFromResponse = Map<String, dynamic>.from(
      userData['user_info'] ?? {},
    );
    print(userInfoFromResponse);
    // ✅ Assign all values safely from user_info
    UserDetails.username = userInfoFromResponse['username'] ?? username;
    UserDetails.fullName =
        '${userInfoFromResponse['first_name'] ?? ''} ${userInfoFromResponse['last_name'] ?? ''}';
    UserDetails.email = userInfoFromResponse['email'] ?? ''; // ✅ FIXED HERE
    UserDetails.country_txt = userInfoFromResponse['country'] ?? '';
    UserDetails.phone = userInfoFromResponse['phone_number'] ?? '';
    UserDetails.avatar = userInfoFromResponse['avater'] ?? '';
    UserDetails.cover = userInfoFromResponse['cover'] ?? '';
    UserDetails.firstName = userInfoFromResponse['first_name'] ?? '';
    UserDetails.lastName = userInfoFromResponse['last_name'] ?? '';
    UserDetails.hobby = userInfoFromResponse['hobby'] ?? '';
    UserDetails.music = userInfoFromResponse['music'] ?? '';
    UserDetails.movie = userInfoFromResponse['movie'] ?? '';
    UserDetails.city = userInfoFromResponse['city'] ?? '';
    UserDetails.country_txt = userInfoFromResponse['country'] ?? '';
    UserDetails.birthday = userInfoFromResponse['birthday'] ?? '';
    UserDetails.genderTxt = userInfoFromResponse['gender_txt'] ?? userInfoFromResponse['gender'] ?? '';
    UserDetails.relationship = userInfoFromResponse['relationship_txt'] ?? '';
    UserDetails.workStatus = userInfoFromResponse['work_status_txt'] ?? '';
    UserDetails.education = userInfoFromResponse['education_txt'] ?? '';
    UserDetails.genderTxt = userInfoFromResponse['gender_txt'] ?? userInfoFromResponse['gender'] ?? '';

    // ✅ FIX FOR ID FIELDS: Use the ID fields from the response
    // If the field is null, default to '0' or '', as the ID lookup expects a string ID.
    UserDetails.relationship = userInfoFromResponse['relationship']?.toString() ?? '';
    UserDetails.workStatus = userInfoFromResponse['work_status']?.toString() ?? '';
    UserDetails.education = userInfoFromResponse['education']?.toString() ?? '';
    UserDetails.ethnicity = userInfoFromResponse['ethnicity']?.toString() ?? '';
    UserDetails.body = userInfoFromResponse['body']?.toString() ?? '';
    UserDetails.children = userInfoFromResponse['children']?.toString() ?? '';
    UserDetails.pets = userInfoFromResponse['pets']?.toString() ?? '';
    // You need to add all other ID-based fields here (religion, smoke, drink, travel, lookingFor)
    UserDetails.religion = userInfoFromResponse['religion']?.toString() ?? ''; // 🎯 Add this line!
    UserDetails.smoke = userInfoFromResponse['smoke']?.toString() ?? '';
    UserDetails.drink = userInfoFromResponse['drink']?.toString() ?? '';
    UserDetails.travel = userInfoFromResponse['travel']?.toString() ?? '';
    UserDetails.lookingFor = userInfoFromResponse['show_me_to']?.toString() ?? '';
    UserDetails.gender = userInfoFromResponse['gender']?.toString() ?? ''; // This is the numerical ID or text (like 'Female')
    UserDetails.genderTxt = userInfoFromResponse['gender_txt'] ?? ''; // This is often empty/not used by API

    // ✅ FIX: Read About
    UserDetails.about = userInfoFromResponse['about'] ?? '';

    // ✅ FIX: Read Favorites/Interests
    UserDetails.music = userInfoFromResponse['music'] ?? '';
    UserDetails.dish = userInfoFromResponse['dish'] ?? '';
    UserDetails.song = userInfoFromResponse['song'] ?? '';
    UserDetails.hobby = userInfoFromResponse['hobby'] ?? '';
    UserDetails.movie = userInfoFromResponse['movie'] ?? '';

    // ✅ FIX: Read Social Links
    UserDetails.facebook = userInfoFromResponse['facebook'] ?? '';
    UserDetails.google = userInfoFromResponse['google'] ?? ''; // It's still empty in the box, but we should map it
    UserDetails.twitter = userInfoFromResponse['twitter'] ?? '';
    UserDetails.linkedin = userInfoFromResponse['linkedin'] ?? '';
    UserDetails.instagram = userInfoFromResponse['instagram'] ?? '';
    // snapchat/tiktok (mapped to okru/mailru in EditProfileScreen)
    UserDetails.okru = userInfoFromResponse['okru'] ?? '';
    UserDetails.mailru = userInfoFromResponse['mailru'] ?? '';
    UserDetails.website = userInfoFromResponse['website'] ?? '';
    UserDetails.mediaFiles = (userInfoFromResponse['mediafiles'] as List?)

        ?.map((e) => MediaFile.fromJson(e))
        .toList() ?? [];

    // ✅ Save full userData (including user_info) to Hive
    var box = await Hive.openBox('loginBox');
    await box.put('currentUser', userData);

    print('--------------------------');
    print('✅ CURRENT USER LOGGED IN:');
    print('User ID: ${UserDetails.userId}');
    print('Username: ${UserDetails.username}');
    print('Email: ${UserDetails.email}'); // ✅ Check this now
    print('Country: ${UserDetails.country_txt}');
    print('Phone: ${UserDetails.phone}');
    print('--------------------------');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }
}
