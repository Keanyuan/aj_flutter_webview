import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:aj_flutter_webview/aj_flutter_webview.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final Completer<WebViewController> _controller = Completer<WebViewController>();
  static const platform = const MethodChannel('flutter_get_html');

  String localHtml = "";
  @override
  void initState() {
    super.initState();
    _getPlatformVersion();
  _controller.future.then((controller){
    print("controller");
    controller.onStateChanged.listen((state){
      print(state.type);
    });

    controller.onHttpError.listen((error){
      print(error.code);
    });

    controller.onUrlChanged.listen((url){
      print(url);
    });

  });

  }

  //调用对应方法
  _getPlatformVersion() async {
    String localHtmlData;

    try {
      //invoke Method 获取定义调用方法名
      if(Platform.isIOS){
        final localHtml = await platform.invokeMethod( 'getLocalHtml' );
        print(localHtml);

        localHtmlData = '$localHtml';
      }

    } on PlatformException catch (e) {
      print( "错误 $e" );
    }
    setState( () {
      localHtml = localHtmlData;
    } );
  }

  @override
  Widget build(BuildContext context) {
//    if(localHtml.length == 0){
//      return MaterialApp(home: Scaffold(
//        appBar: AppBar(title: Text("hhh")),
//        body: CircularProgressIndicator(),
//      ),);
//    }

    return MaterialApp(home: Scaffold(
      appBar: AppBar(
        title: const Text("http://www.baidu.com"),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: (){
                _controller.future.then((controller){
                  controller.goBack();
                  //              controller.currentUrl().then((v){
                  //                print(v);
                  //              });

                });
              }
          ),
          IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: (){
                _controller.future.then((controller){
//                  controller.loadUrl("https://www.taobao.com");
                print(localHtml);
//                if(localHtml.length > 0){
//                  controller.loadLoacalUrl(localHtml);
//
//                }
                  controller.loadLoacalUrl("file:///android_asset/html/NotFindPage.html");

                  //  file:///android_asset/html/NotFindPage.html


                });
              }
           ),
        ],
      ),
      body: AJWebview(
        initialUrl: "http://www.baidu.com",
        javascriptMode: JavascriptMode.unrestricted,
        withLocalUrl: false,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
      ),),
//      floatingActionButton: favoriteButton(),
    );
//
//    return MaterialApp(
//      home: AJWebviewScaffold(
//        appBar: AppBar(
//          leading: FlatButton(onPressed: (){
//            flutterWebViewPlugin.canGoBack().then((v){
//              print(v);
//              if(v){
//                flutterWebViewPlugin.goBack();
//              }
//            });
//
//          }, child: Icon(Icons.arrow_back_ios, color: Colors.white,)),
//          title: Text("title"),
//          actions: <Widget>[
//            FlatButton(onPressed: (){
//              flutterWebViewPlugin.canForward().then((v){
//                if(v){
//                  flutterWebViewPlugin.goForward();
//                }
//              });
//            }, child: Icon(Icons.arrow_forward_ios, color: Colors.white,))
//          ],
//        ),
//        url: _url,
//        withZoom: false,
//        withLocalStorage: true,
//        withJavascript: true,
//        scrollBar: true,
//      ),
//    );
  }
}
