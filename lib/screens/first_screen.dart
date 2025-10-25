import 'package:flutter/material.dart';
import 'package:quickdate_app/screens/LoginActivity.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(  // <-- Wrap in SafeArea
        child: Container(
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.37,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bottom image (icon splash)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            'assets/images/icon_splash.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                      // Top image (title/banner)
                      Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.03,
                          left: 15,
                          right: 15,
                        ),
                        child: Image.asset(
                          'assets/images/TitileImages.png',
                          width: double.infinity,
                          height: 246,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        'Welcome Header',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sub-header text here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
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
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: Center(
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA214D1),
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 2,
                                      color: Color(0x33C21CF0),
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Footer text here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 45),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
