// credits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mainprofile.dart';
import '../services/razorpay_payment_service.dart'; // Import Razorpay service
import '../utils/user_details.dart'; // Import UserDetails to access balance

// Import the reusable payment method bottom sheet
import '../widgets/payment_method_bottom_sheet.dart'; // Adjust path as needed

void main() {
  runApp(const CreditsApp());
}

class CreditsApp extends StatefulWidget {
  const CreditsApp({super.key});

  @override
  State<CreditsApp> createState() => _CreditsAppState();
}

class _CreditsAppState extends State<CreditsApp> {
  late final RazorpayPaymentService _razorpayService;

  @override
  void initState() {
    super.initState();
    print('CreditsApp: Initializing RazorpayPaymentService in root app.');
    _razorpayService = RazorpayPaymentService();
  }

  @override
  void dispose() {
    print('CreditsApp: Disposing RazorpayPaymentService in root app.');
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credits Page',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CreditsPage(razorpayService: _razorpayService),
    );
  }
}
class CreditsPage extends StatefulWidget {
  final RazorpayPaymentService razorpayService; // Accept Razorpay service

  const CreditsPage({super.key, required this.razorpayService});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _carouselItems = [
    {'icon': Icons.rocket_launch, 'text': 'Put yourself First in Search'},
    {'icon': Icons.card_giftcard, 'text': 'Get additional Stickers'},
    {'icon': Icons.favorite, 'text': 'Double your chances for a friendship'},
    {'icon': Icons.rocket_launch, 'text': 'Boost your profile'},
    {'icon': Icons.chat_bubble_outline, 'text': 'Highlight your messages'},
    {'icon': Icons.card_giftcard, 'text': 'Send a gift'},
    {'icon': Icons.track_changes_outlined, 'text': 'Get seen 100x in Discover'},
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
        toolbarHeight: 0, // hides system app bar
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
                      top: 100,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 100,
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
                // Modified to call _showPaymentMethods
                _buildCreditOption(
                  context, // Pass context
                  'Bag of Credits',
                  '1000',
                  '\$ 50',
                  5000, // Amount in cents/smallest unit for payment (50 * 100)
                  const Icon(Icons.monetization_on, color: Colors.orange, size: 40),
                ),
                const SizedBox(height: 15),
                // Modified to call _showPaymentMethods
                _buildCreditOption(
                  context, // Pass context
                  'Box of Credits',
                  '5000',
                  '\$ 100',
                  10000, // Amount in cents/smallest unit for payment (100 * 100)
                  const Icon(Icons.card_giftcard_outlined, color: Colors.purple, size: 40),
                ),
                const SizedBox(height: 15),
                // Modified to call _showPaymentMethods
                _buildCreditOption(
                  context, // Pass context
                  'Chest of Credits',
                  '10000',
                  '\$ 150',
                  15000, // Amount in cents/smallest unit for payment (150 * 100)
                  const Icon(Icons.savings, color: Colors.brown, size: 40),
                ),
                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainProfileScreen()),
                      );
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
    );
  }

  Widget _buildCreditBalanceCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your QuickDate Credits balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${UserDetails.balance} Credits',
                  style: const TextStyle(
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
              child: Icon(icon, color: Colors.pink, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
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
            color: _currentPage == index
                ? Colors.grey
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // Modified _buildCreditOption to trigger the bottom sheet
  Widget _buildCreditOption(
      BuildContext context, // Added context
      String title,
      String subtitle,
      String priceDisplay,
      int priceAmount, // Amount in smallest unit for payment
      Widget iconWidget) {
    return GestureDetector(
      onTap: () {
        print(
            'CreditsPage: Credit option "$title" tapped. Price: $priceDisplay, Amount: $priceAmount');
        _showPaymentMethods(context, title, priceDisplay, priceAmount);
      },
      child: Container(
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
              priceDisplay,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the payment methods bottom sheet
  void _showPaymentMethods(BuildContext context, String planName,
      String priceDisplay, int priceAmount) {
    print(
        'CreditsPage: _showPaymentMethods called for item: $planName, price: $priceDisplay, amount: $priceAmount');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          PaymentMethodBottomSheet(
            planName: planName, // Use 'planName' to represent the credit pack name
            priceDisplay: priceDisplay,
            priceAmount: priceAmount,
            razorpayService: widget.razorpayService, // Pass the service from the widget
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

    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(
        size.width * 0.2, size.height * 0.05, size.width * 0.4, size.height * 0.15);
    path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.25, size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

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

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}