// lib/services/securionpay_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class SecurionPayPaymentService {
  static const String publicKey = 'YOUR_PUBLIC_KEY'; // Replace with test key
  static const String secretKey = 'YOUR_SECRET_KEY'; // Only on backend
  final String backendBaseUrl;

  SecurionPayPaymentService({required this.backendBaseUrl});

  /// Initialize a charge/payment
  Future<Map<String, dynamic>?> initializeCharge({
    required String email,
    required int amountInCents, // Amount in cents
    required String currency, // e.g., 'USD'
    required String description,
    required String planName,
  }) async {
    try {
      print('SecurionPayPaymentService: Initializing charge for $email, amount: $amountInCents $currency, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/securionpay/initialize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amountInCents,
          'currency': currency,
          'description': description,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('SecurionPayPaymentService: Charge initialized: $data');
        return data;
      } else {
        print('SecurionPayPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('SecurionPayPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Tokenize card data (server-side through backend)
  Future<String?> tokenizeCard({
    required String cardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      print('SecurionPayPaymentService: Tokenizing card');

      final url = Uri.parse('$backendBaseUrl/payments/securionpay/tokenize');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'card_number': cardNumber,
          'cardholder_name': cardholderName,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvv': cvv,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print('SecurionPayPaymentService: Token generated: $token');
        return token;
      } else {
        print('SecurionPayPaymentService ERROR: Tokenization failed. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('SecurionPayPaymentService ERROR: Exception during tokenization: $e');
      return null;
    }
  }

  /// Create a charge with tokenized card
  Future<bool> createCharge({
    required String chargeId,
    required String token,
    required String planName,
    required BuildContext context,
  }) async {
    try {
      print('SecurionPayPaymentService: Creating charge with token: $token');

      final url = Uri.parse('$backendBaseUrl/payments/securionpay/charge');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'charge_id': chargeId,
          'token': token,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isSuccessful = data['status'] == 'APPROVED' || data['status'] == 'success';
        print('SecurionPayPaymentService: Charge creation result: $isSuccessful');
        return isSuccessful;
      } else {
        print('SecurionPayPaymentService ERROR: Charge creation failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('SecurionPayPaymentService ERROR: Exception during charge creation: $e');
      return false;
    }
  }

  /// Show payment form in dialog
  Future<void> showPaymentForm({
    required BuildContext context,
    required String chargeId,
    required String planName,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final cardNumberController = TextEditingController();
    final cardholderNameController = TextEditingController();
    final expiryMonthController = TextEditingController();
    final expiryYearController = TextEditingController();
    final cvvController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SecurionPay Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(Icons.credit_card, cardNumberController, 'Card Number'),
              const SizedBox(height: 10),
              _buildTextField(Icons.person, cardholderNameController, 'Cardholder Name'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(Icons.calendar_today, expiryMonthController, 'MM'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(Icons.calendar_today, expiryYearController, 'YYYY'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(Icons.lock, cvvController, 'CVV'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Validate inputs
              if (cardNumberController.text.isEmpty ||
                  cardholderNameController.text.isEmpty ||
                  expiryMonthController.text.isEmpty ||
                  expiryYearController.text.isEmpty ||
                  cvvController.text.isEmpty) {
                onError('Please fill in all fields');
                return;
              }

              // Tokenize card
              final token = await tokenizeCard(
                cardNumber: cardNumberController.text,
                cardholderName: cardholderNameController.text,
                expiryMonth: int.parse(expiryMonthController.text),
                expiryYear: int.parse(expiryYearController.text),
                cvv: cvvController.text,
              );

              if (token == null) {
                onError('Failed to tokenize card');
                return;
              }

              // Create charge
              final success = await createCharge(
                chargeId: chargeId,
                token: token,
                planName: planName,
                context: context,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment successful for $planName!'),
                    backgroundColor: Colors.green,
                  ),
                );
                onSuccess();
              } else {
                onError('Payment failed');
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

