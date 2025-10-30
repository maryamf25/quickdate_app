// services/init_cashfree_payment.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Assuming you have a base URL for your API.
// Adjust this based on your actual backend setup.
// From the C# code, it looks like:
// InitializeCashFreeAsync -> calls "QuickDateClient.Requests.Payments.InitializeCashFreeAsync"
// CashFreeAsync -> calls "QuickDateClient.Requests.Payments.CashFreeAsync"
// CashFreeGetStatusAsync -> calls "QuickDateClient.Requests.Payments.CashFreeGetStatusAsync"
// We will simulate these with direct calls to implied endpoints.
// You might have a SocialLoginService.baseUrl or similar for this.
class ApiConstants {
  static const String baseUrl = 'https://backend.staralign.me'; // Replace with your actual base URL
  static const String initializeCashFreeEndpoint = '/cashfree/pay'; // From the API doc: POST /cashfree/pay
  static const String cashFreeSuccessEndpoint = '/cashfree/success'; // From the API doc: POST /cashfree/success
  // The C# code implies a separate endpoint to get status.
  // The API doc doesn't explicitly show a separate /cashfree/status,
  // but it's reasonable to assume one for client-side status verification.
  // We'll use a hypothetical one or adapt. For now, assuming direct status call.
  // The C# code uses "RequestsAsync.Payments.CashFreeGetStatusAsync" which needs a server endpoint
  // Let's assume an endpoint like '/aj/cashfree/status' as hinted in the C# `OnPageStarted` method.
  static const String cashFreeGetStatusEndpoint = '/aj/cashfree/status';
}


/// Models mirroring the originals in C# (trimmed to fields used by the flow)
class CashFreeObject {
  final String jsonForm; // The HTML form content or URL to load in WebView
  final String orderId;
  final String signature;
  final String appId;
  final String? userName; // Storing for _confirmCashFreePayment if needed
  final String? userEmail;
  final String? userPhone;

  CashFreeObject({
    required this.jsonForm,
    required this.orderId,
    required this.signature,
    required this.appId,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  // Factory method to create CashFree object from user details and price
  static Future<CashFreeObject?> createFromUserDetails({
    required String name,
    required String email,
    required String phone,
    required String amount,
    // planName not strictly needed for CashfreeObject creation, but can be useful
    // for backend logging if passed to the API.
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        Fluttertoast.showToast(msg: 'No internet connection');
        return null;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.initializeCashFreeEndpoint}');
      debugPrint('Calling ${uri.toString()} with body: name=$name, phone=$phone, email=$email, price=$amount');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          // Add any auth headers if required, e.g., 'Authorization': 'Bearer YOUR_TOKEN'
          // The C# code implies Auth()->id is required for /cashfree/pay
        },
        body: {
          'name': name,
          'phone': phone,
          'email': email,
          'price': amount,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('CashFreeObject.createFromUserDetails response: $data');

        // Check for the 'html' key or 'jsonForm' if your backend names it differently
        // The API doc uses "html" in the 200 OK response example.
        if (data['html'] != null && data['orderId'] != null && data['signature'] != null && data['appId'] != null) {
          return CashFreeObject(
            jsonForm: data['html'], // The HTML form content (or URL if direct redirect)
            orderId: data['orderId'],
            signature: data['signature'],
            appId: data['appId'],
            userName: name,
            userEmail: email,
            userPhone: phone,
          );
        } else {
          debugPrint('Missing required fields in CashFree /pay response: $data');
          throw Exception('Invalid response from payment initialization.');
        }
      } else {
        final error = json.decode(response.body);
        debugPrint('CashFreeObject.createFromUserDetails error response: $error');
        throw Exception(error['errors']?['error_text'] ?? 'Failed to initialize CashFree payment. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating CashFree order: $e');
      Fluttertoast.showToast(msg: 'Failed to initiate payment: ${e.toString().contains("Exception:") ? e.toString().split("Exception:")[1].trim() : e.toString()}');
      return null;
    }
  }
}

class CashFreeGetStatusObject {
  final String txStatus;
  final String orderAmount;
  final String referenceId;
  final String paymentMode;
  final String txMsg;
  final String txTime;

  CashFreeGetStatusObject({
    required this.txStatus,
    required this.orderAmount,
    required this.referenceId,
    required this.paymentMode,
    required this.txMsg,
    required this.txTime,
  });

