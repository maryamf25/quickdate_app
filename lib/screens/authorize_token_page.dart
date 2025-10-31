import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthorizeTokenPage extends StatefulWidget {
  final String apiLoginId;
  final String clientKey;
  final String mode; // 'SANDBOX' or 'PRODUCTION'

  const AuthorizeTokenPage({Key? key, required this.apiLoginId, required this.clientKey, required this.mode}) : super(key: key);

  @override
  State<AuthorizeTokenPage> createState() => _AuthorizeTokenPageState();
}

class _AuthorizeTokenPageState extends State<AuthorizeTokenPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Flutter', onMessageReceived: (msg) {
        try {
          final data = jsonDecode(msg.message);
          if (data['status'] == 'ready') {
            // provide config
            final cfg = jsonEncode({ 'apiLoginId': widget.apiLoginId, 'clientKey': widget.clientKey, 'mode': widget.mode });
            _controller.runJavaScript('setConfig($cfg);');
          } else if (data['status'] == 'ok') {
            final descriptor = data['dataDescriptor'];
            final value = data['dataValue'];
            Navigator.of(context).pop({'dataDescriptor': descriptor, 'dataValue': value});
          } else if (data['status'] == 'error') {
            setState(() { _error = data['message'] ?? 'tokenization_error'; });
          }
        } catch (e) {
          setState(() { _error = 'Invalid response from webview'; });
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) { setState(() { _loading = false; }); },
      ))
      ..loadFlutterAsset('assets/authorize/accept.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authorize.Net Card')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Positioned(top: 10, left: 10, right: 10, child: Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_error!, style: const TextStyle(color: Colors.red))))),
        ],
      ),
    );
  }
}

