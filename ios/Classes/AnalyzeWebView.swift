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
    
    var getHtmlTimer : Timer? = nil
    
    var getHtmlCount = 0

    init(frame: CGRect, userAgent:String?, sourceRegex:String?, resultDeleage:AnalyzeResultDeleage?, configuration:WKWebViewConfiguration) {
        
        super.init(frame: frame, configuration: configuration)
        self.resultDeleage = resultDeleage
        self.sourceRegex = sourceRegex
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(30), repeats: false, block: {(timer) in
                if sourceRegex == nil || sourceRegex!.isEmpty {
                    self.evaluateGetHtml()
                } else {
                    self.onResult(result: "请求失败")
                }
            })
        }
        navigationDelegate = self
        uiDelegate = self
        myView = UIView(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView!.autoresizesSubviews = true
        myView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView!.addSubview(self)
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
            evaluateGetHtml()
        }
    }
    
    func evaluateGetHtml() {
        if #available(iOS 10.0, *){
            self.getHtmlTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: true, block: {(timer) in
                self.evaluateJavaScript("document.documentElement.outerHTML.toString()"){(data,error) in
                    self.getHtmlCount = self.getHtmlCount + 1
                    print("evaluateGetHtml \(self.getHtmlCount)")
                    if data != nil {
                        let data = data as! String
                        if data == "<html><head></head><body></body></html>" {
                            if self.getHtmlCount >= 10 {
                                self.onResult(result: "请求失败")
                            }
                        } else {
                            self.onResult(result: data)
                        }
                    } else {
                        if self.getHtmlCount >= 10 {
                            self.onResult(result: "请求失败")
                        }
                    }
                }
            })
        } else {
            self.evaluateJavaScript("document.documentElement.outerHTML.toString()"){(data,error) in
                if data != nil{
                    let data = data as! String
                    self.onResult(result: data)
                } else {
                    self.onResult(result: "请求失败")
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
    
    func onResult(result : String) {
        print("AnalyzeWebView swift onResult")
        resultDeleage?.onResult(result: result)
        dispose()
    }
    
    public func dispose() {
        stopLoading()
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeScriptMessageHandler(forName: JAVASCRIPT_BRIDGE_NAME)
        self.timer?.invalidate()
        self.getHtmlTimer?.invalidate()
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