  factory CashFreeGetStatusObject.fromJson(Map<String, dynamic> json) => CashFreeGetStatusObject(
    txStatus: json['txStatus']?.toString() ?? '',
    orderAmount: json['orderAmount']?.toString() ?? '',
    referenceId: json['referenceId']?.toString() ?? '',
    paymentMode: json['paymentMode']?.toString() ?? '',
    txMsg: json['txMsg']?.toString() ?? '',
    txTime: json['txTime']?.toString() ?? '',
  );
}

typedef OnPaymentResult = void Function(bool success, String message);

/// Service/widget that opens a dialog with a WebView for CashFree payment flow
class InitCashFreePayment {
  /// Shows the CashFree payment dialog and handles the entire payment flow
  static Future<void> startPayment({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String amount,
    required String planName, // Added for potential backend use
    OnPaymentResult? onResult,
  }) async {
    // Store loading dialog context to handle dismissal safely
    BuildContext? loadingContext;

    try {
      // Show initial loading indicator for API call
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            loadingContext = ctx;
            return WillPopScope(
              onWillPop: () async => false, // Prevent dismissing with back button
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      } else {
        onResult?.call(false, 'Context not mounted, cannot start payment.');
        return;
      }


      // Create CashFree order by calling your backend
      final cashFreeObject = await CashFreeObject.createFromUserDetails(
        name: name,
        email: email,
        phone: phone,
        amount: amount,
      );

      // Hide initial loading safely
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.of(loadingContext!).pop();
      }

      if (cashFreeObject == null) {
        onResult?.call(false, 'Failed to create payment order. Check logs for details.');
        return;
      }

      // Show payment WebView
      if (context.mounted) {
        await _showPaymentDialog(context, cashFreeObject, amount, onResult);
      }
    } catch (e) {
      debugPrint('Error in startPayment: $e');
      // Hide initial loading safely
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.of(loadingContext!).pop();
      }
      onResult?.call(false, 'Payment failed unexpectedly: ${e.toString()}');
    }
  }

  static Future<void> _showPaymentDialog(
      BuildContext context,
      CashFreeObject cashFreeObject,
      String amount,
      OnPaymentResult? onResult,
      ) async {
    final UniqueKey webViewKey = UniqueKey();

    // Step 1: Initialize WebViewController first
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    // Step 2: Set Navigation Delegate
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          debugPrint('WebView loading: $progress%');
        },
        onPageStarted: (url) {
          debugPrint('WebView started: $url');
          if (url.contains('${ApiConstants.baseUrl}/aj/cashfree/success')) {
            _handleCashfreeSuccessCallback(context, url, cashFreeObject, amount, onResult);
          }
        },
        onPageFinished: (url) {
          debugPrint('WebView finished: $url');
          if (cashFreeObject.jsonForm.startsWith('<form')) {
            // Inject HTML form if the backend returned raw HTML
            controller.runJavaScript(
                "document.open(); document.write('${cashFreeObject.jsonForm.replaceAll("'", "\\'")}'); document.close();"
            );
          }
        },
        onWebResourceError: (error) {
          debugPrint('WebView error: ${error.description}');
          onResult?.call(false, 'Web page error: ${error.description}');
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
      ),
    );

    // Step 3: Load initial request (about:blank for HTML, URL otherwise)
    if (cashFreeObject.jsonForm.startsWith('<form')) {
      controller.loadRequest(Uri.parse('about:blank'));
    } else {
      controller.loadRequest(Uri.parse(cashFreeObject.jsonForm));
    }

    // Step 4: Show the dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toolbar
            Container(
              color: Theme.of(ctx).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Complete Payment',
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
                      Navigator.of(ctx).pop(); // Close the WebView dialog
                      onResult?.call(false, 'Payment cancelled by user');
                    },
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: WebViewWidget(key: webViewKey, controller: controller),
            ),
          ],
        ),
      ),
    );
  }


  // Handle the callback when the WebView navigates to the success URL
  static Future<void> _handleCashfreeSuccessCallback(
      BuildContext context,
      String callbackUrl,
      CashFreeObject cashFreeObject,
      String amount,
      OnPaymentResult? onResult,
      ) async {
    // Only process once if multiple redirects happen
    if (onResult == null) return; // Already handled or no callback set

    // Set onResult to null to prevent duplicate processing
    final tempOnResult = onResult;
    onResult = null;

    BuildContext? progressContext;
    try {
      if (!context.mounted) {
        tempOnResult.call(false, 'Context not mounted during callback handling.');
        return;
      }

      // Show progress indicator
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          progressContext = ctx;
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );

      // 1. Get payment status from your backend (simulating CashFreeGetStatusAsync)
      final status = await _getCashFreeStatus(cashFreeObject);

      if (status != null) {
        // 2. Confirm payment with your backend (simulating CashFreeAsync)
        final success = await _confirmCashFreePayment(context, status, cashFreeObject, amount);
        tempOnResult.call(success, success ? 'Payment successful!' : 'Payment verification failed.');
      } else {
        tempOnResult.call(false, 'Could not verify payment status with backend.');
      }
    } catch (e) {
      debugPrint('Error in _handleCashfreeSuccessCallback: $e');
      tempOnResult.call(false, 'Payment processing error: ${e.toString()}');
    } finally {
      // Hide progress indicator safely
      if (progressContext != null && Navigator.canPop(progressContext!)) {
        Navigator.of(progressContext!).pop();
      }
      // Close the WebView dialog safely
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }


  /// Get payment status from backend (simulating RequestsAsync.Payments.CashFreeGetStatusAsync)
  /// This endpoint might be internal or specific to your backend,
  /// the C# code implies it needs appId, secretKey, orderId, mode.
  /// We're adapting this to an assumed HTTP endpoint on your backend.
  static Future<CashFreeGetStatusObject?> _getCashFreeStatus(CashFreeObject cashFreeObject) async {
    if (await _checkConnectivity() == false) return null;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cashFreeGetStatusEndpoint}');
      debugPrint('Calling ${uri.toString()} for status with orderId: ${cashFreeObject.orderId}');

      // The C# code passes AppId, SecretKey, OrderId, Mode to a backend function.
      // Your Flutter app will call *your* backend with what's necessary for *your* backend
      // to then call Cashfree's status API.
      // Assuming your backend needs order_id and possibly app_id and signature for verification.
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'order_id': cashFreeObject.orderId,
          'app_id': cashFreeObject.appId,
          // 'signature': cashFreeObject.signature, // Might not be needed for just status if backend uses its own secret
        },
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint('CashFreeGetStatusObject response: $data');
        // The C# `CashFreeGetStatusObject` example implies data['data'] in the response
        if (data['status'] == 200 && data['data'] != null) {
          return CashFreeGetStatusObject.fromJson(data['data']);
        }
        debugPrint('Invalid status response from backend: ${resp.body}');
      } else {
        debugPrint('Error status code from backend status endpoint: ${resp.statusCode}, body: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error getting payment status from backend: $e');
      Fluttertoast.showToast(msg: 'Failed to get payment status.');
    }
    return null;
  }

  /// Confirm payment with backend (simulating RequestsAsync.Payments.CashFreeAsync)
  /// This is the final verification step on your server.
  static Future<bool> _confirmCashFreePayment(
      BuildContext context,
      CashFreeGetStatusObject status,
      CashFreeObject cashFreeObject,
      String amount,
      ) async {
    if (await _checkConnectivity() == false) return false;

    try {
      // Only proceed if Cashfree reported a successful transaction
      if (status.txStatus.toLowerCase() != 'success') {
        debugPrint('Payment not successful according to Cashfree status: ${status.txStatus} - ${status.txMsg}');
        Fluttertoast.showToast(msg: 'Payment not successful: ${status.txMsg}');
        return false;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cashFreeSuccessEndpoint}');
      debugPrint('Calling ${uri.toString()} for confirmation with orderId: ${cashFreeObject.orderId}');

      // The backend API expects specific parameters for /cashfree/success
      // as per the API documentation. Ensure all required parameters are sent.
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'txStatus': status.txStatus,
          // 'hash': '', // The API doc includes 'hash', but the C# code doesn't explicitly send it
          // after getting status. Your backend might re-generate/verify it internally.
          'orderId': cashFreeObject.orderId,
          'orderAmount': status.orderAmount, // Use amount from status, not necessarily initial `amount`
          'referenceId': status.referenceId,
          'paymentMode': status.paymentMode,
          'txMsg': status.txMsg,
          'txTime': status.txTime,
          'signature': cashFreeObject.signature, // Use the original signature from /cashfree/pay
          // The API doc for /cashfree/success does not list 'amount', 'name', 'email', 'phone', 'app_id'
          // as direct parameters. These are likely derived on the backend from the hash or orderId.
          // If your backend *does* require them explicitly, add them here.
          // 'amount': amount,
          // 'name': cashFreeObject.userName,
          // 'email': cashFreeObject.userEmail,
          // 'phone': cashFreeObject.userPhone,
          // 'app_id': cashFreeObject.appId,
        },
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        debugPrint('CashFree success confirmation response: $data');
        // The API doc for /cashfree/success has "message": "SUCCESS", "code": 200
        // We check for "code": 200
        if (data['code'] == 200) {
          Fluttertoast.showToast(msg: 'Payment successfully processed!');
          return true;
        } else {
          debugPrint('Backend reported non-200 code for success confirmation: ${resp.body}');
          Fluttertoast.showToast(msg: 'Payment failed during final verification: ${data['message'] ?? 'Unknown error'}');
          return false;
        }
      } else {
        debugPrint('Error status code from backend success endpoint: ${resp.statusCode}, body: ${resp.body}');
        Fluttertoast.showToast(msg: 'Payment confirmation failed with server error. Status: ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error confirming payment with backend: $e');
      Fluttertoast.showToast(msg: 'Failed to confirm payment: ${e.toString()}');
      return false;
    }
  }

  // Helper to check network connectivity
  static Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      Fluttertoast.showToast(msg: 'No internet connection');
      return false;
    }
    return true;
  }
}