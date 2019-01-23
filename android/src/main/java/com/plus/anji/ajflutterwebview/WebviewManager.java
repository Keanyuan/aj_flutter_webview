package com.plus.anji.ajflutterwebview;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static android.app.Activity.RESULT_OK;

/**
 * 作者 kean_qi on ${DATA}:20
 */
@TargetApi(1)
public class WebviewManager {
    private final static int FILECHOOSER_RESULTCODE=1;
    private ValueCallback<Uri> mUploadMessage;
    private ValueCallback<Uri[]> mUploadMessageArray;

    @TargetApi(7)
    class ResultHandler {
        public boolean handleResult(int requestCode, int resultCode, Intent intent){
            boolean handled = false;
            if(Build.VERSION.SDK_INT >= 21){
                if(requestCode == FILECHOOSER_RESULTCODE){
                    Uri[] results = null;
                    if(resultCode == Activity.RESULT_OK){
                        String dataString = intent.getDataString();
                        if(dataString != null){
                            results = new Uri[]{ Uri.parse(dataString) };
                        }
                    }
                    if(mUploadMessageArray != null){
                        mUploadMessageArray.onReceiveValue(results);
                        mUploadMessageArray = null;
                    }
                    handled = true;
                }
            }else {
                if (requestCode == FILECHOOSER_RESULTCODE) {
                    Uri result = null;
                    if (resultCode == RESULT_OK && intent != null) {
                        result = intent.getData();
                    }
                    if (mUploadMessage != null) {
                        mUploadMessage.onReceiveValue(result);
                        mUploadMessage = null;
                    }
                    handled = true;
                }
            }
            return handled;
        }
    }


    boolean closed = false;
    WebView webView;
    Activity activity;
    ResultHandler resultHandler;

