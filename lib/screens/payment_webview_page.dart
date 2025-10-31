// lib/screens/payment_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/flutterwave_payment_service.dart';

class PaymentWebViewPage extends StatefulWidget {
  final FlutterwavePaymentService service;
  final String paymentUrl;
  final String transactionReference;
  final String planName;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const PaymentWebViewPage({
    Key? key,
    required this.service,
    required this.paymentUrl,
    required this.transactionReference,
    required this.planName,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _acceptVisible = false;
  bool _verifying = false;
  String _transactionIdentifier = '';
  String _mode = 'pro';
  int? _membershipType;
  int? _amount;

  @override
  void initState() {
    super.initState();
    _transactionIdentifier = widget.transactionReference;
    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          // Detect backend redirect to success URL and show Accept button
          try {
            final uri = Uri.parse(url);
            final path = uri.path.toLowerCase();
            if (path.contains('/aj/fluttewave/success') || url.contains('/aj/fluttewave/success') || url.contains('status=successful') || url.contains('tx_ref=')) {
              final qp = uri.queryParameters;
              final txId = qp['transaction_id'] ?? qp['flw_ref'] ?? qp['tx_ref'] ?? qp['txref'] ?? '';
              final mode = qp['mode'] ?? qp['m'] ?? 'pro';
              int? membershipType;
              int? amount;
              if (mode == 'pro') {
                membershipType = int.tryParse(qp['membershipType'] ?? qp['membershiptype'] ?? '');
              } else if (mode == 'credits') {
                amount = int.tryParse(qp['amount'] ?? qp['price'] ?? '');
              }

              String transactionIdentifier = txId;
              if (transactionIdentifier.isEmpty) {
                final all = url;
                final regex = RegExp(r'flw_ref=([^&]+)');
                final m = regex.firstMatch(all);
                if (m != null && m.groupCount >= 1) transactionIdentifier = m.group(1)!;
              }

              if (transactionIdentifier.isEmpty) transactionIdentifier = widget.transactionReference;

              setState(() {
                _acceptVisible = true;
                _transactionIdentifier = transactionIdentifier;
                _mode = mode;
                _membershipType = membershipType;
                _amount = amount;
              });
            }
          } catch (e) {
            // ignore parse errors
            print('PaymentWebViewPage: URL parse error: $e');
          }
        },
        onWebResourceError: (error) {
          widget.onError('Payment page error: ${error.description}');
        },
      ),
    );

    _controller.loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _onAcceptPressed() async {
    setState(() => _verifying = true);
    final ok = await widget.service.verifyTransaction(
      transactionIdentifier: _transactionIdentifier,
      mode: _mode,
      membershipType: _membershipType,
      amount: _amount,
      context: context,
    );
    setState(() => _verifying = false);

    if (ok) {
      widget.onSuccess();
      if (context.mounted) Navigator.of(context).pop();
    } else {
      widget.onError('Payment verification failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 50,
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.onError('Payment cancelled by user');
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text('X', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          widget.onError('Payment closed by user');
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text('X', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WebViewWidget(controller: _controller),
                ),
                const SizedBox(height: 80), // space for accept button area
              ],
            ),

            // Accept button aligned bottom center
            if (_acceptVisible)
              Positioned(
                left: 30,
                right: 30,
                bottom: 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _verifying ? null : _onAcceptPressed,
                  child: _verifying
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
