//
//  WKURLSchemeHandler.swift
//  analyze_webview
//
//  Created by Lxq on 2021/10/14.
//

import Flutter
import Foundation
import WebKit

@available(iOS 11.0, *)
class CustomeSchemeHandler : NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int:URLSessionDataTask] = [:]
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url
        print("AnalyzeWebView swift schemeHandlers \(url?.absoluteString)")
        let task = URLSession.shared.dataTask(with: url!){(data,response,error) in
            if let error = error {
                urlSchemeTask.didFailWithError(error)
            }else {
                if let response = response {
                    urlSchemeTask.didReceive(response)
                }
                if let data = data {
                    urlSchemeTask.didReceive(data)
                }
                urlSchemeTask.didFinish()
            }
        }
        task.resume()
        schemeHandlers[urlSchemeTask.hash] = task
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let task = schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
        task?.cancel()
    }
}
