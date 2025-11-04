import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/user_details.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'social_login_service.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';


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
                Wrap(
                  alignment: WrapAlignment.center,
                  children: const [
                    Text("Welcome to ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("QuickDate", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFBF01FD))),
                  ],
                ),

                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.login_subtitle, style: const TextStyle(fontSize: 16)),
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
        onPressed: _loginWithWowonder,
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

  // Prompt user for credentials (will check our database or redirect to registration)
  Future<Map<String, String>?> _promptForWowonderCredentials() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign In'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email and password to login or create a new account.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final map = <String, String>{};
              map['username'] = usernameController.text.trim();
              map['password'] = passwordController.text;
              Navigator.pop(context, map);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithWowonder() async {
    setState(() => isLoading = true);

    try {
      // Prompt for credentials (they'll use WoWonder email/password)
      final creds = await _promptForWowonderCredentials();
      if (creds == null) {
        setState(() => isLoading = false);
        return;
      }

      final username = creds['username'] ?? '';
      final password = creds['password'] ?? '';

      if (username.isEmpty || password.isEmpty) {
        _showDialog('Error', 'Please enter your email and password.');
        setState(() => isLoading = false);
        return;
      }

      debugPrint('🔍 Checking if user exists in our database...');

      // Try to login with our database first
      final body = {
        'username': username,
        'password': password.toString(),
        'mobile_device_id': UserDetails.deviceId,
      };

      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      final data = jsonDecode(response.body);
      print("Final data is $data");

      if (response.statusCode == 200 && data['data'] != null) {
        // ✅ User exists in our database - login directly
        debugPrint('✅ User found in database - logging in');
        await _handleLoginSuccess(data['data'], username);
      } else {
        // ❌ User doesn't exist - redirect to registration with pre-filled email
        debugPrint('ℹ️ User not found - redirecting to registration');
        setState(() => isLoading = false);

        if (!mounted) return;

        // Show info dialog first
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Account Not Found'),
            content: Text(
              'No account found with these credentials.\n\n'
              'Would you like to create a new account with email:\n$username?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to registration with pre-filled email
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(prefilledEmail: username),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      _showDialog('Error', 'Failed to check credentials: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
      print("Final data is $data");
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
    print('--------------------------');
    print('🔑 START LOGIN SUCCESS HANDLER');

    // ----------------- Basic user info -----------------
    try {
      UserDetails.accessToken = userData['access_token']?.toString() ?? '';
      UserDetails.userId = userData['user_id'] is int
          ? userData['user_id']
          : int.tryParse(userData['user_id']?.toString() ?? '0') ?? 0;
      UserDetails.password = passwordController.text.trim();

      print('Username: $username');
      print('Access Token: ${UserDetails.accessToken}');
      print('User ID: ${UserDetails.userId}');
    } catch (e) {
      print('Error parsing basic user info: $e');
    }

    // ----------------- user_info -----------------
    Map<String, dynamic> userInfo = {};
    try {
      if (userData['user_info'] is Map) {
        userInfo = Map<String, dynamic>.from(userData['user_info']);
      }
      UserDetails.username = userInfo['username']?.toString() ?? username;
      UserDetails.firstName = userInfo['first_name']?.toString() ?? '';
      UserDetails.lastName = userInfo['last_name']?.toString() ?? '';
      UserDetails.fullName =
      '${UserDetails.firstName} ${UserDetails.lastName}';
      UserDetails.email = userInfo['email']?.toString() ?? '';
      UserDetails.phone = userInfo['phone_number']?.toString() ?? '';
      UserDetails.country_txt = userInfo['country']?.toString() ?? '';
      UserDetails.birthday = userInfo['birthday']?.toString() ?? '';
      UserDetails.gender = userInfo['gender']?.toString() ?? '';
      UserDetails.genderTxt =
          userInfo['gender_txt']?.toString() ?? UserDetails.gender;
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
      UserDetails.about = userInfo['about']?.toString() ?? '';
      UserDetails.isPro = userInfo['is_pro'] ?? "0";


      print('Full Name: ${UserDetails.fullName}');
      print('Email: ${UserDetails.email}');
      print('Phone: ${UserDetails.phone}');
      print('Country: ${UserDetails.country_txt}');
      print('Gender: ${UserDetails.gender}');
      print('Birthday: ${UserDetails.birthday}');
    } catch (e) {
      print('Error parsing user_info: $e');
    }

    // ----------------- Favorites / Interests -----------------
    try {
      UserDetails.hobby = userInfo['hobby']?.toString() ?? '';
      UserDetails.music = userInfo['music']?.toString() ?? '';
      UserDetails.movie = userInfo['movie']?.toString() ?? '';
      UserDetails.dish = userInfo['dish']?.toString() ?? '';
      UserDetails.song = userInfo['song']?.toString() ?? '';

      print('Hobby: ${UserDetails.hobby}');
      print('Music: ${UserDetails.music}');
      print('Movie: ${UserDetails.movie}');
    } catch (e) {
      print('Error parsing favorites: $e');
    }

    // ----------------- Avatars & Covers -----------------
    try {
      UserDetails.avatar = userInfo['avater']?.toString() ?? '';
      UserDetails.cover = userInfo['cover']?.toString() ?? '';
      print('Avatar: ${UserDetails.avatar}');
      print('Cover: ${UserDetails.cover}');
    } catch (e) {
      print('Error parsing avatars/covers: $e');
    }

    // ----------------- Social links -----------------
    try {
      UserDetails.facebook = userInfo['facebook']?.toString() ??
          userData['facebook']?.toString() ??
          '';
      UserDetails.google =
          userInfo['google']?.toString() ?? userData['google']?.toString() ?? '';
      UserDetails.twitter =
          userInfo['twitter']?.toString() ?? userData['twitter']?.toString() ?? '';
      UserDetails.linkedin =
          userInfo['linkedin']?.toString() ?? userData['linkedin']?.toString() ?? '';
      UserDetails.instagram =
          userInfo['instagram']?.toString() ?? userData['instagram']?.toString() ?? '';
      UserDetails.discord =
          userInfo['discord']?.toString() ?? userData['discord']?.toString() ?? '';
      UserDetails.okru =
          userInfo['okru']?.toString() ?? userData['okru']?.toString() ?? '';
      UserDetails.mailru =
          userInfo['mailru']?.toString() ?? userData['mailru']?.toString() ?? '';
      UserDetails.wechat =
          userInfo['wechat']?.toString() ?? userData['wechat']?.toString() ?? '';
      UserDetails.qq =
          userInfo['qq']?.toString() ?? userData['qq']?.toString() ?? '';
      UserDetails.website =
          userInfo['website']?.toString() ?? userData['website']?.toString() ?? '';

      print('Social Links: facebook=${UserDetails.facebook}, google=${UserDetails.google}');
    } catch (e) {
      print('Error parsing social links: $e');
    }

    // ----------------- Media files -----------------
    try {
      final mediaList = userInfo['mediafiles'] as List<dynamic>?;

      if (mediaList != null && mediaList.isNotEmpty) {
        UserDetails.mediaFiles = mediaList
            .map((e) => MediaFile.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        print('Media Files:');
        for (var i = 0; i < UserDetails.mediaFiles.length; i++) {
          final m = UserDetails.mediaFiles[i];
          print('  Media #$i:');
          print('    ID: ${m.id}');
          print('    Full: ${m.full}');
          print('    Avatar: ${m.avater}');
          print('    Video File: ${m.videoFile}');
          print('    Is Video: ${m.isVideo}');
          print('    Is Private: ${m.isPrivate}');
          print('    Private Full: ${m.privateFileFull}');
          print('    Private Avatar: ${m.privateFileAvater}');
          print('    Is Confirmed: ${m.isConfirmed}');
          print('    Is Approved: ${m.isApproved}');
        }
      } else {
        UserDetails.mediaFiles = [];
        print('No media files found.');
      }
    } catch (e) {
      UserDetails.mediaFiles = [];
      print('Error parsing media files: $e');
    }


    // ----------------- Blocked users -----------------
    try {
      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/profile'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': UserDetails.userId.toString(),
          'fetch': 'blocks',
          'access_token': UserDetails.accessToken,
        },
      );

      // Extract JSON from response, ignoring any PHP warnings/HTML
      String body = response.body;
      int startIndex = body.indexOf('{');
      int endIndex = body.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) {
        print('No valid JSON found in response.');
        UserDetails.blockedUsers = [];
        return;
      }

      String jsonString = body.substring(startIndex, endIndex + 1);
      final blockedData = jsonDecode(jsonString);

      if (blockedData['code'] == 200 && blockedData['data'] is Map) {
        var blocks = blockedData['data']['blocks'];
        if (blocks is List) {
          UserDetails.blockedUsers = List<Map<String, dynamic>>.from(blocks);
        } else {
          UserDetails.blockedUsers = [];
        }
      } else {
        UserDetails.blockedUsers = [];
      }

      print('Blocked Users Count: ${UserDetails.blockedUsers.length}');
    } catch (e) {
      print('Error fetching blocked users: $e');
      UserDetails.blockedUsers = [];
    }
    print('✅ LOGIN SUCCESS HANDLER COMPLETE');
    print('--------------------------');

    // Save session & navigate
    try {
      await SocialLoginService.saveAccessToken(UserDetails.accessToken);
      await SocialLoginService.saveUserData({
        'id': UserDetails.userId.toString(),
        'username': UserDetails.username,
        'email': UserDetails.email,
        'first_name': UserDetails.firstName,
        'last_name': UserDetails.lastName,
        'access_token': UserDetails.accessToken,
        ...userInfo,
      });
      await SessionManager.setSession(userData: userData);
    } catch (e) {
      print('Error saving session: $e');
    }

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
                child: Text(AppLocalizations.of(context)!.common_ok),
              ),
            ],
          ),
    );
  }
}
