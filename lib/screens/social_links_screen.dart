import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'package:hive/hive.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  // Map of social links controllers
  final Map<String, TextEditingController> _controllers = {};

  // List of social platforms
  final List<String> _socialPlatforms = [
    'facebook',
    'twitter',
    'linkedin',
    'instagram',
    'google',
    'discord',
    'okru',
    'mailru',
    'wechat',
    'qq',
    'website'
  ];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current user data
    for (var platform in _socialPlatforms) {
      _controllers[platform] =
          TextEditingController(text: _getUserSocial(platform));
    }
  }

  String _getUserSocial(String platform) {
    switch (platform) {
      case 'facebook':
        return UserDetails.facebook ?? '';
      case 'twitter':
        return UserDetails.twitter ?? '';
      case 'linkedin':
        return UserDetails.linkedin ?? '';
      case 'instagram':
        return UserDetails.instagram ?? '';
      case 'google':
        return UserDetails.google ?? '';
      case 'discord':
        return UserDetails.discord ?? '';
      case 'okru':
        return UserDetails.okru ?? '';
      case 'mailru':
        return UserDetails.mailru ?? '';
      case 'wechat':
        return UserDetails.wechat ?? '';
      case 'qq':
        return UserDetails.qq ?? '';
      case 'website':
        return UserDetails.website ?? '';
      default:
        return '';
    }
  }

  Future<void> _updateSocialLinks() async {
    setState(() => isLoading = true);

    try {
      Map<String, String> body = {'access_token': UserDetails.accessToken};

      // Add all social links from controllers
      for (var platform in _socialPlatforms) {
        body[platform] = _controllers[platform]?.text.trim() ?? '';
      }

      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/update_profile'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        // Update UserDetails
        for (var platform in _socialPlatforms) {
          final value = _controllers[platform]?.text.trim() ?? '';
          switch (platform) {
            case 'facebook':
              UserDetails.facebook = value;
              break;
            case 'twitter':
              UserDetails.twitter = value;
              break;
            case 'linkedin':
              UserDetails.linkedin = value;
              break;
            case 'instagram':
              UserDetails.instagram = value;
              break;
            case 'google':
              UserDetails.google = value;
              break;
            case 'discord':
              UserDetails.discord = value;
              break;
            case 'okru':
              UserDetails.okru = value;
              break;
            case 'mailru':
              UserDetails.mailru = value;
              break;
            case 'wechat':
              UserDetails.wechat = value;
              break;
            case 'qq':
              UserDetails.qq = value;
              break;
            case 'website':
              UserDetails.website = value;
              break;
          }
        }

        // Update Hive
        var box = await Hive.openBox('loginBox');
        Map<String, dynamic> currentUser =
        Map<String, dynamic>.from(box.get('currentUser') ?? {});
        currentUser['user_info'] ??= {};

        for (var platform in _socialPlatforms) {
          currentUser['user_info'][platform] =
              _controllers[platform]?.text.trim() ?? '';
        }

        await box.put('currentUser', currentUser);

        _showSnackBar("Social links updated successfully!", success: true);
      } else {
        _showSnackBar(data['errors']?['error_text'] ?? 'Update failed');
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_social_links)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: _socialPlatforms.map((platform) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[platform],
                        decoration: InputDecoration(
                          labelText: platform[0].toUpperCase() +
                              platform.substring(1),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateSocialLinks,
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(AppLocalizations.of(context)!.common_save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
