package tech.gentleflow.analyze_webview.analyze_webview;

import android.content.Context;
import android.net.http.SslError;
import android.os.Handler;
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

    private final String mSourceRegex;

    private ResultListener mResultListener;
    private Runnable mTimeoutRunnable;
    private Handler mHandler;

    private int mEvaluateJsCount = 0;

    public AnalyzeWebView(Context context, String userAgent, String sourceRegex) {
        super(context);

        Log.e("AnalyzeWebView", "init");

        this.mSourceRegex = sourceRegex;

        mHandler = new Handler();

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
                if (TextUtils.isEmpty(mSourceRegex)) {
                    evaluateGetHtml();
                }
            }

            @Override
            public void onLoadResource(WebView view, String url) {
                super.onLoadResource(view, url);
//                Log.e("AnalyzeWebView", "onLoadResource " + url);
                if (!TextUtils.isEmpty(mSourceRegex)) {
                    if (url.matches(mSourceRegex)) {
                        onResult(url);
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

    @Override
    public void loadUrl(String url) {
        super.loadUrl(url);
        mTimeoutRunnable = new Runnable() {
            @Override
            public void run() {
                Log.e("AnalyzeWebView", "mTimeoutRunnable");
                mTimeoutRunnable = null;
                if (TextUtils.isEmpty(mSourceRegex)) {
                    evaluateGetHtml();
                } else {
                    onResult("请求失败");
                }
            }
        };
        mHandler.postDelayed(mTimeoutRunnable, 30 * 1000);
        Log.e("AnalyzeWebView", "loadUrl");
    }

    private void evaluateGetHtml() {
        mHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                mEvaluateJsCount++;
                Log.e("AnalyzeWebView", "evaluateGetHtml" + mEvaluateJsCount);
                evaluateJavascript(JS, new ValueCallback<String>() {
                    @Override
                    public void onReceiveValue(String value) {
                        String content = StringEscapeUtils.unescapeJson(value)
                                .replace("^\"|\"$", "");
                        if (TextUtils.isEmpty(content)) {
                            if (mEvaluateJsCount >= 10) {
                                onResult("请求失败");
                            } else {
                                evaluateGetHtml();
                            }
                        } else {
                            onResult(content);
                        }
                    }
                });
            }
        }, 1000);
    }

    private void onResult(String result) {
        if (mResultListener != null) {
            mResultListener.onResult(result);
        }
    }

    @Override
    public void destroy() {
        mHandler.removeCallbacksAndMessages(null);
        mHandler = null;
        stopLoading();
        super.destroy();
    }

    public void setResultListener(ResultListener resultListener) {
        mResultListener = resultListener;
    }

    public interface ResultListener {
        void onResult(String result);
    }
}
