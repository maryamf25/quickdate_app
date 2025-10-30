// lib/services/iyzipay_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class IyziPayPaymentService {
  static const String apiKey = 'YOUR_API_KEY'; // Replace with test key
  static const String secretKey = 'YOUR_SECRET_KEY'; // Only on backend
  static const String sandboxUrl = 'https://sandbox-api.iyzipay.com';
  static const String productionUrl = 'https://api.iyzipay.com';
  final String backendBaseUrl;
  final bool isSandbox;

  IyziPayPaymentService({required this.backendBaseUrl, this.isSandbox = true});

  String get baseUrl => isSandbox ? sandboxUrl : productionUrl;

  /// Initialize a payment
  Future<Map<String, dynamic>?> initializePayment({
    required String email,
    required String firstName,
    required String lastName,
    required int priceAmount,
    required String currency,
    required String planName,
    required String ip,
  }) async {
    try {
      print('IyziPayPaymentService: Initializing payment for $email, amount: $priceAmount, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/iyzipay/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'price': priceAmount.toString(),
          'currency': currency,
          'plan_name': planName,
          'ip_address': ip,
          'locale': 'en',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('IyziPayPaymentService: Payment initialized: $data');
        return data;
      } else {
        print('IyziPayPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('IyziPayPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify payment completion
  Future<bool> verifyPayment({
    required String paymentId,
    required String conversationId,
    required BuildContext context,
  }) async {
    try {
      print('IyziPayPaymentService: Verifying payment with ID: $paymentId');

      final url = Uri.parse('$backendBaseUrl/payments/iyzipay/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'payment_id': paymentId,
          'conversation_id': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == 'success' || data['status'] == '1';
        print('IyziPayPaymentService: Payment verification result: $isVerified');
        return isVerified;
      } else {
        print('IyziPayPaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('IyziPayPaymentService ERROR: Exception during verification: $e');
      return false;
    }
  }

  /// Open IyziPay hosted checkout in WebView
  Future<void> openPaymentPage({
    required BuildContext context,
    required String checkoutFormContent,
    required String paymentId,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('IyziPayPaymentService: Opening payment page');

      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('IyziPayPaymentService: WebView page started: $url');
          },
          onPageFinished: (url) {
            print('IyziPayPaymentService: WebView page finished: $url');
            // Inject the checkout form if it's HTML
            if (checkoutFormContent.startsWith('<')) {
              controller.runJavaScript(
                "document.body.innerHTML = '${checkoutFormContent.replaceAll("'", "\\'")}';"
              );
            }
          },
          onWebResourceError: (error) {
            print('IyziPayPaymentService ERROR: WebView error: ${error.description}');
            onError('Payment page error: ${error.description}');
          },
        ),
      );

      if (checkoutFormContent.startsWith('http')) {
        await controller.loadRequest(Uri.parse(checkoutFormContent));
      } else {
        await controller.loadRequest(Uri.parse('about:blank'));
      }

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
                color: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'IyziPay Payment',
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
      print('IyziPayPaymentService ERROR: Exception in openPaymentPage: $e');
      onError('Failed to open payment page: $e');
    }
  }
}

