package com.plus.anji.ajflutterwebview;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Point;
import android.os.Build;
import android.view.Display;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.widget.FrameLayout;

import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AjFlutterWebviewPlugin */
public class AjFlutterWebviewPlugin {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "aj_flutter_webview", new WebViewFactory(registrar.messenger()));
  }
}