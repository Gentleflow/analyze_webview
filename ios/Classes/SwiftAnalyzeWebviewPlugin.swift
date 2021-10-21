import Flutter
import UIKit

public class SwiftAnalyzeWebviewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tech.gentleflow.analyze_webview", binaryMessenger: registrar.messenger())
    let instance = SwiftAnalyzeWebviewPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "run":
        let params = call.arguments as! [String: Any?]
        run(result: result, params: params)
        break
    default: break
    }
  }
    
    public func run(result: @escaping FlutterResult,params:[String: Any?]){
        let url = params["url"] as! String
        let userAgent = params["userAgent"] as? String
        let sourceRegex = params["sourceRegex"] as? String
        if url == "" {
            result("请求失败")
            return
        }
        
        let webViewManager = AnalyzeWebViewManager.init(userAgent: userAgent, sourceRegex: sourceRegex, flutterResult: result)
        webViewManager.loadUrl(url: url)
        print("AnalyzeWebView swift run end ")
    }
}
