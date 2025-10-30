import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle

void main() {
  runApp(const CreditsApp());
}

class CreditsApp extends StatelessWidget {
  const CreditsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credits Page',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CreditsPage(),
    );
  }
}

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'icon': Icons.rocket_launch,
      'text': 'Put yourself First in Search', // This is from your first attached image
    },
    {
      'icon': Icons.card_giftcard, // Changed icon to be more generic for "Stickers"
      'text': 'Get additional Stickers', // This is from your second attached image
    },
    {
      'icon': Icons.favorite, // Changed icon to a heart for "friendship"
      'text': 'Double your chances for a friendship', // This is from your third attached image
    },
    {
      'icon': Icons.rocket_launch,
      'text': 'Boost your profile',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'text': 'Highlight your messages',
    },
    {
      'icon': Icons.card_giftcard,
      'text': 'Send a gift',
    },
    {
      'icon': Icons.track_changes_outlined,
      'text': 'Get seen 100x in Discover',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Hide default AppBar
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBar(),
                const SizedBox(height: 20),
                const Text(
                  'Credits',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCreditBalanceCard(),
                    Positioned(
                      top: 100, // Adjust this value to position the card correctly
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 100, // Height of the boost profile card
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _carouselItems.length,
                          itemBuilder: (context, index) {
                            return _buildBoostProfileCard(
                              _carouselItems[index]['icon'],
                              _carouselItems[index]['text'],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(child: _buildPageIndicator()),
                const SizedBox(height: 30),
                const Text(
                  'Buy Credits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                _buildCreditOption(
                  'Bag of Credits',
                  '1000',
                  '\$ 50',
                  const Icon(Icons.monetization_on, color: Colors.orange, size: 40), // Placeholder image
                ),
                const SizedBox(height: 15),
                _buildCreditOption(
                  'Box of Credits',
                  '5000',
                  '\$ 100',
                  const Icon(Icons.card_giftcard_outlined, color: Colors.purple, size: 40), // Placeholder image
                ),
                const SizedBox(height: 15),
                _buildCreditOption(
                  'Chest of Credits',
                  '10000',
                  '\$ 150',
                  const Icon(Icons.savings, color: Colors.brown, size: 40), // Placeholder image
                ),
                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Skip Credits',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
              IconButton(icon: const Icon(Icons.circle_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '3:14',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.wifi, size: 18),
              const Icon(Icons.signal_cellular_alt, size: 18),
              const SizedBox(width: 4),
              Text(
                '51%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.battery_full, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditBalanceCard() {
    return Container(
      width: double.infinity,
      height: 180, // Height of the card, enough to show the content
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)], // Pink and Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _CreditCardBackgroundPainter(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your QuickDate Credits balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '0 Credits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostProfileCard(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: Colors.pink,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _carouselItems.length,
            (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.grey : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditOption(
      String title, String subtitle, String price, Widget iconWidget) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconWidget,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.green, // Assuming green for price based on image
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Wavy top-left element
    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(
        size.width * 0.2, size.height * 0.05, size.width * 0.4, size.height * 0.15);
    path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.25, size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Wavy bottom-right element
    path.reset();
    path.moveTo(size.width, size.height * 0.9);
    path.quadraticBezierTo(
        size.width * 0.8, size.height * 0.95, size.width * 0.6, size.height * 0.85);
    path.quadraticBezierTo(
        size.width * 0.4, size.height * 0.75, size.width * 0.2, size.height * 0.9);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Additional circles/patterns to mimic the background
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}