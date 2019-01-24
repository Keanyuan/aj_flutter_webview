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

  @override
  void initState() {
    super.initState();
  _controller.future.then((controller){
    print("controller");
    controller.onStateChanged.listen((state){
      print(state.type);
    });

    controller.onHttpError.listen((error){
      print(error.code);
    });


  });
  }


  @override
  Widget build(BuildContext context) {

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
                  controller.loadUrl("https://www.taobao.com");


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
