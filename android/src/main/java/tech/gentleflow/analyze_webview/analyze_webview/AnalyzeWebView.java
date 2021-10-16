package tech.gentleflow.analyze_webview.analyze_webview;

import android.content.Context;
import android.net.http.SslError;
import android.text.TextUtils;
import android.util.Log;
import android.webkit.SslErrorHandler;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.apache.commons.text.StringEscapeUtils;

/**
 * @Description:
 * @Author: Lxq
 * @Date: 10/14/21
 */
class AnalyzeWebView extends WebView {

    static String JS = "document.documentElement.outerHTML";

    private ResultListener mResultListener;

    public AnalyzeWebView(Context context, String userAgent, final String sourceRegex) {
        super(context);

        Log.e("AnalyzeWebView", "init");

        WebSettings settings = getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setBlockNetworkImage(true);
        settings.setUserAgentString(userAgent);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        setWebViewClient(new WebViewClient() {

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                Log.e("AnalyzeWebView", "onPageFinished");
                if (TextUtils.isEmpty(sourceRegex)) {
                    evaluateJavascript(JS, new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String value) {
                            String content = StringEscapeUtils.unescapeJson(value)
                                    .replace("^\"|\"$", "");
                            if (mResultListener != null) {
                                mResultListener.onResult(content);
                            }
                        }
                    });
                }
            }

            @Override
            public void onLoadResource(WebView view, String url) {
                super.onLoadResource(view, url);
                Log.e("AnalyzeWebView", "onLoadResource " + url);
                if (!TextUtils.isEmpty(sourceRegex)) {
                    if (url.matches(sourceRegex)) {
                        if (mResultListener != null) {
                            mResultListener.onResult(url);
                        }
                    }
                }
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                Log.e("AnalyzeWebView", "onReceivedError " + request.getUrl() + " :" + error);
            }

            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                super.onReceivedSslError(view, handler, error);
                Log.e("AnalyzeWebView", "onReceivedSslError " + " :" + error);
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
                super.onReceivedHttpError(view, request, errorResponse);
                Log.e("AnalyzeWebView", "onReceivedError " + request.getUrl() + " :" + errorResponse.getStatusCode());
            }
        });
    }

    public void setResultListener(ResultListener resultListener) {
        mResultListener = resultListener;
    }

    public interface ResultListener {
        void onResult(String result);
    }
}
