

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

typedef void WebViewCreatedCallback(WebViewController controller);

enum JavascriptMode {
  /// 禁用Javascrip
  disabled,

  /// 不禁用Javascrip.
  unrestricted,
}

class AJWebview extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _WebViewState();
  }


  const AJWebview({
    Key key,
    this.initialUrl,
    this.onWebViewCreated,
    this.javascriptMode = JavascriptMode.unrestricted,
    this.gestureRecognizers,
    this.withLocalUrl = false,
  }) : assert(javascriptMode != null), super(key: key);

  final WebViewCreatedCallback onWebViewCreated;
  final JavascriptMode javascriptMode;
  final String initialUrl;
  ///手势  web视图应该使用哪些手势
  ///如果web视图在[ListView]中，[ListView]将需要处理垂直拖
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool withLocalUrl;

}
class _WebViewState extends State<AJWebview> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();
  
  _WebSettings _settings;


  @override
  Widget build(BuildContext context) {
    if(defaultTargetPlatform == TargetPlatform.android){

      return GestureDetector(
        onLongPress: () {},
        child: AndroidView(
          viewType: 'aj_flutter_webview',
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: widget.gestureRecognizers,
          layoutDirection: TextDirection.rtl,
          creationParams: _CreationParams.fromWidget(widget).toMap(),
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );

    } else if(defaultTargetPlatform == TargetPlatform.iOS){
      
      return UiKitView(
        viewType: "aj_flutter_webview",
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
        creationParams: _CreationParams.fromWidget(widget).toMap(),
        creationParamsCodec: const StandardMessageCodec(),//消息格式
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the aj_flutter_webview plugin');
  }
  
  @override
  void didUpdateWidget(AJWebview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSettings(_WebSettings.fromWidget(widget));
  }

  Future<void> _updateSettings(_WebSettings settings) async {
    _settings = settings;
    final WebViewController controller = await _controller.future;
    controller._updateSettings(settings);
  }

  void _onPlatformViewCreated(int id){
    final WebViewController controller = WebViewController._(id, _WebSettings.fromWidget(widget));
    _controller.complete(controller);
    if(widget.onWebViewCreated != null){
      widget.onWebViewCreated(controller);
    }
  }
}

class _CreationParams {
  _CreationParams({this.initialUrl, this.settings, this.withLocalUrl});
  static _CreationParams fromWidget(AJWebview widget){
    return _CreationParams(
      initialUrl: widget.initialUrl,
      settings: _WebSettings.fromWidget(widget),
      withLocalUrl: widget.withLocalUrl,

    );
  }
  final String initialUrl;
  final _WebSettings settings;
  final bool withLocalUrl;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'initialUrl': initialUrl,
      'settings': settings.toMap(),
      'withLocalUrl': withLocalUrl
    };
  }
}


class WebViewController {
  WebViewController._(int id, _WebSettings settings){
    _channel = MethodChannel('aj_flutter_webview_$id');
    _settings = settings;
    _channel.setMethodCallHandler(_handleMessages);
  }
   MethodChannel _channel;
  _WebSettings _settings;

  final _onUrlChanged = StreamController<String>.broadcast();
  final _onTitleChange = StreamController<String>.broadcast();
  final _onStateChanged = StreamController<WebViewStateChanged>.broadcast();
  final _onHttpError = StreamController<WebViewHttpError>.broadcast();


  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onState':
        _onStateChanged.add(WebViewStateChanged.fromMap(Map<String, dynamic>.from(call.arguments)));
      break;
      case 'onTitleChange':
        _onTitleChange.add(call.arguments['title']);
        break;
      case 'onHttpError':
      _onHttpError.add(WebViewHttpError(call.arguments['code'], call.arguments['url']));
      break;
    }
  }

  //url改变通知
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  Stream<String> get onTitleChange => _onTitleChange.stream;


  //请求状态改变
  Stream<WebViewStateChanged> get onStateChanged => _onStateChanged.stream;

  //请求错误通知
  Stream<WebViewHttpError> get onHttpError => _onHttpError.stream;


  Future<void> _updateSettings(_WebSettings setting) async {
    final Map<String, dynamic> updateMap = _settings.updatesMap(setting);
    if (updateMap == null) {
      return null;
    }
    _settings = setting;
    return _channel.invokeMethod('updateSettings', updateMap);
  }


  Future<void> loadUrl(String url) async {
    assert(url != null);
    _validateUrlString(url);
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<void> loadLoacalUrl(String url) async {
    return _channel.invokeMethod('loadLoacalUrl', url);
  }

  Future<String> currentUrl() async {
    final String url = await _channel.invokeMethod('currentUrl');
    return url;
  }

  Future<bool> canGoBack() async {
    final bool canGoBack = await _channel.invokeMethod("canGoBack");
    return canGoBack;
  }

  Future<bool> canGoForward() async {
    final bool canGoForward = await _channel.invokeMethod("canGoForward");
    return canGoForward;
  }

  Future<void> goBack() async {
    return _channel.invokeMethod("goBack");
  }

  Future<void> goForward() async {
    return _channel.invokeMethod("goForward");
  }

  Future<void> reload() async {
    return _channel.invokeMethod("reload");
  }

  //释放资源
  Future<void> dispose() {
    _onUrlChanged.close();
    _onStateChanged.close();
    _onHttpError.close();
    _onTitleChange.close();
  }







  Future<String> evaluateJavascript(String javascriptString) async {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      throw FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.');
    }
    if (javascriptString == null) {
      throw ArgumentError('The argument javascriptString must not be null. ');
    }
    final String result =
    await _channel.invokeMethod('evaluateJavascript', javascriptString);
    return result;
  }
}


class _WebSettings {
  _WebSettings({
    this.javascriptMode
  });
  static _WebSettings fromWidget(AJWebview widget){
    return _WebSettings(javascriptMode: widget.javascriptMode);
  }
  final JavascriptMode javascriptMode;

  Map<String, dynamic> toMap(){
    return <String, dynamic>{
    'jsMode': javascriptMode.index,
    };
  }

  Map<String, dynamic> updatesMap(_WebSettings newSettings){
    if(javascriptMode == newSettings.javascriptMode){
      return null;
    }
    return <String, dynamic>{
      'jsMode': newSettings.javascriptMode.index,
    };
  }

}

void _validateUrlString(String url) {
  try {
    final Uri uri = Uri.parse(url);
    if (uri.scheme.isEmpty) {
      throw ArgumentError('Missing scheme in URL string: "$url"');
    }
  } on FormatException catch (e) {
    throw ArgumentError(e);
  }
}


enum WebViewState { shouldStart, startLoad, finishLoad, loadFaild}

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
      case 'loadFaild':
        t = WebViewState.loadFaild;
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