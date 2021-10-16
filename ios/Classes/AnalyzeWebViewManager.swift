//
//  AnalyzeWebViewManager.swift
//  analyze_webview
//
//  Created by Lxq on 2021/10/15.
//

import Foundation
import WebKit

let JAVASCRIPT_BRIDGE_NAME = "flutter_analyze_webview"

let ON_LOAD_RES_JS = """
(function() {
    var observer = new PerformanceObserver(function(list) {
        list.getEntries().forEach(function(entry) {
                            var url = entry.name;
                            window.webkit.messageHandlers.\(JAVASCRIPT_BRIDGE_NAME).postMessage(url);
        });
    });
    observer.observe({entryTypes: ['resource']});
})();
"""

class AnalyzeWebViewManager:NSObject,AnalyzeResultDeleage, WKScriptMessageHandler{
    
    var flutterResult: FlutterResult? = nil
    
    var webView : AnalyzeWebView? = nil
    
    var session :URLSession? = nil
    
    var holdUrlSchemeTasks : [Int : URLSessionDataTask] = [:]
    
    var sourceRegex : String? = nil
    
    var isDisopse = false
    
    init(userAgent:String?, sourceRegex:String?, flutterResult: @escaping FlutterResult) {
        super.init()
        self.session = URLSession.init(configuration: URLSessionConfiguration.default)
        self.flutterResult = flutterResult
        self.sourceRegex = sourceRegex
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.processPool = WKProcessPoolManager.sharedProcessPool
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.minimumFontSize = 9.0
        
        configuration.userContentController.add(self,name: JAVASCRIPT_BRIDGE_NAME)
        configuration.userContentController.addUserScript(WKUserScript.init(source: ON_LOAD_RES_JS, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        webView = AnalyzeWebView.init(frame: CGRect.init(x: 0, y: 0, width: 1080, height: 1280), userAgent: userAgent, sourceRegex: sourceRegex, resultDeleage: self, configuration:configuration)
    
    }
    
    func loadUrl(url:String) {
        webView?.load(URLRequest.init(url: URL.init(string: url)!))
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("AnalyzeWebViewManager userContentController didReceive \(message.name) \(message.body)")
        if message.name == JAVASCRIPT_BRIDGE_NAME {
            if sourceRegex != nil && !sourceRegex!.isEmpty {
                let url = message.body as! String
                let regex = try? NSRegularExpression(pattern: sourceRegex!, options: []);
                if let matchs = regex?.matches(in: url, options: [], range: NSRange.init(location: 0, length: url.count)){
                    if !matchs.isEmpty {
                        self.webView?.onResult(result: url)
                    }
                }
            }
        }
    }

    
    func onResult(result: String) {
        print("AnalyzeWebViewManager onResult")
        holdUrlSchemeTasks.forEach { key,task in
            task.cancel()
        }
        holdUrlSchemeTasks.removeAll()
        session?.finishTasksAndInvalidate()
        session = nil
        isDisopse = true
        flutterResult?(result)
        webView = nil
    }
}
