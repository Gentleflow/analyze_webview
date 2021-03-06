import 'dart:async';

import 'package:flutter/services.dart';

class AnalyzeWebview {
  static const MethodChannel _channel = const MethodChannel('tech.gentleflow.analyze_webview');

  static Future<String> loadUrl(String url, {String userAgent, String sourceRegex}) async {
    if (url == null || url == "") {
      return "请求失败";
    }
    print("AnalyzeWebView  Flutter loadUrl $url");
    Map<String, dynamic> args = Map();
    args["url"] = url;
    args["userAgent"] = userAgent;
    args["sourceRegex"] = sourceRegex;
    final String result = await _channel.invokeMethod('run', args);
    return result;
  }
}
