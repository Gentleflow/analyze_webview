//
//  AnalyzeWebView.swift
//  analyze_webview
//
//  Created by Lxq on 2021/10/14.
//

import Foundation
import WebKit

public class AnalyzeWebView: WKWebView, WKNavigationDelegate, WKUIDelegate{
    
    var resultDeleage : AnalyzeResultDeleage? = nil
    
    var sourceRegex : String? = nil
    
    var myView : UIView? = nil
    
    var timer : Timer? = nil
    
    

    init(frame: CGRect, userAgent:String?, sourceRegex:String?, resultDeleage:AnalyzeResultDeleage?, configuration:WKWebViewConfiguration) {
        
        super.init(frame: frame, configuration: configuration)
        self.resultDeleage = resultDeleage
        self.sourceRegex = sourceRegex
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(40), repeats: false, block: {(timer) in
                self.onResult(result: "请求超时")
            })
        }
        navigationDelegate = self
        uiDelegate = self
        myView = UIView(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView!.autoresizesSubviews = true
        myView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView!.addSubview(self)
        addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        myView!.frame = frame
        if let keyWindow = UIApplication.shared.keyWindow {
            keyWindow.insertSubview(myView!, at: 0)
            keyWindow.sendSubviewToBack(myView!)
        }
        
        print("AnalyzeWebView swift init")
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override public var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            
            self.scrollView.contentInset = UIEdgeInsets.zero;
            if #available(iOS 11, *) {
                // Above iOS 11, adjust contentInset to compensate the adjustedContentInset so the sum will
                // always be 0.
                if (scrollView.adjustedContentInset != UIEdgeInsets.zero) {
                    let insetToAdjust = self.scrollView.adjustedContentInset;
                    scrollView.contentInset = UIEdgeInsets(top: -insetToAdjust.top, left: -insetToAdjust.left,
                                                                bottom: -insetToAdjust.bottom, right: -insetToAdjust.right);
                }
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("AnalyzeWebView swift 开始加载")
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("AnalyzeWebView swift 加载完成 " + webView.url!.absoluteString)
        if sourceRegex == nil || sourceRegex!.isEmpty {
            evaluateJavaScript("document.documentElement.outerHTML"){(data,error) in
                if data != nil{
                    let data = data as! String
                    self.onResult(result: data)
                }
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("AnalyzeWebView swift didFail ")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("AnalyzeWebView swift didFailProvisionalNavigation ")
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("AnalyzeWebView swift didReceive ")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential);
        }else{
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var targetUrl = ""
        let url = navigationAction.request.url
        if url != nil {
            targetUrl = url!.absoluteString
        }
        print("AnalyzeWebView swift decidePolicyFor request \(targetUrl)")
        decisionHandler(.allow)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress = Int(estimatedProgress * 100)
            print("AnalyzeWebView swift 进度\(progress)")
        }
    }
    
    func onResult(result : String) {
        print("AnalyzeWebView swift onResult")
        resultDeleage?.onResult(result: result)
        dispose()
    }
    
    public func dispose() {
        stopLoading()
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeScriptMessageHandler(forName: JAVASCRIPT_BRIDGE_NAME)
        removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress),context: nil)
        self.timer?.invalidate()
        navigationDelegate = nil
        uiDelegate = nil
        removeFromSuperview()
        myView = nil
    }
    
    deinit {
        print("AnalyzeWebView swift deinit")
    }
}

public protocol AnalyzeResultDeleage: NSObjectProtocol {
    func onResult(result:String) -> Void
}
