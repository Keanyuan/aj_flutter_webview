package com.plus.anji.ajflutterwebview;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.File;


import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

import static android.content.ContentValues.TAG;
import static android.database.sqlite.SQLiteDatabase.deleteDatabase;
import static io.flutter.util.PathUtils.getFilesDir;

@TargetApi(23)
public class FlutterWebView implements PlatformView, MethodCallHandler {
  private final WebView webView;
  static MethodChannel methodChannel;

  @SuppressWarnings("unchecked")
  FlutterWebView(Context context, BinaryMessenger messenger, int id, Map<String, Object> params) {
    webView = new WebView(context);
    buildWebView(context);

    if (params.containsKey("initialUrl")) {
      String url = (String) params.get("initialUrl");
      webView.loadUrl(url);
    }


    applySettings((Map<String, Object>) params.get("settings"));
    methodChannel = new MethodChannel(messenger, "aj_flutter_webview_" + id);
    methodChannel.setMethodCallHandler(this);
  }


  private void buildWebView(Context context){
    WebViewClient webViewClient = new BrowserClient();
    webView.setWebViewClient(webViewClient);
    //版本号 > 21
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      webView.getSettings().setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
    }

    WebSettings settings = webView.getSettings();
    settings.setDomStorageEnabled(true);
    settings.setBuiltInZoomControls(true);
    settings.setJavaScriptCanOpenWindowsAutomatically(true);
    settings.setSupportMultipleWindows(true);
    //开启 database storage API 功能
    settings.setAppCacheEnabled(true);
    // 开启 DOM storage API 功能
    settings.setDomStorageEnabled(true);
//    String cacheDirPath = context.getFilesDir().getAbsolutePath()+"/webcache";
    //设置数据库缓存路径
//    settings.setDatabasePath(cacheDirPath);
    //设置  Application Caches 缓存目录
//    settings.setAppCachePath(cacheDirPath);
    //开启 Application Caches 功能
    settings.setAppCacheEnabled(true);

  }

  @Override
  public View getView() {
    return webView;
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case "loadUrl":
        loadUrl(methodCall, result);
        break;
      case "loadLoacalUrl":
        loadUrl(methodCall, result);
        break;
      case "updateSettings":
        updateSettings(methodCall, result);
        break;
      case "canGoBack":
        canGoBack(methodCall, result);
        break;
      case "canGoForward":
        canGoForward(methodCall, result);
        break;
      case "goBack":
        goBack(methodCall, result);
        break;
      case "goForward":
        goForward(methodCall, result);
        break;
      case "reload":
        reload(methodCall, result);
        break;
      case "currentUrl":
        currentUrl(methodCall, result);
        break;
      case "evaluateJavascript":
        evaluateJavaScript(methodCall, result);
        break;
      default:
        result.notImplemented();
    }
  }

  private void loadUrl(MethodCall methodCall, Result result) {
    String url = (String) methodCall.arguments;
    webView.loadUrl(url);
    result.success(null);
  }

  private void canGoBack(MethodCall methodCall, Result result) {
    result.success(webView.canGoBack());
  }

  private void canGoForward(MethodCall methodCall, Result result) {
    result.success(webView.canGoForward());
  }

  private void goBack(MethodCall methodCall, Result result) {
    if (webView.canGoBack()) {
      webView.goBack();
    }
    result.success(null);
  }

  private void goForward(MethodCall methodCall, Result result) {
    if (webView.canGoForward()) {
      webView.goForward();
    }
    result.success(null);
  }

  private void reload(MethodCall methodCall, Result result) {
    webView.reload();
    result.success(null);
  }

  private void currentUrl(MethodCall methodCall, Result result) {
    result.success(webView.getUrl());
  }

  @SuppressWarnings("unchecked")
  private void updateSettings(MethodCall methodCall, Result result) {
    applySettings((Map<String, Object>) methodCall.arguments);
    result.success(null);
  }

  @TargetApi(19)
  private void evaluateJavaScript(MethodCall methodCall, final Result result) {
    String jsString = (String) methodCall.arguments;
    if (jsString == null) {
      throw new UnsupportedOperationException("JavaScript string cannot be null");
    }
    webView.evaluateJavascript(
        jsString,
        new android.webkit.ValueCallback<String>() {
          @Override
          public void onReceiveValue(String value) {
            result.success(value);
          }
        });
  }

  private void applySettings(Map<String, Object> settings) {
    for (String key : settings.keySet()) {
      switch (key) {
        case "jsMode":
          updateJsMode((Integer) settings.get(key));
          break;
        default:
          throw new IllegalArgumentException("Unknown WebView setting: " + key);
      }
    }
  }

  private void updateJsMode(int mode) {
    switch (mode) {
      case 0: // disabled
        webView.getSettings().setJavaScriptEnabled(false);
        break;
      case 1: // unrestricted
        webView.getSettings().setJavaScriptEnabled(true);
        break;
      default:
        throw new IllegalArgumentException("Trying to set unknown JavaScript mode: " + mode);
    }
  }

  @Override
  public void dispose() {}
}
