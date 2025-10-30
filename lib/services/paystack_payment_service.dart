// lib/services/paystack_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class PaystackPaymentService {
  static const String baseUrl = 'https://api.paystack.co';
  static const String publicKey = 'pk_test_YOUR_PUBLIC_KEY'; // Replace with your test key
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY'; // Only used on backend
  final String backendBaseUrl;

  PaystackPaymentService({required this.backendBaseUrl});

  /// Initialize a payment transaction
  Future<Map<String, dynamic>?> initializeTransaction({
    required String email,
    required int amount, // Amount in smallest currency unit (kobo for NGN)
    required String planName,
    String? reference,
  }) async {
    try {
      print('PaystackPaymentService: Initializing transaction for $email, amount: $amount, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/paystack/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amount,
          'plan_name': planName,
          'reference': reference ?? DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('PaystackPaymentService: Transaction initialized successfully: $data');
        return data;
      } else {
        print('PaystackPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('PaystackPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify payment transaction
  Future<bool> verifyTransaction({
    required String reference,
    required BuildContext context,
  }) async {
    try {
      print('PaystackPaymentService: Verifying transaction with reference: $reference');

      final url = Uri.parse('$backendBaseUrl/payments/paystack/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reference': reference,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == true || data['status'] == 'success';
        print('PaystackPaymentService: Verification result: $isVerified');
        return isVerified;
      } else {
        print('PaystackPaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('PaystackPaymentService ERROR: Exception during verification: $e');
      return false;
    }
  }

  /// Open Paystack payment in WebView
  Future<void> openPaymentPage({
    required BuildContext context,
    required String authorizationUrl,
    required String reference,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('PaystackPaymentService: Opening payment page. URL: $authorizationUrl');

      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('PaystackPaymentService: WebView page started: $url');
            if (url.contains('close=')) {
              // Payment completed
              _extractReferenceAndVerify(context, url, reference, planName, onSuccess, onError);
            }
          },
          onWebResourceError: (error) {
            print('PaystackPaymentService ERROR: WebView error: ${error.description}');
            onError('Payment page error: ${error.description}');
          },
        ),
      );

      await controller.loadRequest(Uri.parse(authorizationUrl));

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
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Paystack Payment',
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
      print('PaystackPaymentService ERROR: Exception in openPaymentPage: $e');
      onError('Failed to open payment page: $e');
    }
  }

  void _extractReferenceAndVerify(
    BuildContext context,
    String url,
    String reference,
    String planName,
    VoidCallback onSuccess,
    Function(String) onError,
  ) {
    Navigator.of(context).pop();
    verifyTransaction(reference: reference, context: context).then((isVerified) {
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

