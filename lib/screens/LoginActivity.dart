import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'social_login_service.dart';
import '../services/session_manager.dart';

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
                const Text("Login to continue finding partner.", style: TextStyle(fontSize: 16)),
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
                      "Forgot password?",
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
        onPressed: _loginWithGoogle,
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
        onTap: _loginWithFacebook,
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
      UserDetails.password = passwordController.text.trim();

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
    // ----------------- Basic user info -----------------
    UserDetails.accessToken = userData['access_token'] ?? '';
    UserDetails.userId = userData['user_id'] ?? 0;
    UserDetails.password = passwordController.text.trim();

    // ----------------- Read user_info safely -----------------
    Map<String, dynamic> userInfo = Map<String, dynamic>.from(
      userData['user_info'] ?? {},
    );

    UserDetails.username = userInfo['username'] ?? username;
    UserDetails.fullName =
    '${userInfo['first_name'] ?? ''} ${userInfo['last_name'] ?? ''}';
    UserDetails.firstName = userInfo['first_name'] ?? '';
    UserDetails.lastName = userInfo['last_name'] ?? '';
    UserDetails.email = userInfo['email'] ?? '';
    UserDetails.phone = userInfo['phone_number'] ?? '';
    UserDetails.country_txt = userInfo['country'] ?? '';
    UserDetails.birthday = userInfo['birthday'] ?? '';
    UserDetails.gender = userInfo['gender']?.toString() ?? '';
    UserDetails.genderTxt = userInfo['gender_txt'] ?? userInfo['gender'] ?? '';
    UserDetails.relationship = userInfo['relationship']?.toString() ?? '';
    UserDetails.workStatus = userInfo['work_status']?.toString() ?? '';
    UserDetails.education = userInfo['education']?.toString() ?? '';
    UserDetails.ethnicity = userInfo['ethnicity']?.toString() ?? '';
    UserDetails.body = userInfo['body']?.toString() ?? '';
    UserDetails.children = userInfo['children']?.toString() ?? '';
    UserDetails.pets = userInfo['pets']?.toString() ?? '';
    UserDetails.religion = userInfo['religion']?.toString() ?? '';
    UserDetails.smoke = userInfo['smoke']?.toString() ?? '';
    UserDetails.drink = userInfo['drink']?.toString() ?? '';
    UserDetails.travel = userInfo['travel']?.toString() ?? '';
    UserDetails.lookingFor = userInfo['show_me_to']?.toString() ?? '';
    UserDetails.about = userInfo['about'] ?? '';

    // ----------------- Favorites / Interests -----------------
    UserDetails.hobby = userInfo['hobby'] ?? '';
    UserDetails.music = userInfo['music'] ?? '';
    UserDetails.movie = userInfo['movie'] ?? '';
    UserDetails.dish = userInfo['dish'] ?? '';
    UserDetails.song = userInfo['song'] ?? '';

    // ----------------- Avatars & Covers -----------------
    UserDetails.avatar = userInfo['avater'] ?? '';
    UserDetails.cover = userInfo['cover'] ?? '';

    // ----------------- Social links -----------------
    UserDetails.facebook = userInfo['facebook'] ?? userData['facebook'] ?? '';
    UserDetails.google = userInfo['google'] ?? userData['google'] ?? '';
    UserDetails.twitter = userInfo['twitter'] ?? userData['twitter'] ?? '';
    UserDetails.linkedin = userInfo['linkedin'] ?? userData['linkedin'] ?? '';
    UserDetails.instagram = userInfo['instagram'] ?? userData['instagram'] ?? '';
    UserDetails.discord = userInfo['discord'] ?? userData['discord'] ?? '';
    UserDetails.okru = userInfo['okru'] ?? userData['okru'] ?? '';
    UserDetails.mailru = userInfo['mailru'] ?? userData['mailru'] ?? '';
    UserDetails.wechat = userInfo['wechat'] ?? userData['wechat'] ?? '';
    UserDetails.qq = userInfo['qq'] ?? userData['qq'] ?? '';
    UserDetails.website = userInfo['website'] ?? userData['website'] ?? '';

    // ----------------- Media files -----------------
    UserDetails.mediaFiles = (userInfo['mediafiles'] as List?)
        ?.map((e) => MediaFile.fromJson(e))
        .toList() ??
        [];

    // ----------------- Blocked users -----------------
    try {
      // final blockedResponse = await http.get(
      //   Uri.parse(
      //       '${SocialLoginService.baseUrl}/users/blocked_users?access_token=${UserDetails.accessToken}&limit=50'),
      //   headers: {'Accept': 'application/json'},
      // );
      final blockedResponse = await SessionManager.get(
        Uri.parse(
            '${SocialLoginService.baseUrl}/users/blocked_users?access_token=${UserDetails.accessToken}&limit=50'),
      );

      if (blockedResponse.statusCode == 200) {
        final blockedData = jsonDecode(blockedResponse.body);
        if (blockedData['code'] == 200) {
          UserDetails.blockedUsers =
          List<Map<String, dynamic>>.from(blockedData['data']);
        } else {
          UserDetails.blockedUsers = [];
        }
      } else {
        UserDetails.blockedUsers = [];
      }
    } catch (e) {
      print('Error fetching blocked users: $e');
      UserDetails.blockedUsers = [];
    }


    // Save access token and user data for transaction API
    await SocialLoginService.saveAccessToken(UserDetails.accessToken);
    await SocialLoginService.saveUserData({
      'id': UserDetails.userId.toString(),
      'username': UserDetails.username,
      'email': UserDetails.email,
      'first_name': UserDetails.firstName,
      'last_name': UserDetails.lastName,
      'access_token': UserDetails.accessToken,
      ...userInfo, // Include all user info
    });
    await SessionManager.setSession(userData: userData);
    // ----------------- Debug logs -----------------
    print('--------------------------');
    print('✅ CURRENT USER LOGGED IN:');
    print('User ID: ${UserDetails.userId}');
    print('Username: ${UserDetails.username}');
    print('Email: ${UserDetails.email}');
    print('Country: ${UserDetails.country_txt}');
    print('Phone: ${UserDetails.phone}');
    print('Blocked Users: ${UserDetails.blockedUsers.length}');
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
