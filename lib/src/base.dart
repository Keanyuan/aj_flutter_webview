

import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

const _kChannel = 'aj_flutter_webview';

// TODO: more general state for iOS/android
enum WebViewState { shouldStart, startLoad, finishLoad }

class AJFlutterWebviewPlugin {
  factory AJFlutterWebviewPlugin() => _instance ??= AJFlutterWebviewPlugin._();

  final _channel = const MethodChannel(_kChannel);

  static AJFlutterWebviewPlugin _instance;

  AJFlutterWebviewPlugin._() {
    _channel.setMethodCallHandler(_handleMessages);
  }

  final _onDestroy = StreamController<Null>.broadcast();
  final _onUrlChanged = StreamController<String>.broadcast();
  final _onStateChanged = StreamController<WebViewStateChanged>.broadcast();
  final _onScrollXChanged = StreamController<double>.broadcast();
  final _onScrollYChanged = StreamController<double>.broadcast();
  final _onHttpError = StreamController<WebViewHttpError>.broadcast();

  //处理监听消息
  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onDestroy':
        _onDestroy.add(null);
        break;
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onScrollXChanged':
        _onScrollXChanged.add(call.arguments['xDirection']);
        break;
      case 'onScrollYChanged':
        _onScrollYChanged.add(call.arguments['yDirection']);
        break;
      case 'onState':
        _onStateChanged.add(WebViewStateChanged.fromMap(Map<String, dynamic>.from(call.arguments)));
        break;
      case 'onHttpError':
        _onHttpError.add(WebViewHttpError(call.arguments['code'], call.arguments['url']));
        break;
    }
  }


  //销毁
  Stream<Null> get onDestroy => _onDestroy.stream;

  //url改变通知
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  //请求状态改变
  Stream<WebViewStateChanged> get onStateChanged => _onStateChanged.stream;

  //横轴改变
  Stream<double> get onScrollXChanged => _onScrollXChanged.stream;

  //纵轴改变
  Stream<double> get onScrollYChanged => _onScrollYChanged.stream;

  //请求错误通知
  Stream<WebViewHttpError> get onHttpError => _onHttpError.stream;

  Future<Null> launch(String url, {
    Map<String, String> headers, //webview头部添加信息
    bool withJavascript, //是否使用Javascript
    bool clearCache, //是否清除缓存
    bool clearCookies, //是否清除cookies
    bool hidden, //是否隐藏
    bool enableAppScheme, //是否启动
    Rect rect, //坐标
    String userAgent,//用户代理
    bool withZoom,//是否开启缩放
    bool withLocalStorage,//是否使用本地存储
    bool withLocalUrl,//是否是本地URL
    bool scrollBar,//是否显示滑动条
    bool supportMultipleWindows,//是否支持多窗口
    bool appCacheEnabled,//是否使用缓存
    bool allowFileURLs,//是否运行文件URL
  })async{
    final args = <String, dynamic>{
      'url' : url,
      'withJavascript': withJavascript ?? true,
      'clearCache': clearCache ?? false,
      'hidden': hidden ?? false,
      'clearCookies': clearCookies ?? false,
      'enableAppScheme': enableAppScheme ?? true,
      'userAgent': userAgent,
      'withZoom': withZoom ?? false,
      'withLocalStorage': withLocalStorage ?? true,
      'withLocalUrl': withLocalUrl ?? false,
      'scrollBar': scrollBar ?? true,
      'supportMultipleWindows': supportMultipleWindows ?? false,
      'appCacheEnabled': appCacheEnabled ?? false,
      'allowFileURLs': allowFileURLs ?? false,
    };
    if (headers != null) {
      args['headers'] = headers;
    }

    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    }

    await _channel.invokeMethod('launch', args);

  }

  Future<String> evalJavascript(String code) async {
    final res = await _channel.invokeMethod('eval', {'code': code});
    return res;
  }

  Future<bool> canGoBack() async {
    final res = await _channel.invokeMethod('canGoBack');
    Map r = res;
    print(r);
    return r["canGoBack"] == "1" ? true : false;
  }

  Future<bool> canForward() async {
    final res = await _channel.invokeMethod('canForward');
    Map r = res;
    return r["canForward"] == "1" ? true : false;
  }

  ///关闭webview
  Future<Null> close() async => await _channel.invokeMethod('close');
  ///刷新webview
  Future<Null> reload() async => await _channel.invokeMethod('reload');
  ///返回上一页webview
  Future<Null> goBack() async => await _channel.invokeMethod('back');
  ///跳转下一页webview
  Future<Null> goForward() async => await _channel.invokeMethod('forward');
  ///隐藏webview
  Future<Null> hide() async => await _channel.invokeMethod('hide');
  ///显示webview
  Future<Null> show() async => await _channel.invokeMethod('show');
  ///清除webview cookies
  Future<Null> cleanCookies() async => await _channel.invokeMethod('cleanCookies');
  ///停止加载webview
  Future<Null> stopLoading() async => await _channel.invokeMethod('stopLoading');

  //重置URL
  Future<Null> reloadUrl(String url) async {
    final args = <String, String>{'url': url};
    await _channel.invokeMethod('reloadUrl', args);
  }

  //释放资源
  void dispose() {
    _onDestroy.close();
    _onUrlChanged.close();
    _onStateChanged.close();
    _onScrollXChanged.close();
    _onScrollYChanged.close();
    _onHttpError.close();
    _instance = null;
  }

  ///获取cookies
  Future<Map<String, String>> getCookies() async {
    final cookiesString = await evalJavascript('document.cookie');
    final cookies = <String, String>{};

    if (cookiesString?.isNotEmpty == true) {
      cookiesString.split(';').forEach((String cookie) {
        final split = cookie.split('=');
        cookies[split[0]] = split[1];
      });
    }

    return cookies;
  }

  //重置大小
  Future<Null> resize(Rect rect) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
    await _channel.invokeMethod('resize', args);
  }

}

//加载类型
class WebViewStateChanged {
  WebViewStateChanged(this.type, this.url, this.navigationType);
  factory WebViewStateChanged.fromMap(Map<String, dynamic> map) {
    WebViewState t;
    switch (map['type']) {
      case 'shouldStart':
        t = WebViewState.shouldStart;
        break;
      case 'startLoad':
        t = WebViewState.startLoad;
        break;
      case 'finishLoad':
        t = WebViewState.finishLoad;
        break;
    }
    return WebViewStateChanged(t, map['url'], map['navigationType']);
  }

  final WebViewState type;
  final String url;
  final int navigationType;
}


//错误类型
class WebViewHttpError {
  WebViewHttpError(this.code, this.url);

  final String url;
  final String code;
}