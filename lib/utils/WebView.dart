import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import './GlobalControllers.dart';
import './AppState.dart';
import './Color.dart';

class WebView extends StatefulWidget {
  final String url;
  final void Function()? customLastGoBack;
  const WebView({super.key, required this.url, this.customLastGoBack});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> with WidgetsBindingObserver {
  int loadingPercentage = 0;
  Object? errorLoadingPage;
  late InAppWebViewController controller;
  bool showErrorPage = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
    if (controller != null) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached
        ) {
        controller.pauseTimers();
        if (Platform.isAndroid) {
          controller.android.pause();
        }
      } else {
        controller.resumeTimers();
        if (Platform.isAndroid) {
          controller.android.resume();
        }
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return errorLoadingPage == null
      ? Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(this.widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                cacheEnabled: true,
                supportZoom: true,
                useWideViewPort: false,
              ),
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame ?? false) {
                  setState(() {
                    errorLoadingPage = error.description;
                  });
                }
              },
              onReceivedHttpError: (controller, request, response) {
                if (request.isForMainFrame ?? false) {
                  setState(() {
                    errorLoadingPage = 'HTTP error: ${response.statusCode}';
                  });
                }
              },

              onWebViewCreated: (ctrl) {
                controller = ctrl;
                webViewControllers.add([
                  controller,
                  this.widget.customLastGoBack,
                ]);
              },
              onLoadStart: (ctrl, url) {
                setState(() {
                  loadingPercentage = 0;
                  errorLoadingPage = null;
                });
              },
              onProgressChanged: (ctrl, progress) {
                setState(() {
                  loadingPercentage = progress;
                });
              },
              onLoadStop: (ctrl, url) {
                setState(() {
                  loadingPercentage = 100;
                });
              },
            ),
            if (loadingPercentage < 100)
              const Center(child: CircularProgressIndicator()),
          ],
        )
      : _webviewErrorWidget(context);
  }

  Widget _webviewErrorWidget(BuildContext context) {
    final theme = Theme.of(context);

    String errorMessage = errorLoadingPage?.toString() ?? 'Unknown error';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: LayoutBuilder(builder: (context, constraints) {
          double squareSize = constraints.maxWidth;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: squareSize,
                  height: squareSize,
                  child: Image.asset(
                    'assets/icon/icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Looks Like there's a problem loading the corresponding page.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Try to reload again. Check your modem or router. Disconnect and reconnect to Wi-Fi.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  "Error Message: $errorMessage",
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        errorLoadingPage = null;
                        loadingPercentage = 0;
                      });
                      controller.reload();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      "Reload",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}


