// upgrade_to_premium_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/razorpay_payment_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/init_cashfree_payment.dart';
import '../services/paystack_payment_service.dart';
import '../services/securionpay_payment_service.dart';
import '../services/authorizenet_payment_service.dart';
import '../services/iyzipay_payment_service.dart';
import '../services/aamarpay_payment_service.dart';
import '../services/flutterwave_payment_service.dart';
import '../services/lyzipay_payment_service.dart';
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
              _buildPremiumFeature(
                  Icons.sticky_note_2_outlined, 'See more stickers on chat'),
              _buildPremiumFeature(Icons.star_outline, 'Show in Premium bar'),
              _buildPremiumFeature(Icons.notifications_active_outlined,
                  'See likes notifications'),
              _buildPremiumFeature(
                  Icons.percent, 'Get discount when buy boost me'),
              _buildPremiumFeature(
                  Icons.format_list_numbered, 'Display first in find matches'),
              _buildPremiumFeature(
                  Icons.people_alt_outlined, 'Display on top in random users'),
              _buildPremiumFeature(Icons.videocam_outlined,
                  'Create unlimited video and audio calls'),
              _buildPremiumFeature(Icons.location_on_outlined,
                  'Find potential matches by country'),
              const SizedBox(height: 30),
              _buildSubscriptionOption(context, 'Weekly', 'Normal', '8\$', 800,
                  Colors.deepOrangeAccent),
              const SizedBox(height: 15),
              _buildSubscriptionOption(
                  context, 'Monthly', 'Save 51%', '25\$', 2500, Colors.purple),
              const SizedBox(height: 15),
              _buildSubscriptionOption(
                  context, 'Yearly', 'Save 90%', '280\$', 28000, Colors.indigo),
              const SizedBox(height: 15),
              _buildSubscriptionOption(
                  context, 'Lifetime', 'Pay once, access forever', '500\$',
                  50000, Colors.amber),
              const SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: () {
                    print('PremiumUpgradePage: Skip Premium tapped.');
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Skip Premium',
                    style: TextStyle(fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600),
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
  Widget _buildSubscriptionOption(BuildContext context, String title,
      String subtitle, String priceDisplay, int priceAmount, Color color) {
    return GestureDetector(
      onTap: () {
        print(
            'PremiumUpgradePage: Subscription option "$title" tapped. Price: $priceDisplay, Amount: $priceAmount');
        _showPaymentMethods(context, title, priceDisplay, priceAmount);
      },
      child: Container(
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
            Text(priceDisplay, style: const TextStyle(color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, String planName,
      String priceDisplay, int priceAmount) {
    print(
        'PremiumUpgradePage: _showPaymentMethods called for plan: $planName, price: $priceDisplay, amount: $priceAmount');
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
      builder: (_) =>
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16.0),
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
                                print(
                                    'PremiumUpgradePage: Payment method "${method['title']}" tapped.');
                                Navigator.pop(context); // Close bottom sheet
                                _handlePaymentMethod(
                                  context: context,
                                  method: method['title']!,
                                  planName: planName,
                                  priceDisplay: priceDisplay,
                                  priceAmount: priceAmount,
                                );
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
  Widget _buildPaymentMethodTile(BuildContext context, String title,
      String imagePath, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: SizedBox(
              width: 30, height: 30, child: Image.asset(imagePath)),
          title: Text(title, style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
          trailing: const Icon(
              Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 0, indent: 16, endIndent: 16),
      ],
    );
  }

// CASHFREE DIALOG
  void _showCashfreeDialog(BuildContext context, {
    String? name,
    String? email,
    String? phone,
    required String planName,
    required String amount,
  }) {
    final TextEditingController nameController = TextEditingController(
        text: name);
    final TextEditingController emailController = TextEditingController(
        text: email);
    final TextEditingController phoneController = TextEditingController(
        text: phone);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
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
                      const SnackBar(
                          content: Text('Please fill in all fields')),
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
  Widget _buildInputField(IconData icon, TextEditingController controller,
      String hint) {
    return Row(
      children: [
        Container(width: 40, child: Icon(icon, size: 24)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // COMPREHENSIVE PAYMENT METHOD HANDLER
  void _handlePaymentMethod({
    required BuildContext context,
    required String method,
    required String planName,
    required String priceDisplay,
    required int priceAmount,
  }) async {
    final String backendUrl = 'https://backend.staralign.me'; // Replace with your actual backend URL

    switch (method) {
      case 'RazorPay':
        print('PremiumUpgradePage: Handling RazorPay payment');
        razorpayService.openCheckout(context, priceAmount, planName);
        break;

      case 'Cashfree':
        print('PremiumUpgradePage: Handling Cashfree payment');
        _showCashfreeDialog(
          context,
          name: "Test User",
          email: "test@example.com",
          phone: "9876543210",
          planName: planName,
          amount: priceAmount.toString(),
        );
        break;

      case 'Paystack':
        print('PremiumUpgradePage: Handling Paystack payment');
        await _handlePaystackPayment(
            context, priceAmount, planName, backendUrl);
        break;

      case 'SecurionPay':
        print('PremiumUpgradePage: Handling SecurionPay payment');
        await _handleSecurionPayPayment(
            context, priceAmount, planName, backendUrl);
        break;

      case 'AuthorizeNet':
        print('PremiumUpgradePage: Handling Authorize.Net payment');
        await _handleAuthorizeNetPayment(
            context, priceAmount, planName, backendUrl);
        break;

      case 'IyziPay':
        print('PremiumUpgradePage: Handling IyziPay payment');
        await _handleIyziPayPayment(context, priceAmount, planName, backendUrl);
        break;

      case 'AamarPay':
        print('PremiumUpgradePage: Handling AamarPay payment');
        await _handleAamarPayPayment(
            context, priceAmount, planName, backendUrl);
        break;

      case 'FlutterWave':
        print('PremiumUpgradePage: Handling FlutterWave payment');
        await _handleFlutterwavePayment(
            context, priceAmount, planName, backendUrl);
        break;

      case 'LyziPay':
        print('PremiumUpgradePage: Handling LyziPay payment');
        await _handleLyziPayPayment(context, priceAmount, planName, backendUrl);
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment method $method not yet implemented')),
        );
    }
  }

  // PAYSTACK PAYMENT HANDLER
  Future<void> _handlePaystackPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = PaystackPaymentService(backendBaseUrl: backendUrl);
      final response = await service.initializeTransaction(
        email: 'test@example.com',
        amount: priceAmount, // Amount in kobo (smallest unit)
        planName: planName,
      );

      if (response != null && response['status'] == true) {
        if (!context.mounted) return;
        await service.openPaymentPage(
          context: context,
          authorizationUrl: response['data']['authorization_url'],
          reference: response['data']['reference'],
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: Paystack payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Paystack Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: Paystack error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // SECURIONPAY PAYMENT HANDLER
  Future<void> _handleSecurionPayPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = SecurionPayPaymentService(backendBaseUrl: backendUrl);
      final response = await service.initializeCharge(
        email: 'test@example.com',
        amountInCents: priceAmount * 100,
        currency: 'USD',
        description: 'Premium Plan: $planName',
        planName: planName,
      );

      if (response != null && response['charge_id'] != null &&
          context.mounted) {
        await service.showPaymentForm(
          context: context,
          chargeId: response['charge_id'],
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: SecurionPay payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('SecurionPay Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: SecurionPay error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // AUTHORIZE.NET PAYMENT HANDLER
  Future<void> _handleAuthorizeNetPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = AuthorizeNetPaymentService(backendBaseUrl: backendUrl);
      final response = await service.initializeTransaction(
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        amount: priceAmount.toDouble(),
        currency: 'USD',
        planName: planName,
      );

      if (response != null && response['transaction_id'] != null &&
          context.mounted) {
        await service.showPaymentForm(
          context: context,
          planName: planName,
          amount: priceAmount.toDouble(),
          onSuccess: () {
            print('PremiumUpgradePage: Authorize.Net payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Authorize.Net Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: Authorize.Net error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // IZIPAY PAYMENT HANDLER
  Future<void> _handleIyziPayPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = IyziPayPaymentService(backendBaseUrl: backendUrl);
      final response = await service.initializePayment(
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        priceAmount: priceAmount,
        currency: 'TRY',
        planName: planName,
        ip: '192.168.1.1',
      );

      if (response != null && response['payment_id'] != null &&
          context.mounted) {
        await service.openPaymentPage(
          context: context,
          checkoutFormContent: response['checkout_form_content'] ??
              response['payment_url'] ?? '',
          paymentId: response['payment_id'],
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: IyziPay payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('IyziPay Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: IyziPay error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // AAMARPAY PAYMENT HANDLER
  Future<void> _handleAamarPayPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = AamarPayPaymentService(backendBaseUrl: backendUrl);
      final orderId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final response = await service.initializePayment(
        orderId: orderId,
        amount: priceAmount.toString(),
        currency: 'BDT',
        customerName: 'Test User',
        customerEmail: 'test@example.com',
        customerPhone: '9876543210',
        planName: planName,
      );

      if (response != null && response['payment_url'] != null &&
          context.mounted) {
        await service.openPaymentGateway(
          context: context,
          paymentUrl: response['payment_url'],
          orderId: orderId,
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: AamarPay payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('AamarPay Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: AamarPay error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // FLUTTERWAVE PAYMENT HANDLER
  Future<void> _handleFlutterwavePayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = FlutterwavePaymentService(backendBaseUrl: backendUrl);
      final response = await service.initializeTransaction(
        email: 'test@example.com',
        customerName: 'Test User',
        amount: priceAmount.toDouble(),
        currency: 'NGN',
        planName: planName,
        phone: '9876543210',
      );

      if (response != null && response['data'] != null &&
          response['data']['link'] != null && context.mounted) {
        await service.openPaymentPage(
          context: context,
          paymentUrl: response['data']['link'],
          transactionReference: response['data']['tx_ref'],
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: Flutterwave payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Flutterwave Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: Flutterwave error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // LYZIPAY PAYMENT HANDLER
  Future<void> _handleLyziPayPayment(BuildContext context,
      int priceAmount,
      String planName,
      String backendUrl,) async {
    try {
      final service = LyziPayPaymentService(backendBaseUrl: backendUrl);
      final customerId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final response = await service.initializePayment(
        customerId: customerId,
        customerEmail: 'test@example.com',
        customerPhone: '9876543210',
        amount: priceAmount.toDouble(),
        currency: 'USD',
        planName: planName,
      );

      if (response != null && response['checkout_url'] != null &&
          context.mounted) {
        await service.openPaymentPage(
          context: context,
          checkoutUrl: response['checkout_url'],
          paymentId: response['payment_id'],
          planName: planName,
          onSuccess: () {
            print('PremiumUpgradePage: LyziPay payment successful');
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('LyziPay Error: $error'),
                    backgroundColor: Colors.red),
              );
            }
          },
        );
      }
    } catch (e) {
      print('PremiumUpgradePage ERROR: LyziPay error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}