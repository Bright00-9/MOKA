import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/api_client.dart';

/// Hosts Paystack's checkout page in a WebView. We never handle card details
/// ourselves — Paystack's hosted page does — which keeps Moka out of PCI-DSS
/// scope entirely. When the page navigates to our callback URL, we stop
/// trusting the URL itself (it can be spoofed/delayed) and poll our own
/// backend for the authoritative payment status instead.
class PaystackCheckoutScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String callbackUrlPrefix; // must match PLATFORM_CALLBACK_URL on the backend

  const PaystackCheckoutScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.callbackUrlPrefix,
  });

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith(widget.callbackUrlPrefix)) {
            _onReachedCallback();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<void> _onReachedCallback() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    // Webhooks can lag a few seconds behind the redirect, so poll briefly
    // rather than declaring success or failure on the first check.
    for (var attempt = 0; attempt < 6; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final res = await ApiClient.instance.client.get('/payments/${widget.reference}/status');
        final status = res.data['status'] as String;
        if (status == 'SUCCESS') {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        if (status == 'FAILED' || status == 'ABANDONED') {
          if (mounted) Navigator.of(context).pop(false);
          return;
        }
      } catch (_) {
        // transient network hiccup — keep polling within the loop
      }
    }
    if (mounted) Navigator.of(context).pop(false); // gave up waiting — surface as "not confirmed yet"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete payment')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_verifying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Confirming payment…', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
