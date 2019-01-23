package com.plus.anji.ajflutterwebview;

import android.annotation.TargetApi;
import android.graphics.Bitmap;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.util.HashMap;
import java.util.Map;

/**
 * 作者 kean_qi on ${DATA}:34 浏览客户端
 */
@TargetApi(23)
public class BrowserClient extends WebViewClient {
    public BrowserClient() {
        super();
    }

    //开始加载
    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
        super.onPageStarted(view, url, favicon);

        Map<String, Object> data = new HashMap<>();
        data.put("url", url);
        data.put("type", "startLoad");
        AjFlutterWebviewPlugin.channel.invokeMethod("onState", data);
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        super.onPageFinished(view, url);

        Map<String, Object> data = new HashMap<>();
        data.put("url", url);
        AjFlutterWebviewPlugin.channel.invokeMethod("onUrlChanged", data);
        data.put("type", "finishLoad");
        AjFlutterWebviewPlugin.channel.invokeMethod("onState", data);
    }

    @Override
    public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
        super.onReceivedError(view, request, error);
        Map<String, Object> data = new HashMap<>();
        data.put("url", request.getUrl().toString());
        data.put("code", Integer.toString(error.getErrorCode()));
        AjFlutterWebviewPlugin.channel.invokeMethod("onHttpError", data);
    }

    @Override
    public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
        super.onReceivedHttpError(view, request, errorResponse);
        Map<String, Object> data = new HashMap<>();
        data.put("url", request.getUrl().toString());
        data.put("code", Integer.toString(errorResponse.getStatusCode()));
        AjFlutterWebviewPlugin.channel.invokeMethod("onHttpError", data);
    }
}
