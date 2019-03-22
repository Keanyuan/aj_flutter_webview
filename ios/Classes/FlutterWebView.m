//
//  FlutterWebView.m
//  Pods
//
//  Created by kean_qi on 2019/1/24.
//

#import "FlutterWebView.h"

@implementation AJWebViewFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    AJWebViewController* webviewController = [[AJWebViewController alloc] initWithFrame:frame
                                                                           viewIdentifier:viewId
                                                                                arguments:args
                                                                          binaryMessenger:_messenger];
    return webviewController;
}

@end

@interface AJWebViewController() <WKNavigationDelegate, UIScrollViewDelegate>
@end
@implementation AJWebViewController {
    WKWebView* _webView;
    int64_t _viewId;
    FlutterMethodChannel* _channel;
    NSString* _currentUrl;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    if ([super init]) {
        _viewId = viewId;
        _webView = [[WKWebView alloc] initWithFrame:frame];
        _webView.navigationDelegate = self;
        NSString* channelName = [NSString stringWithFormat:@"aj_flutter_webview_%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
        }];
        NSDictionary<NSString*, id>* settings = args[@"settings"];
        [self applySettings:settings];
        NSString* initialUrl = args[@"initialUrl"];
        if (initialUrl && ![initialUrl isKindOfClass:[NSNull class]]) {
            [self loadInitArguments:args];
        }
    }
    return self;
}

- (UIView*)view {
    return _webView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([[call method] isEqualToString:@"updateSettings"]) {
        [self onUpdateSettings:call result:result];
    } else if ([[call method] isEqualToString:@"loadUrl"]) {
        [self onLoadUrl:call result:result];
    } else if ([[call method] isEqualToString:@"loadLoacalUrl"]) {
        [self loadLoacalUrl:call result:result];
    } else if ([[call method] isEqualToString:@"canGoBack"]) {
        [self onCanGoBack:call result:result];
    } else if ([[call method] isEqualToString:@"canGoForward"]) {
        [self onCanGoForward:call result:result];
    } else if ([[call method] isEqualToString:@"goBack"]) {
        [self onGoBack:call result:result];
    } else if ([[call method] isEqualToString:@"goForward"]) {
        [self onGoForward:call result:result];
    } else if ([[call method] isEqualToString:@"reload"]) {
        [self onReload:call result:result];
    } else if ([[call method] isEqualToString:@"currentUrl"]) {
        [self onCurrentUrl:call result:result];
    } else if ([[call method] isEqualToString:@"evaluateJavascript"]) {
        [self onEvaluateJavaScript:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)onUpdateSettings:(FlutterMethodCall*)call result:(FlutterResult)result {
    [self applySettings:[call arguments]];
    result(nil);
}

- (void)onLoadUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* url = [call arguments];
    if (![self loadUrl:url]) {
        result([FlutterError errorWithCode:@"loadUrl_failed"
                                   message:@"Failed parsing the URL"
                                   details:[NSString stringWithFormat:@"URL was: '%@'", url]]);
    } else {
        result(nil);
    }
}

- (void)loadLoacalUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* url = [call arguments];
    if (![self loadLoacalUrl:url]) {
        result([FlutterError errorWithCode:@"loadUrl_failed"
                                   message:@"Failed parsing the URL"
                                   details:[NSString stringWithFormat:@"URL was: '%@'", url]]);
    } else {
        result(nil);
    }
}



- (void)onCanGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
    BOOL canGoBack = [_webView canGoBack];
    result([NSNumber numberWithBool:canGoBack]);
}

- (void)onCanGoForward:(FlutterMethodCall*)call result:(FlutterResult)result {
    BOOL canGoForward = [_webView canGoForward];
    result([NSNumber numberWithBool:canGoForward]);
}

- (void)onGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_webView goBack];
    result(nil);
}

- (void)onGoForward:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_webView goForward];
    result(nil);
}

- (void)onReload:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_webView reload];
    result(nil);
}

- (void)onCurrentUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
    _currentUrl = [[_webView URL] absoluteString];
    result(_currentUrl);
}

