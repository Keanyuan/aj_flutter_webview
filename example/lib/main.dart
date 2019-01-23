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
  String _url = 'http://www.baidu.com';
//定义webview插件
  final flutterWebViewPlugin = new AJFlutterWebviewPlugin();


  @override
  void initState() {
    super.initState();
    flutterWebViewPlugin.onStateChanged.listen((s){
      print(s.type);
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AJWebviewScaffold(
        appBar: AppBar(
          leading: FlatButton(onPressed: (){
            flutterWebViewPlugin.canGoBack().then((v){
              print(v);
              if(v){
                flutterWebViewPlugin.goBack();
              }
            });
            
          }, child: Icon(Icons.arrow_back_ios, color: Colors.white,)),
          title: Text("title"),
          actions: <Widget>[
            FlatButton(onPressed: (){
              flutterWebViewPlugin.canForward().then((v){
                if(v){
                  flutterWebViewPlugin.goForward();
                }
              });
            }, child: Icon(Icons.arrow_forward_ios, color: Colors.white,))
          ],
        ),
        url: _url,
        withZoom: false,
        withLocalStorage: true,
        withJavascript: true,
        scrollBar: true,
      ),
    );
  }
}
