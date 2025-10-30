// lib/services/aamarpay_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class AamarPayPaymentService {
  static const String storeId = 'YOUR_STORE_ID'; // Replace with test store ID
  static const String signatureKey = 'YOUR_SIGNATURE_KEY'; // Only on backend
  static const String sandboxUrl = 'https://sandbox.aamarpay.com';
  static const String productionUrl = 'https://aamarpay.com';
  final String backendBaseUrl;
  final bool isSandbox;

  AamarPayPaymentService({required this.backendBaseUrl, this.isSandbox = true});

  String get baseUrl => isSandbox ? sandboxUrl : productionUrl;

  /// Initialize payment and get form data
  Future<Map<String, dynamic>?> initializePayment({
    required String orderId,
    required String amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String planName,
  }) async {
    try {
      print('AamarPayPaymentService: Initializing payment for $orderId, amount: $amount $currency, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/aamarpay/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('AamarPayPaymentService: Payment initialized: $data');
        return data;
      } else {
        print('AamarPayPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AamarPayPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify payment after IPN or callback
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentStatus,
    required BuildContext context,
  }) async {
    try {
      print('AamarPayPaymentService: Verifying payment for order: $orderId, status: $paymentStatus');

      final url = Uri.parse('$backendBaseUrl/payments/aamarpay/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'payment_status': paymentStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == 'success' || data['verified'] == true;
        print('AamarPayPaymentService: Payment verification result: $isVerified');
        return isVerified;
      } else {
        print('AamarPayPaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('AamarPayPaymentService ERROR: Exception during verification: $e');
      return false;
    }
  }

  /// Open AamarPay payment gateway in WebView
  Future<void> openPaymentGateway({
    required BuildContext context,
    required String paymentUrl,
    required String orderId,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('AamarPayPaymentService: Opening payment gateway. URL: $paymentUrl');

      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('AamarPayPaymentService: WebView page started: $url');
            // Check for success redirect
            if (url.contains('success_url') || url.contains('status=success')) {
              _handlePaymentSuccess(context, orderId, planName, onSuccess, onError);
            }
            // Check for failure redirect
            else if (url.contains('fail_url') || url.contains('status=failed')) {
              onError('Payment failed');
            }
            // Check for cancel redirect
            else if (url.contains('cancel_url') || url.contains('status=cancel')) {
              onError('Payment cancelled');
            }
          },
          onWebResourceError: (error) {
            print('AamarPayPaymentService ERROR: WebView error: ${error.description}');
            onError('Payment page error: ${error.description}');
          },
        ),
      );

      await controller.loadRequest(Uri.parse(paymentUrl));

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
                color: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AamarPay Payment',
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
    } catch (e) {
      print('AamarPayPaymentService ERROR: Exception in openPaymentGateway: $e');
      onError('Failed to open payment gateway: $e');
    }
  }

  void _handlePaymentSuccess(
    BuildContext context,
    String orderId,
    String planName,
    VoidCallback onSuccess,
    Function(String) onError,
  ) {
    Navigator.of(context).pop();
    verifyPayment(
      orderId: orderId,
      paymentStatus: 'success',
      context: context,
    ).then((isVerified) {
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verified successfully for $planName!'),
            backgroundColor: Colors.green,
          ),
        );
        onSuccess();
      } else {
        onError('Payment verification failed');
      }
    }).catchError((e) {
      onError('Verification error: $e');
    });
  }
}

