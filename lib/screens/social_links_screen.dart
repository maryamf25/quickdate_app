import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _googleController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();

  late Box loginBox; // reference to the already opened box

  @override
  void initState() {
    super.initState();
    loginBox = Hive.box('loginBox'); // use the already opened box
    _loadSocialLinks();
  }

  void _loadSocialLinks() {
    setState(() {
      _facebookController.text = loginBox.get('facebook', defaultValue: '');
      _twitterController.text = loginBox.get('twitter', defaultValue: '');
      _googleController.text = loginBox.get('google', defaultValue: '');
      _instagramController.text = loginBox.get('instagram', defaultValue: '');
      _linkedinController.text = loginBox.get('linkedin', defaultValue: '');
      _websiteController.text = loginBox.get('website', defaultValue: '');
    });
  }

  Future<void> _saveSocialLinks() async {
    await loginBox.put('facebook', _facebookController.text);
    await loginBox.put('twitter', _twitterController.text);
    await loginBox.put('google', _googleController.text);
    await loginBox.put('instagram', _instagramController.text);
    await loginBox.put('linkedin', _linkedinController.text);
    await loginBox.put('website', _websiteController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Social Links saved successfully!')),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFBF01FD)),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social Links"),
        backgroundColor: const Color(0xFFBF01FD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              icon: Icons.facebook,
              hint: "Facebook",
              controller: _facebookController,
            ),
            _buildTextField(
              icon: Icons.alternate_email,
              hint: "Twitter",
              controller: _twitterController,
            ),
            _buildTextField(
              icon: Icons.account_circle,
              hint: "Google Plus",
              controller: _googleController,
            ),
            _buildTextField(
              icon: Icons.camera_alt,
              hint: "Instagram",
              controller: _instagramController,
            ),
            _buildTextField(
              icon: Icons.business_center,
              hint: "LinkedIn",
              controller: _linkedinController,
            ),
            _buildTextField(
              icon: Icons.link,
              hint: "Website",
              controller: _websiteController,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSocialLinks,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF01FD),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
