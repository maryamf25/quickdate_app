// lib/services/aamarpay_payment_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class AamarPayPaymentService {
  // These constants are only informative; secret keys MUST remain server-side.
  static const String sandboxUrl = 'https://sandbox.aamarpay.com';
  static const String productionUrl = 'https://secure.aamarpay.com';
  final String backendBaseUrl;
  final bool isSandbox;

  AamarPayPaymentService({required this.backendBaseUrl, this.isSandbox = true});

  String get baseUrl => isSandbox ? sandboxUrl : productionUrl;

  /// Call backend to get Aamarpay hosted URL.
  /// Backend expected: POST /aamarpay/get (x-www-form-urlencoded) with fields: type, price, name, email, phone
  /// Returns: {'status':200, 'url': '<hosted-url>'} on success.
  Future<Map<String, dynamic>?> initializePayment({
    required String type, // 'credit' or 'go_pro'
    required String price,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? authToken,
    String? planName,
  }) async {
    try {
      print('AamarPayPaymentService: Initializing payment type=$type price=$price plan=$planName');

      final uri = Uri.parse('$backendBaseUrl/aamarpay/get');

      final headers = <String,String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = {
        'type': type,
        'price': price,
        'name': customerName,
        'email': customerEmail,
        'phone': customerPhone,
      };

      final response = await http.post(uri, headers: headers, body: body);

      print('AamarPayPaymentService: Received status ${response.statusCode} with content-type=${response.headers['content-type']}');

      if (response.statusCode == 200) {
        String responseBody = response.body;

        final contentType = (response.headers['content-type'] ?? '').toLowerCase();
        final looksLikeHtml = responseBody.contains('<') || contentType.contains('text/html');

        if (looksLikeHtml) {
          // Don't attempt to heuristically extract JSON from HTML (it often fails).
          final html = response.body;

          // 1) Try to find a full aamarpay.com URL inside the HTML
          final reg = RegExp(r'''https?://(?:sandbox\.|secure\.)?aamarpay\.com/[^\s"'<]+''', caseSensitive: false);
          final match = reg.firstMatch(html);
          if (match != null) {
            final found = match.group(0) ?? '';
            print('AamarPayPaymentService: Found Aamarpay URL inside HTML: $found');
            return {
              'status': response.statusCode,
              'url': found,
            };
          }

          // 2) Try to find request.php path and build url
          final pathReg = RegExp(r'''request\.php\?[^\s"'<>]+''', caseSensitive: false);
          final pathMatch = pathReg.firstMatch(html);
          if (pathMatch != null) {
            final path = pathMatch.group(0) ?? '';
            final base = isSandbox ? sandboxUrl : productionUrl;
            final normalizedBase = base.endsWith('/') ? base : base + '/';
            final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
            final full = normalizedBase + normalizedPath;
            print('AamarPayPaymentService: Built Aamarpay URL from path: $full');
            return {
              'status': response.statusCode,
              'url': full,
            };
          }

          // 3) If nothing found, return structured error with raw snippet
          final snippet = html.substring(0, html.length > 1200 ? 1200 : html.length);
          print('AamarPayPaymentService ERROR: Non-JSON HTML response from backend (first 1200 chars): ${snippet}');
          return {
            'status': response.statusCode,
            'error': true,
            'message': 'Non-JSON (HTML) response from backend',
            'raw': snippet,
          };
        }

        // If not HTML, try to parse JSON normally
        try {
          final data = jsonDecode(responseBody);
          print('AamarPayPaymentService: initialize response: $data');
          return data;
        } catch (e) {
          final snippet = responseBody.substring(0, responseBody.length > 1000 ? 1000 : responseBody.length);
          print('AamarPayPaymentService ERROR: Failed to parse JSON response: $e');
          print('AamarPayPaymentService ERROR: Response body (first 1000 chars): ${snippet}');
          return {
            'status': response.statusCode,
            'error': true,
            'message': 'Failed to parse JSON response',
            'raw': snippet,
            'exception': e.toString(),
          };
        }
      } else {
        print('AamarPayPaymentService ERROR: Failed initialize. Status: ${response.statusCode}, body: ${response.body}');
        final snippet = response.body.substring(0, response.body.length > 800 ? 800 : response.body.length);
        return {
          'status': response.statusCode,
          'error': true,
          'message': 'HTTP ${response.statusCode}',
          'raw': snippet,
        };
      }
    } catch (e) {
      print('AamarPayPaymentService ERROR: Exception during initializePayment: $e');
      return null;
    }
  }

  /// Verify payment by calling backend /aamarpay/success (server-side will perform final verification).
  /// If your backend already processes provider callbacks, this call can be used to request status and make it idempotent.
  Future<bool> verifyPayment({
    required String merTxnid,
    required String type,
    String? amount,
    required String payStatus, // e.g. "Successful"
    String? authToken,
  }) async {
    try {
      print('AamarPayPaymentService: Verifying payment mer_txnid=$merTxnid status=$payStatus');
      final uri = Uri.parse('$backendBaseUrl/aamarpay/success');
      final headers = <String,String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = {
        'type': type,
        'amount': amount ?? '',
        'mer_txnid': merTxnid,
        'pay_status': payStatus,
      };

      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('AamarPayPaymentService: verify response: $data');
        // Backend example returns { message: "SUCCESS", code: 200 }
        if ((data['code'] != null && data['code'] == 200) || (data['message'] != null && (data['message'] == 'SUCCESS' || data['message'] == 'success'))) {
          return true;
        }
      } else {
        print('AamarPayPaymentService ERROR: verify failed status=${response.statusCode} body=${response.body}');
      }
      return false;
    } catch (e) {
      print('AamarPayPaymentService ERROR: Exception during verifyPayment: $e');
      return false;
    }
  }

  /// Open the Aamarpay hosted url in a WebView and watch navigation for success/failure/cancel.
  Future<void> openPaymentGateway({
    required BuildContext context,
    required String paymentUrl,
    required String type, // pass through so we can call verify (credit|go_pro)
    required String planName,
    String? authToken,
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

            final lower = url.toLowerCase();
            // Common success redirect path used by the server example
            if (lower.contains('/aj/aamarpay/success') || lower.contains('/aamarpay/success') || lower.contains('mer_txnid=')) {
              // attempt to extract merTxnid and amount
              String merTxnid = '';
              String amount = '';
              try {
                final uri = Uri.parse(url);
                merTxnid = uri.queryParameters['mer_txnid'] ?? uri.queryParameters['tran_id'] ?? uri.queryParameters['mer_txn'] ?? '';
                amount = uri.queryParameters['amount'] ?? uri.queryParameters['price'] ?? '';
              } catch (_) {
                // ignore parse errors
              }

              // If merTxnid missing, we can try to extract numbers from url as fallback
              if (merTxnid.isEmpty) {
                final match = RegExp(r"\d{6,}").firstMatch(url);
                if (match != null) merTxnid = match.group(0) ?? '';
              }

              // Close webview/dialog first
              if (context.mounted) Navigator.of(context).pop();

              // Prefer server-driven verification. Call backend success endpoint to let server finalize and mark user balance/pro.
              verifyPayment(
                merTxnid: merTxnid,
                type: type,
                amount: amount.isNotEmpty ? amount : null,
                payStatus: 'Successful',
                authToken: authToken,
              ).then((isVerified) {
                if (isVerified) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment verified successfully for $planName!'), backgroundColor: Colors.green),
                    );
                  }
                  onSuccess();
                } else {
                  onError('Payment verification failed');
                }
              }).catchError((e) {
                onError('Verification error: $e');
              });
            }

            // failure or cancellation patterns
            else if (lower.contains('/aj/aamarpay/cancel') || lower.contains('fail') || lower.contains('cancel')) {
              // Close webview/dialog
              if (context.mounted) Navigator.of(context).pop();
              onError('Payment cancelled or failed');
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
}
