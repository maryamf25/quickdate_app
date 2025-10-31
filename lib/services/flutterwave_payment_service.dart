// lib/services/flutterwave_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/payment_webview_page.dart';


class FlutterwavePaymentService {
  // Do NOT store secret keys in the client. All secret operations must be done on the backend.
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
    required String type, // 'go_pro' or 'credit'
    required String phone,
    String? authToken, // optional Bearer token
    Map<String, String>? extraHeaders, // optional additional headers (e.g., Cookie)
    Map<String, String>? cardData, // optional card fields: card_number, cvv, expiry_month, expiry_year, postal_code, card_holder_name
  }) async {
    try {
      print('FlutterwavePaymentService: Initializing transaction for $email, amount: $amount $currency, plan: $planName');

      // NOTE: the project's PHP backend exposes endpoints at /aj/fluttewave/pay and /aj/fluttewave/success
      // Use that endpoint instead of the earlier /payments/flutterwave/initialize
      final url = Uri.parse('${backendBaseUrl.replaceAll(RegExp(r'\/+\z'), '')}/aj/fluttewave/pay');

      // The backend expects at minimum: amount, email and type (go_pro or credit)
      // In this app we call Flutterwave for upgrades (go_pro).
      // PHP backend expects form POST (populate $_POST), so send x-www-form-urlencoded
      final amountStr = (amount % 1 == 0) ? amount.toInt().toString() : amount.toString();
      // Build headers and include auth or extra headers if provided
      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      if (extraHeaders != null) {
        headers.addAll(extraHeaders);
      }

      final bodyMap = {
        'email': email,
        'amount': amountStr,
        'type': type,
      };
      if (cardData != null) {
        // merge card fields into body so backend can perform direct charge if supported
        bodyMap.addAll(cardData);
      }

      final response = await http.post(
        url,
        headers: headers,
        body: bodyMap,
      );

      print('FlutterwavePaymentService: Received response. Status: ${response.statusCode}');
      print('FlutterwavePaymentService: Raw body:\n${response.body}');

      if (response.statusCode != 200) {
        print('FlutterwavePaymentService ERROR: Failed to initialize. Status: ${response.statusCode}');
        print('FlutterwavePaymentService ERROR: Response body:\n${response.body}');
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      // Backend should return JSON; if not, log and bail
      if (!contentType.toLowerCase().contains('application/json')) {
        print('FlutterwavePaymentService ERROR: Expected JSON but got Content-Type: $contentType');
        print('FlutterwavePaymentService ERROR: Response body (non-JSON):\n${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body);

      // The provided PHP backend returns $data with numeric 'status' and 'url' when success.
      // Normalize that to the UI shape { 'status': 'success', 'data': { 'link': ..., 'tx_ref': ... } }
      try {
        final int? statusNum = decoded['status'] is int ? decoded['status'] as int : int.tryParse('${decoded['status'] ?? ''}');
        if (statusNum != null && statusNum == 200 && decoded['url'] != null) {
          final String link = decoded['url'];

          // Try to extract tx_ref or flw_ref from the link's query parameters
          String txRef = '';
          try {
            final uri = Uri.parse(link);
            txRef = uri.queryParameters['tx_ref'] ?? uri.queryParameters['txref'] ?? uri.queryParameters['flw_ref'] ?? '';
          } catch (_) {
            txRef = '';
          }

          final normalized = {
            'status': 'success',
            'data': {
              'link': link,
              'tx_ref': txRef,
            }
          };

          print('FlutterwavePaymentService: Normalized init response: $normalized');
          return normalized;
        } else {
          print('FlutterwavePaymentService ERROR: Backend returned unsuccessful init: $decoded');
          return null;
        }
      } catch (e) {
        print('FlutterwavePaymentService ERROR: Error processing backend init response: $e');
        print('FlutterwavePaymentService ERROR: Raw response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('FlutterwavePaymentService ERROR: Exception during initialization: $e');
      return null;
    }
  }

  /// Verify transaction
  /// transactionIdentifier: could be transaction_id (flw_ref) or tx_ref depending on redirect
  Future<bool> verifyTransaction({
    required String transactionIdentifier,
    required String mode, // 'pro' or 'credits' (derived from redirect URL)
    required int? membershipType, // for pro mode
    required int? amount, // for credits mode
    required BuildContext context,
  }) async {
    try {
      print('FlutterwavePaymentService: Verifying transaction with identifier: $transactionIdentifier, mode: $mode, membershipType: $membershipType, amount: $amount');

      final url = Uri.parse('${backendBaseUrl.replaceAll(RegExp(r'\/+\z'), '')}/aj/fluttewave/success');

      final Map<String, dynamic> body = {
        'status': 'successful',
        // backend expects transaction_id (the actual flutterwave transaction id) — use provided identifier as transaction_id
        'transaction_id': transactionIdentifier,
      };

      // backend expects 'type' to be 'go_pro' or 'credit'
      if (mode == 'pro') {
        body['type'] = 'go_pro';
        if (membershipType != null) body['membershipType'] = membershipType;
      } else if (mode == 'credits') {
        body['type'] = 'credit';
        if (amount != null) body['amount'] = (amount % 1 == 0) ? amount.toInt().toString() : amount.toString();
      }

      // Send verification as form-encoded so PHP accesses values via $_POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body.map((k, v) => MapEntry(k, v == null ? '' : v.toString())),
      );

      print('FlutterwavePaymentService: Verify response status: ${response.statusCode}');
      print('FlutterwavePaymentService: Verify raw body:\n${response.body}');

      if (response.statusCode != 200) {
        print('FlutterwavePaymentService ERROR: Verification failed. Status: ${response.statusCode}');
        return false;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.toLowerCase().contains('application/json')) {
        print('FlutterwavePaymentService ERROR: Expected JSON in verification but got Content-Type: $contentType');
        print('FlutterwavePaymentService ERROR: Response body (non-JSON):\n${response.body}');
        return false;
      }

      try {
        final data = jsonDecode(response.body);
        // PHP backend uses either ['code']==200 or ['status']==200 in different branches
        final int? codeNum = data['code'] is int ? data['code'] as int : int.tryParse('${data['code'] ?? ''}');
        final int? statusNum = data['status'] is int ? data['status'] as int : int.tryParse('${data['status'] ?? ''}');
        final bool ok = (codeNum != null && codeNum == 200) || (statusNum != null && statusNum == 200);
        print('FlutterwavePaymentService: Verification result ok=$ok payload=$data');
        return ok;
      } catch (e) {
        print('FlutterwavePaymentService ERROR: JSON parse error during verification: $e');
        print('FlutterwavePaymentService ERROR: Raw verification body:\n${response.body}');
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

      // Navigate to a full screen WebView page that mimics the provided Android UI
      if (!context.mounted) return;
      final service = this;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => PaymentWebViewPage(
          service: service,
          paymentUrl: paymentUrl,
          transactionReference: transactionReference,
          planName: planName,
          onSuccess: onSuccess,
          onError: onError,
        ),
      ));
    } catch (e) {
      print('FlutterwavePaymentService ERROR: Exception in openPaymentPage: $e');
      onError('Failed to open payment page: $e');
    }
  }
}