    WebviewManager(final  Activity activity){
        this.webView = new ObservableWebView(activity);
        this.activity = activity;
        this.resultHandler = new ResultHandler();
        WebViewClient webViewClient = new BrowserClient();
        webView.setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View v, int keyCode, KeyEvent event) {
                if(event.getAction() == KeyEvent.ACTION_DOWN){
                    switch (keyCode){
                        case KeyEvent.KEYCODE_BACK:
                            if (webView.canGoBack()){
                                webView.canGoBack();
                            } else  {
                                close();
                            }
                            return true;
                    }
                }
                return false;
            }
        });

        ((ObservableWebView) webView).setmOnScrollChangedCallback(new ObservableWebView.OnScrollChangedCallback() {
            @Override
            public void onScroll(int x, int y, int oldx, int oldy) {
                Map<String, Object> yDirection = new HashMap<>();
                yDirection.put("yDirection", (double)y);
                AjFlutterWebviewPlugin.channel.invokeMethod("onScrollYChanged", yDirection);
                Map<String, Object> xDirection = new HashMap<>();
                xDirection.put("xDirection", (double)x);
                AjFlutterWebviewPlugin.channel.invokeMethod("onScrollXChanged", xDirection);
            }
        });

        webView.setWebViewClient(webViewClient);

        webView.setWebChromeClient(new WebChromeClient(){
            //The undocumented magic method override
            //Eclipse will swear at you if you try to put @Override here
            // For Android 3.0+
            public void openFileChooser(ValueCallback<Uri> uploadMsg) {

                mUploadMessage = uploadMsg;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("image/*");
                activity.startActivityForResult(Intent.createChooser(i,"File Chooser"), FILECHOOSER_RESULTCODE);

            }

            // For Android 3.0+
            public void openFileChooser( ValueCallback uploadMsg, String acceptType ) {
                mUploadMessage = uploadMsg;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("*/*");
                activity.startActivityForResult(
                        Intent.createChooser(i, "File Browser"),
                        FILECHOOSER_RESULTCODE);
            }

            //For Android 4.1
            public void openFileChooser(ValueCallback<Uri> uploadMsg, String acceptType, String capture){
                mUploadMessage = uploadMsg;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("image/*");
                activity.startActivityForResult( Intent.createChooser( i, "File Chooser" ), FILECHOOSER_RESULTCODE );

            }

            //For Android 5.0+
            public boolean onShowFileChooser(
                    WebView webView, ValueCallback<Uri[]> filePathCallback,
                    FileChooserParams fileChooserParams){
                if(mUploadMessageArray != null){
                    mUploadMessageArray.onReceiveValue(null);
                }
                mUploadMessageArray = filePathCallback;

                Intent contentSelectionIntent = new Intent(Intent.ACTION_GET_CONTENT);
                contentSelectionIntent.addCategory(Intent.CATEGORY_OPENABLE);
                contentSelectionIntent.setType("*/*");
                Intent[] intentArray;
                intentArray = new Intent[0];

                Intent chooserIntent = new Intent(Intent.ACTION_CHOOSER);
                chooserIntent.putExtra(Intent.EXTRA_INTENT, contentSelectionIntent);
                chooserIntent.putExtra(Intent.EXTRA_TITLE, "Image Chooser");
                chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, intentArray);
                activity.startActivityForResult(chooserIntent, FILECHOOSER_RESULTCODE);
                return true;
            }
        });
    }


    void openUrl(
            boolean withJavascript,
            boolean clearCache,
            boolean hidden,
            boolean clearCookies,
            String userAgent,
            String url,
            Map<String, String> headers,
            boolean withZoom,
            boolean withLocalStorage,
            boolean scrollBar,
            boolean supportMultipleWindows,
            boolean appCacheEnabled,
            boolean allowFileURLs
    ){
        webView.getSettings().setJavaScriptEnabled(withJavascript);
        webView.getSettings().setBuiltInZoomControls(withZoom);
        webView.getSettings().setSupportZoom(withZoom);
        webView.getSettings().setDomStorageEnabled(withLocalStorage);
        webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(supportMultipleWindows);

        webView.getSettings().setSupportMultipleWindows(supportMultipleWindows);

        webView.getSettings().setAppCacheEnabled(appCacheEnabled);

        webView.getSettings().setAllowFileAccessFromFileURLs(allowFileURLs);
        webView.getSettings().setAllowUniversalAccessFromFileURLs(allowFileURLs);

        //版本号 > 21
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webView.getSettings().setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
        }

        if (clearCache) {
            clearCache();
        }

        if (hidden) {
            webView.setVisibility(View.INVISIBLE);
        }

        if (clearCookies) {
            clearCookies();
        }

        if (userAgent != null) {
            webView.getSettings().setUserAgentString(userAgent);
        }

        if(!scrollBar){
            webView.setVerticalScrollBarEnabled(false);
        }

        if (headers != null) {
            webView.loadUrl(url, headers);
        } else {
            webView.loadUrl(url);
        }
    }





    //清除cookies
    private void clearCookies() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean aBoolean) {

                }
            });
        } else {
            CookieManager.getInstance().removeAllCookie();
        }
    }

    //清除缓存
    private void clearCache() {
        webView.clearCache(true);
        webView.clearFormData();
    }

    //刷新URL
    void reloadUrl(String url) {
        webView.loadUrl(url);
    }

    //使用JavaScript
    @TargetApi(Build.VERSION_CODES.KITKAT)
    void eval(MethodCall call, final MethodChannel.Result result) {
        String code = call.argument("code");
        webView.evaluateJavascript(code, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                result.success(value);
            }
        });
    }

    //刷新webview
    void reload(MethodCall call, MethodChannel.Result result) {
        if (webView != null) {
            webView.reload();
        }
    }

    //返回
    void back(MethodCall call, MethodChannel.Result result) {
        if (canGoBack()) {
            webView.goBack();
        }
    }

    //下一步
    void forward(MethodCall call, MethodChannel.Result result) {
        if (canGoForward()) {
            webView.goForward();
        }
    }


    //重置layout
    void resize(FrameLayout.LayoutParams params) {
        webView.setLayoutParams(params);
    }
    /**
     * Checks if going back on the Webview is possible.
     */
    boolean canGoBack() {
        if (webView != null && webView.canGoBack()) {
            return  true;
        }
        return false;
    }

    void canGoBack(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> map = new HashMap();
        map.put("canGoBack", canGoBack() ? "1": "0");
        result.success(map);
    }

    void canGoForward(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> map = new HashMap();
        map.put("canForward", canGoForward() ? "1": "0");
        result.success(map);
    }


    /**
     * Checks if going forward on the Webview is possible.
     */
    boolean canGoForward() {
        if (webView != null && webView.canGoForward()) {
            return  true;
        }
        return false;
    }

    //隐藏
    void hide(MethodCall call, MethodChannel.Result result) {
        if (webView != null) {
            webView.setVisibility(View.INVISIBLE);
        }
    }

    //显示
    void show(MethodCall call, MethodChannel.Result result) {
        if (webView != null) {
            webView.setVisibility(View.VISIBLE);
        }
    }

    //停止loading
    void stopLoading(MethodCall call, MethodChannel.Result result){
        if (webView != null){
            webView.stopLoading();
        }
    }


    //关闭
    void close(MethodCall call, MethodChannel.Result result){
        if (webView != null) {
            ViewGroup vg = (ViewGroup) (webView.getParent());
            vg.removeView(webView);
        }
        webView = null;
        if (result != null) {
            result.success(null);
        }
        closed = true;
        AjFlutterWebviewPlugin.channel.invokeMethod("onDestroy", null);
    }

    void close() {
        close(null, null);
    }

}
