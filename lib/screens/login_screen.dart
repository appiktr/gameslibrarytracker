import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/steam_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;

  String _currentUrl = 'https://steamcommunity.com/openid/login';

  @override
  void initState() {
    super.initState();

    final String loginUrl =
        'https://steamcommunity.com/openid/login'
        '?openid.ns=http://specs.openid.net/auth/2.0'
        '&openid.mode=checkid_setup'
        '&openid.return_to=https://www.google.com'
        '&openid.realm=https://www.google.com'
        '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
        '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            if (change.url != null) {
              setState(() => _currentUrl = change.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.google.com')) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  void _handleRedirect(String url) {
    final uri = Uri.parse(url);
    final openIdClaimedId = uri.queryParameters['openid.claimed_id'];

    if (openIdClaimedId != null) {
      // Format: https://steamcommunity.com/openid/id/76561198XXXXXXXXX
      final steamId = openIdClaimedId.split('/').last;

      if (steamId.isNotEmpty) {
        // Pop back to main, which will now show HomeScreen because of Provider update
        Provider.of<SteamProvider>(context, listen: false).login(steamId);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Login to Steam', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                const Icon(Icons.lock, size: 12, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _currentUrl,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
