// lib/services/flutterwave_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class FlutterwavePaymentService {
  static const String publicKey = 'FLWPUBK_TEST_xxxxx'; // Replace with test key
  static const String secretKey = 'FLWSECK_TEST_xxxxx'; // Only on backend
  static const String baseUrl = 'https://api.flutterwave.com/v3';
  final String backendBaseUrl;

  FlutterwavePaymentService({required this.backendBaseUrl});

  /// Initialize a transaction
  Future<Map<String, dynamic>?> initializeTransaction({
    required String email,
    required String customerName,
    required double amount,
    required String currency,
    required String planName,
    required String phone,
  }) async {
    try {
      print('FlutterwavePaymentService: Initializing transaction for $email, amount: $amount $currency, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/flutterwave/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'customer_name': customerName,
          'amount': amount,
          'currency': currency,
          'plan_name': planName,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('FlutterwavePaymentService: Transaction initialized: $data');
        return data;
      } else {
        print('FlutterwavePaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('FlutterwavePaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify transaction
  Future<bool> verifyTransaction({
    required String transactionReference,
    required BuildContext context,
  }) async {
    try {
      print('FlutterwavePaymentService: Verifying transaction with reference: $transactionReference');

      final url = Uri.parse('$backendBaseUrl/payments/flutterwave/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'transaction_reference': transactionReference,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == 'success' || data['data']['status'] == 'successful';
        print('FlutterwavePaymentService: Verification result: $isVerified');
        return isVerified;
      } else {
        print('FlutterwavePaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('FlutterwavePaymentService ERROR: Exception during verification: $e');
      return false;
    }
  }

  /// Open Flutterwave hosted payment page
  Future<void> openPaymentPage({
    required BuildContext context,
    required String paymentUrl,
    required String transactionReference,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('FlutterwavePaymentService: Opening payment page. URL: $paymentUrl');

      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('FlutterwavePaymentService: WebView page started: $url');
            // Check for completion redirect
            if (url.contains('status=completed') || url.contains('tx_ref=')) {
              _extractAndVerify(context, url, transactionReference, planName, onSuccess, onError);
            }
          },
          onWebResourceError: (error) {
            print('FlutterwavePaymentService ERROR: WebView error: ${error.description}');
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
                color: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Flutterwave Payment',
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
      print('FlutterwavePaymentService ERROR: Exception in openPaymentPage: $e');
      onError('Failed to open payment page: $e');
    }
  }

  void _extractAndVerify(
    BuildContext context,
    String url,
    String transactionReference,
    String planName,
    VoidCallback onSuccess,
    Function(String) onError,
  ) {
    Navigator.of(context).pop();
    verifyTransaction(transactionReference: transactionReference, context: context)
        .then((isVerified) {
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
    })
        .catchError((e) {
      onError('Verification error: $e');
    });
  }
}

