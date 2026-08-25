import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TradingViewChart extends StatefulWidget {
  final String symbol;
  final bool showControls;
  final Function(String)? onSymbolChanged;

  const TradingViewChart({
    super.key,
    this.symbol = 'FX:GBPCAD',
    this.showControls = true,
    this.onSymbolChanged,
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _lastLoadedSymbol;

  @override
  void initState() {
    super.initState();
    debugPrint('TV_LOG: [${identityHashCode(this)}] initState for: ${widget.symbol}');
  }

  @override
  void dispose() {
    debugPrint('TV_LOG: [${identityHashCode(this)}] dispose CALLED! State is being lost.');
    super.dispose();
  }

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    isInspectable: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    transparentBackground: true,
  );

  @override
  void didUpdateWidget(TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('TV_LOG: [${identityHashCode(this)}] didUpdateWidget. PropSymbol: ${widget.symbol}, LastLoaded: $_lastLoadedSymbol');
    // Only reload if the symbol provided by the parent is DIFFERENT from what we actually have
    if (widget.symbol != _lastLoadedSymbol && widget.symbol != oldWidget.symbol) {
      _lastLoadedSymbol = widget.symbol;
      _webViewController?.loadData(data: _getHtml(widget.symbol));
    }
  }

  String _getHtml(String symbol) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        body, html { margin: 0; padding: 0; height: 100%; width: 100%; background-color: #131722; overflow: hidden; }
        #tradingview_widget { height: 100vh; width: 100vw; }
      </style>
    </head>
    <body>
      <div id="tradingview_widget"></div>
      <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
      <script type="text/javascript">
        var widget = new TradingView.widget({
          "autosize": true,
          "symbol": "$symbol",
          "interval": "60",
          "timezone": "Europe/Istanbul",
          "theme": "dark",
          "style": "1",
          "locale": "tr",
          "toolbar_bg": "#161922",
          "enable_publishing": false,
          "allow_symbol_change": true,
          "hide_top_toolbar": ${!widget.showControls},
          "hide_side_toolbar": ${!widget.showControls},
          "withdateranges": true,
          "save_image": true,
          "details": true,
          "hotlist": true,
          "calendar": true,
          "show_popup_button": false,
          "container_id": "tradingview_widget"
        });

        // Listen for symbol changes and notify Flutter
        widget.onChartReady(function() {
          widget.chart().onSymbolChanged().subscribe(null, function(symbolData) {
            window.flutter_inappwebview.callHandler('onSymbolChanged', symbolData.name);
          });
        });
      </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialData: InAppWebViewInitialData(data: _getHtml(widget.symbol)),
          initialSettings: _settings,
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _lastLoadedSymbol = widget.symbol;

            // Register handler for symbol changes from JS
            controller.addJavaScriptHandler(
              handlerName: 'onSymbolChanged',
              callback: (args) {
                if (args.isNotEmpty && widget.onSymbolChanged != null) {
                  widget.onSymbolChanged!(args[0].toString());
                }
              },
            );
          },
          onLoadStop: (controller, url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.cyan,
            ),
          ),
      ],
    );
  }
}
