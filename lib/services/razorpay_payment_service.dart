// razorpay_payment_service.dart (updated for Web warning)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../screens/social_login_service.dart'; // Assuming this provides UserDetails and baseUrl

class RazorpayPaymentService {
  final Razorpay _razorpay = Razorpay();

  RazorpayPaymentService() {
    if (!kIsWeb) {
      print('RazorpayPaymentService: Constructor called. Setting up event listeners.');
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } else {
      print('RazorpayPaymentService WARNING: Razorpay plugin does NOT work on Web.');
    }
  }

  late BuildContext _context;
  late int _amount;
  late String _planName;

  void openCheckout(BuildContext context, int amount, String planName) async {
    _context = context;
    _amount = amount;
    _planName = planName;

    if (kIsWeb) {
      print('RazorpayPaymentService WARNING: Cannot open Razorpay checkout on Web.');
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(content: Text('Razorpay payments are not supported on Web.')),
      );
      return;
    }

    print('RazorpayPaymentService: openCheckout called with amount: $amount, plan: $planName');

    String razorpayKey;
    try {
      razorpayKey = await _getRazorpayKey();
    } catch (e) {
      print('RazorpayPaymentService ERROR: Failed to get Razorpay key: $e');
      razorpayKey = 'rzp_test_YOUR_FALLBACK_KEY';
    }

    var options = {
      'key': razorpayKey,
      'amount': _amount, // in paise
      'name': 'QuickDate',
      'description': _planName,
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'},
      'currency': 'INR',
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      print('RazorpayPaymentService: Attempting to open Razorpay checkout with options: $options');
      _razorpay.open(options);
      print('RazorpayPaymentService: _razorpay.open() called. Awaiting response...');
    } catch (e) {
      print('RazorpayPaymentService ERROR: Exception caught while opening Razorpay: $e');
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(content: Text('Failed to open payment gateway: $e')),
      );
    }
  }

  Future<String> _getRazorpayKey() async {
    // Normally fetch key from native resources
    // On Web, plugin is unavailable, so throw
    if (kIsWeb) throw Exception('Razorpay plugin not supported on Web');
    // TODO: Replace this with fetching key from Android/iOS resources if needed
    return 'rzp_test_ruzI7R7AkonOIi';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('RazorpayPaymentService: EVENT_PAYMENT_SUCCESS received. Payment ID: ${response.paymentId}');
    bool success = await _verifyPayment(
      paymentId: response.paymentId!,
      orderId: response.orderId ?? '',
      merchantAmount: _amount,
    );

    print('RazorpayPaymentService: Payment verification result: $success');
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Payment verified successfully for $_planName!'
            : 'Payment verification failed!'),
      ),
    );

    if (Navigator.of(_context).canPop()) {
      print('RazorpayPaymentService: Popping current route after payment success.');
      Navigator.pop(_context);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('RazorpayPaymentService: EVENT_PAYMENT_ERROR received. Code: ${response.code}, Message: ${response.message}');
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('RazorpayPaymentService: EVENT_EXTERNAL_WALLET received. Wallet Name: ${response.walletName}');
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
    );
  }

  Future<bool> _verifyPayment({
    required String paymentId,
    required String orderId,
    required int merchantAmount,
  }) async {
    print('RazorpayPaymentService: Calling _verifyPayment for paymentId: $paymentId, orderId: $orderId, amount: $merchantAmount');
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}razorpay/create');
      print('RazorpayPaymentService: Backend verification URL: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'payment_id': paymentId,
          'order_id': orderId,
          'merchant_amount': merchantAmount.toString(),
        },
      );

      if (response.statusCode == 200) {
        print('RazorpayPaymentService: Backend verification success: ${response.body}');
        return true;
      } else {
        print('RazorpayPaymentService: Backend verification failed. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('RazorpayPaymentService ERROR: Exception caught during backend verification: $e');
      return false;
    }
  }

  void dispose() {
    if (!kIsWeb) {
      print('RazorpayPaymentService: Disposing Razorpay instance.');
      _razorpay.clear();
    }
  }
}
