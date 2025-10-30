// lib/services/lyzipay_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class LyziPayPaymentService {
  static const String apiKey = 'YOUR_API_KEY'; // Replace with test key
  static const String secretKey = 'YOUR_SECRET_KEY'; // Only on backend
  static const String baseUrl = 'https://api.lyzipay.com';
  final String backendBaseUrl;

  LyziPayPaymentService({required this.backendBaseUrl});

  /// Initialize a payment
  Future<Map<String, dynamic>?> initializePayment({
    required String customerId,
    required String customerEmail,
    required String customerPhone,
    required double amount,
    required String currency,
    required String planName,
  }) async {
    try {
      print('LyziPayPaymentService: Initializing payment for $customerId, amount: $amount $currency, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/lyzipay/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
          'amount': amount,
          'currency': currency,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('LyziPayPaymentService: Payment initialized: $data');
        return data;
      } else {
        print('LyziPayPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('LyziPayPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify payment status
  Future<bool> verifyPayment({
    required String paymentId,
    required BuildContext context,
  }) async {
    try {
      print('LyziPayPaymentService: Verifying payment with ID: $paymentId');

      final url = Uri.parse('$backendBaseUrl/payments/lyzipay/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'payment_id': paymentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == 'success' || data['status'] == 'completed';
        print('LyziPayPaymentService: Verification result: $isVerified');
        return isVerified;
      } else {
        print('LyziPayPaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('LyziPayPaymentService ERROR: Exception during verification: $e');
      return false;
    }
  }

  /// Open LyziPay hosted payment page
  Future<void> openPaymentPage({
    required BuildContext context,
    required String checkoutUrl,
    required String paymentId,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('LyziPayPaymentService: Opening payment page. URL: $checkoutUrl');

      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('LyziPayPaymentService: WebView page started: $url');
          },
          onWebResourceError: (error) {
            print('LyziPayPaymentService ERROR: WebView error: ${error.description}');
            onError('Payment page error: ${error.description}');
          },
        ),
      );

      await controller.loadRequest(Uri.parse(checkoutUrl));

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'LyziPay Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onError('Payment cancelled by user');
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(controller: controller),
              ),
            ],
          ),
        ),
      );

      // After dialog closes, verify payment
      verifyPayment(paymentId: paymentId, context: context).then((isVerified) {
        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verified successfully for $planName!'),
              backgroundColor: Colors.green,
            ),
          );
          onSuccess();
        }
      });
    } catch (e) {
      print('LyziPayPaymentService ERROR: Exception in openPaymentPage: $e');
      onError('Failed to open payment page: $e');
    }
  }
}