- (void)onEvaluateJavaScript:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* jsString = [call arguments];
    if (!jsString) {
        result([FlutterError errorWithCode:@"evaluateJavaScript_failed"
                                   message:@"JavaScript String cannot be null"
                                   details:nil]);
        return;
    }
    [_webView evaluateJavaScript:jsString
               completionHandler:^(_Nullable id evaluateResult, NSError* _Nullable error) {
                   if (error) {
                       result([FlutterError
                               errorWithCode:@"evaluateJavaScript_failed"
                               message:@"Failed evaluating JavaScript"
                               details:[NSString stringWithFormat:@"JavaScript string was: '%@'\n%@",
                                        jsString, error]]);
                   } else {
                       result([NSString stringWithFormat:@"%@", evaluateResult]);
                   }
               }];
}


- (void)applySettings:(NSDictionary<NSString*, id>*)settings {
    for (NSString* key in settings) {
        if ([key isEqualToString:@"jsMode"]) {
            NSNumber* mode = settings[key];
            [self updateJsMode:mode];
        } else {
            NSLog(@"webview_flutter: unknown setting key: %@", key);
        }
    }
}

- (void)updateJsMode:(NSNumber*)mode {
    WKPreferences* preferences = [[_webView configuration] preferences];
    switch ([mode integerValue]) {
        case 0:  // disabled
            [preferences setJavaScriptEnabled:NO];
            break;
        case 1:  // unrestricted
            [preferences setJavaScriptEnabled:YES];
            break;
        default:
            NSLog(@"webview_flutter: unknown JavaScript mode: %@", mode);
    }
}

- (bool)loadInitArguments:(id _Nullable)arguments{
    NSString* initialUrl = arguments[@"initialUrl"];
    NSNumber *withLocalUrl = arguments[@"withLocalUrl"];

    if (initialUrl.length == 0) {
        return false;
    }
    if([withLocalUrl boolValue]){
        NSURL *htmlUrl = [NSURL fileURLWithPath:initialUrl];
        if (@available(iOS 9.0, *)) {
            [_webView loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
        } else {
            // Fallback on earlier versions
            @throw @"not available on version earlier than ios 9.0";
        }
    } else {

        NSURL* nsUrl = [NSURL URLWithString:initialUrl];
        NSURLRequest* req = [NSURLRequest requestWithURL:nsUrl];
        [_webView loadRequest:req];
    }
    
    
    return true;
}


- (bool)loadLoacalUrl:(NSString*)url {
    if (url.length == 0) {
        return false;
    }
    NSURL *htmlUrl = [NSURL fileURLWithPath:url];
    if (@available(iOS 9.0, *)) {
        [_webView loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
    } else {
        // Fallback on earlier versions
        @throw @"not available on version earlier than ios 9.0";
    }
    return true;
}
- (bool)loadUrl:(NSString*)url {
    NSURL* nsUrl = [NSURL URLWithString:url];
    if (!nsUrl) {
        return false;
    }
    NSURLRequest* req = [NSURLRequest requestWithURL:nsUrl];
    [_webView loadRequest:req];
    return true;
}

#pragma mark -- WkWebView Delegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [_channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.URL.absoluteString}];
}
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    id data = @{
                @"url" : navigationAction.request.URL.absoluteString,
                @"type" : @"shouldStart",
                @"navigationType" : [NSNumber numberWithInt: navigationAction.navigationType]
                };
    [_channel invokeMethod:@"onState" arguments:data];
    
    if(navigationAction.navigationType != WKNavigationTypeBackForward){
        id data = @{@"url" : navigationAction.request.URL.absoluteString};
        [_channel invokeMethod:@"onUrlChanged" arguments:data];
        
    }
    decisionHandler(WKNavigationActionPolicyAllow);

    
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.URL.absoluteString}];
    [_channel invokeMethod:@"onTitleChange" arguments:@{@"title": webView.title}];
}


// 开始加载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [_channel invokeMethod:@"onState" arguments:@{@"type": @"loadFaild", @"url": webView.URL.absoluteString}];
    [_channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}

// // 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;
        [_channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", response.statusCode], @"url": webView.URL.absoluteString}];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{return nil;}


@end
