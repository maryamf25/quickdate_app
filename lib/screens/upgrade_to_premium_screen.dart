// upgrade_to_premium_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/razorpay_payment_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/init_cashfree_payment.dart';
void main() {
  runApp(const PremiumUpgradeApp());
}

class PremiumUpgradeApp extends StatefulWidget {
  const PremiumUpgradeApp({super.key});

  @override
  State<PremiumUpgradeApp> createState() => _PremiumUpgradeAppState();
}

class _PremiumUpgradeAppState extends State<PremiumUpgradeApp> {
  late final RazorpayPaymentService _razorpayService;

  @override
  void initState() {
    super.initState();
    print('PremiumUpgradeApp: Initializing RazorpayPaymentService in root app.');
    _razorpayService = RazorpayPaymentService();
  }

  @override
  void dispose() {
    print('PremiumUpgradeApp: Disposing RazorpayPaymentService in root app.');
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Upgrade To Premium',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PremiumUpgradePage(razorpayService: _razorpayService),
    );
  }
}

class PremiumUpgradePage extends StatelessWidget {
  final RazorpayPaymentService razorpayService;

  const PremiumUpgradePage({super.key, required this.razorpayService});

  @override
  Widget build(BuildContext context) {
    // Full-screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    print('PremiumUpgradePage: Building UI.');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Upgrade To Premium',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Activating Premium will help you meet more\npeople, faster.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const Text(
                'Why Choose Premium Membership?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              _buildPremiumFeature(Icons.sticky_note_2_outlined, 'See more stickers on chat'),
              _buildPremiumFeature(Icons.star_outline, 'Show in Premium bar'),
              _buildPremiumFeature(Icons.notifications_active_outlined, 'See likes notifications'),
              _buildPremiumFeature(Icons.percent, 'Get discount when buy boost me'),
              _buildPremiumFeature(Icons.format_list_numbered, 'Display first in find matches'),
              _buildPremiumFeature(Icons.people_alt_outlined, 'Display on top in random users'),
              _buildPremiumFeature(Icons.videocam_outlined, 'Create unlimited video and audio calls'),
              _buildPremiumFeature(Icons.location_on_outlined, 'Find potential matches by country'),
              const SizedBox(height: 30),
              _buildSubscriptionOption(context, 'Weekly', 'Normal', '8\$', 800, Colors.deepOrangeAccent),
              const SizedBox(height: 15),
              _buildSubscriptionOption(context, 'Monthly', 'Save 51%', '25\$', 2500, Colors.purple),
              const SizedBox(height: 15),
              _buildSubscriptionOption(context, 'Yearly', 'Save 90%', '280\$', 28000, Colors.indigo),
              const SizedBox(height: 15),
              _buildSubscriptionOption(context, 'Lifetime', 'Pay once, access forever', '500\$', 50000, Colors.amber),
              const SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: () {
                    print('PremiumUpgradePage: Skip Premium tapped.');
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Skip Premium',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // PREMIUM FEATURES
  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink, size: 28),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
        ],
      ),
    );
  }

  // SUBSCRIPTION OPTION
  Widget _buildSubscriptionOption(
      BuildContext context, String title, String subtitle, String priceDisplay, int priceAmount, Color color) {
    return GestureDetector(
      onTap: () {
        print('PremiumUpgradePage: Subscription option "$title" tapped. Price: $priceDisplay, Amount: $priceAmount');
        _showPaymentMethods(context, title, priceDisplay, priceAmount);
      },
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
            Text(priceDisplay, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, String planName, String priceDisplay, int priceAmount) {
    print('PremiumUpgradePage: _showPaymentMethods called for plan: $planName, price: $priceDisplay, amount: $priceAmount');
    final paymentMethods = [
      {'title': 'RazorPay', 'image': 'assets/razorpay.png'},
      {'title': 'Cashfree', 'image': 'assets/cashfree.png'},
      {'title': 'Paystack', 'image': 'assets/paystack.png'},
      {'title': 'SecurionPay', 'image': 'assets/securionpay.png'},
      {'title': 'AuthorizeNet', 'image': 'assets/authorizenet.png'},
      {'title': 'LyziPay', 'image': 'assets/lyzipay.png'},
      {'title': 'AamarPay', 'image': 'assets/aamarpay.png'},
      {'title': 'FlutterWave', 'image': 'assets/flutterwave.png'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4.0,
                        width: 40.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Select Your Payment Method',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: paymentMethods.length * 70.0,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = paymentMethods[index];
                        return _buildPaymentMethodTile(
                          context,
                          method['title']!,
                          method['image']!,
                              () {
                            print('PremiumUpgradePage: Payment method "${method['title']}" tapped.');
                            Navigator.pop(context); // Close bottom sheet
                            if (method['title'] == 'RazorPay') {
                              print('PremiumUpgradePage: Calling RazorpayService.openCheckout...');
                              razorpayService.openCheckout(context, priceAmount, planName);
                            } else if (method['title'] == 'Cashfree') {
                              print('PremiumUpgradePage: Opening Cashfree dialog with autofill.');
                              _showCashfreeDialog(
                                context,
                                name: "Test User",
                                email: "test@example.com",
                                phone: "9876543210",
                                planName: planName,
                                amount: priceAmount.toString(),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Paying $priceDisplay for $planName via ${method['title']}')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PAYMENT METHOD TILE
  Widget _buildPaymentMethodTile(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: SizedBox(width: 30, height: 30, child: Image.asset(imagePath)),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 0, indent: 16, endIndent: 16),
      ],
    );
  }

// CASHFREE DIALOG
  void _showCashfreeDialog(
      BuildContext context, {
        String? name,
        String? email,
        String? phone,
        required String planName,
        required String amount,
      }) {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cashfree Payment Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputField(Icons.person, nameController, "Name"),
              const SizedBox(height: 10),
              _buildInputField(Icons.email, emailController, "Email"),
              const SizedBox(height: 10),
              _buildInputField(Icons.phone, phoneController, "Phone"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              Navigator.pop(context);

              // Start CashFree payment flow
              InitCashFreePayment.startPayment(
                context: context,
                name: name,
                email: email,
                phone: phone,
                amount: amount,
                planName: planName,
                onResult: (success, message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text("Pay"),
          ),
        ],
      ),
    );
  }

  // TEXT INPUT HELPER
  Widget _buildInputField(IconData icon, TextEditingController controller, String hint) {
    return Row(
      children: [
        Container(width: 40, child: Icon(icon, size: 24)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
