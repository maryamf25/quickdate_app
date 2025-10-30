// lib/services/authorizenet_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class AuthorizeNetPaymentService {
  static const String apiLoginId = 'YOUR_API_LOGIN_ID'; // Replace with test key
  static const String transactionKey = 'YOUR_TRANSACTION_KEY'; // Only on backend
  static const String clientKey = 'YOUR_CLIENT_KEY'; // Client-side key for tokenization
  final String backendBaseUrl;

  AuthorizeNetPaymentService({required this.backendBaseUrl});

  /// Initialize a transaction
  Future<Map<String, dynamic>?> initializeTransaction({
    required String email,
    required String firstName,
    required String lastName,
    required double amount,
    required String currency,
    required String planName,
  }) async {
    try {
      print('AuthorizeNetPaymentService: Initializing transaction for $email, amount: $amount $currency, plan: $planName');

      final url = Uri.parse('$backendBaseUrl/payments/authorizenet/initialize');
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
          'amount': amount,
          'currency': currency,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('AuthorizeNetPaymentService: Transaction initialized: $data');
        return data;
      } else {
        print('AuthorizeNetPaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AuthorizeNetPaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Generate payment nonce (tokenization)
  Future<String?> generatePaymentNonce({
    required String cardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      print('AuthorizeNetPaymentService: Generating payment nonce');

      final url = Uri.parse('$backendBaseUrl/payments/authorizenet/nonce');
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
        final nonce = data['nonce'];
        print('AuthorizeNetPaymentService: Nonce generated: $nonce');
        return nonce;
      } else {
        print('AuthorizeNetPaymentService ERROR: Nonce generation failed. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AuthorizeNetPaymentService ERROR: Exception during nonce generation: $e');
      return null;
    }
  }

  /// Create transaction with nonce
  Future<bool> createTransaction({
    required String nonce,
    required double amount,
    required String planName,
    required BuildContext context,
  }) async {
    try {
      print('AuthorizeNetPaymentService: Creating transaction with nonce');

      final url = Uri.parse('$backendBaseUrl/payments/authorizenet/charge');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nonce': nonce,
          'amount': amount,
          'plan_name': planName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isSuccessful = data['transaction_response']['response_code'] == '1' ||
                            data['messages']['result_code'] == 'Ok';
        print('AuthorizeNetPaymentService: Transaction result: $isSuccessful');
        return isSuccessful;
      } else {
        print('AuthorizeNetPaymentService ERROR: Transaction creation failed. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('AuthorizeNetPaymentService ERROR: Exception during transaction creation: $e');
      return false;
    }
  }

  /// Show payment form in dialog
  Future<void> showPaymentForm({
    required BuildContext context,
    required String planName,
    required double amount,
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
        title: const Text('Authorize.Net Payment'),
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

              // Generate nonce
              final nonce = await generatePaymentNonce(
                cardNumber: cardNumberController.text,
                cardholderName: cardholderNameController.text,
                expiryMonth: int.parse(expiryMonthController.text),
                expiryYear: int.parse(expiryYearController.text),
                cvv: cvvController.text,
              );

              if (nonce == null) {
                onError('Failed to generate payment nonce');
                return;
              }

              // Create transaction
              final success = await createTransaction(
                nonce: nonce,
                amount: amount,
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

