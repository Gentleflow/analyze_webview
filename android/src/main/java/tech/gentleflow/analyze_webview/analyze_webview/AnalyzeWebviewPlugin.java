package tech.gentleflow.analyze_webview.analyze_webview;

import android.content.Context;
import android.util.ArrayMap;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * AnalyzeWebviewPlugin
 */
public class AnalyzeWebviewPlugin implements FlutterPlugin, MethodCallHandler {

    private MethodChannel channel;
    private Context mContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mContext = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "tech.gentleflow.analyze_webview");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "run":
                HashMap<String, Object> params = (HashMap<String, Object>) call.arguments;
                run(result, params);
                break;
        }
    }

    public void run(final Result result, final HashMap<String, Object> params) {
        String url = (String) params.get("url");
        String userAgent = (String) params.get("userAgent");
        String sourceRegex = (String) params.get("sourceRegex");
        final AnalyzeWebView webView = new AnalyzeWebView(mContext, userAgent, sourceRegex);
        webView.setResultListener(new AnalyzeWebView.ResultListener() {
            @Override
            public void onResult(String resultStr) {
                Log.e("AnalyzeWebView", "run onResult" + resultStr);
                result.success(resultStr);
                webView.destroy();
            }
        });
        webView.loadUrl(url);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
