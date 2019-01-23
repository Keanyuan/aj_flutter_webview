#import "AjFlutterWebviewPlugin.h"

static NSString *const CHANNEL_NAME = @"aj_flutter_webview";


@interface AjFlutterWebviewPlugin() <WKNavigationDelegate, UIScrollViewDelegate>{
    
    ///是否启用应用程序方案
    BOOL _enableAppScheme;
    ///是否可以放大缩小
    BOOL _enableZoom;
}

@end

@implementation AjFlutterWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
      methodChannelWithName:CHANNEL_NAME
            binaryMessenger:[registrar messenger]];
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    AjFlutterWebviewPlugin* instance = [[AjFlutterWebviewPlugin alloc] initWithViewController:viewController];
    [registrar addMethodCallDelegate:instance channel:channel];
}
- (instancetype)initWithViewController:(UIViewController*)viewController {
    self = [super init];
    if (self) {
        self.viewController = viewController;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"launch" isEqualToString:call.method]) { //构建
        if (!self.webview){
            [self initWebview: call];
        } else {
            [self navigate:call];
        }
        result(nil);
    } else if ([@"close" isEqualToString:call.method]) { //关闭webview
        [self closeWebView];
        result(nil);
    } else if ([@"eval" isEqualToString:call.method]) { //交互
        [self evalJavascript:call completionHandler:^(NSString *response) {
            result(response);
        }];
    } else if ([@"resize" isEqualToString:call.method]) {//重置
        [self resize:call];
        result(nil);
    } else if ([@"reloadUrl" isEqualToString:call.method]) { //重新加载
         [self reloadUrl:call];
        result(nil);
    } else if ([@"show" isEqualToString:call.method]) { //显示
        [self show];
        result(nil);
    } else if ([@"hide" isEqualToString:call.method]) { //隐藏
        [self hide];
        result(nil);
    } else if ([@"stopLoading" isEqualToString:call.method]) { //停止加载
        [self stopLoading];
        result(nil);
    } else if ([@"cleanCookies" isEqualToString:call.method]) { //清除cookies
        [self cleanCookies];
        result(nil);
    } else if ([@"back" isEqualToString:call.method]) { //返回
        [self back];
        result(nil);
    } else if ([@"forward" isEqualToString:call.method]) { //前进
        [self forward];
        result(nil);
    } else if ([@"reload" isEqualToString:call.method]) { //重新加载
        [self reload];
        result(nil);
    } else {
    result(FlutterMethodNotImplemented);
  }
}

//初始化webview
- (void)initWebview:(FlutterMethodCall*)call {
    NSNumber *clearCache = call.arguments[@"clearCache"];
    NSNumber *clearCookies = call.arguments[@"clearCookies"];
    NSNumber *hidden = call.arguments[@"hidden"];
    NSDictionary *rect = call.arguments[@"rect"];
    _enableAppScheme = call.arguments[@"enableAppScheme"];
    NSString *userAgent = call.arguments[@"userAgent"];
    NSNumber *withZoom = call.arguments[@"withZoom"];
    NSNumber *scrollBar = call.arguments[@"scrollBar"];
    
    //是否清除缓存
    if(clearCache != (id)[NSNull null] && [clearCache boolValue]){
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
    //是否清除cookies
    if(clearCookies != (id)[NSNull null] && [clearCookies boolValue]){
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
            
        }];
    }
    
    //保存本地userAgent
    if(userAgent != (id)[NSNull null]){
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : userAgent}];
    }
    
    CGRect rc;
    if(rect != (id)[NSNull null]){
        rc = [self parseRect:rect];
    } else {
        rc = self.viewController.view.bounds;
    }
    
    self.webview = [[WKWebView alloc] initWithFrame:rc];
    self.webview.navigationDelegate = self;
    self.webview.scrollView.delegate = self;
    self.webview.hidden = [hidden boolValue];
    self.webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
    self.webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
    
    _enableZoom = [withZoom boolValue];
    
    [self.viewController.view addSubview:self.webview];
    
    [self navigate:call];
    

}
//跳转webview
- (void)navigate:(FlutterMethodCall*)call {
    if(self.webview != nil){
        NSString *url = call.arguments[@"url"];
        NSNumber *withLocalUrl = call.arguments[@"withLocalUrl"];
        if([withLocalUrl boolValue]){
            NSURL *htmlUrl = [NSURL fileURLWithPath:url isDirectory:false];
            if (@available(iOS 9.0, *)) {
                //允许对URL的读访问
                [self.webview loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
            } else {
                @throw @"not available on version earlier than ios 9.0";
            }
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSDictionary *headers = call.arguments[@"headers"];
            if(headers == nil){
                [request setAllHTTPHeaderFields:headers];
            }
            [self.webview loadRequest:request];
        }
    }
}

//关闭webview
- (void)closeWebView {
    if(self.webview != nil){
        [self.webview stopLoading];
        [self.webview removeFromSuperview];
        self.webview.navigationDelegate = nil;
        
        //flutter 销毁
        [channel invokeMethod:@"onDestroy" arguments:nil];
    }
}

//javascript交互
- (void)evalJavascript:(FlutterMethodCall*)call completionHandler:(void (^_Nullable)(NSString * response))completionHandler {
    if(self.webview != nil){
        NSString *code = call.arguments[@"code"];
        [self.webview evaluateJavaScript:code completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            completionHandler([NSString stringWithFormat:@"%@", response]);
        }];
    } else {
        completionHandler(nil);
    }
}

//重置布局
- (void)resize:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSDictionary *rect = call.arguments[@"rect"];
        CGRect rc = [self parseRect:rect];
        self.webview.frame = rc;
    }
}

//重新加载URL
- (void)reloadUrl:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSString *url = call.arguments[@"url"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.webview loadRequest:request];
    }
}

//显示
- (void)show {
    if (self.webview != nil) {
        self.webview.hidden = false;
    }
}
//隐藏
- (void)hide {
    if (self.webview != nil) {
        self.webview.hidden = true;
    }
}
//停止
- (void)stopLoading {
    if (self.webview != nil) {
        [self.webview stopLoading];
    }
}

//返回
- (void)back {
    if (self.webview != nil) {
        [self.webview goBack];
    }
}

//前进
- (void)forward {
    if (self.webview != nil) {
        [self.webview goForward];
    }
}

//刷新
- (void)reload {
    if (self.webview != nil) {
        [self.webview reload];
    }
}

//清除缓存
- (void)cleanCookies {
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
    }];
}

#pragma mark -- private
- (CGRect)parseRect:(NSDictionary *)rect {
    return CGRectMake([[rect valueForKey:@"left"] doubleValue],
                      [[rect valueForKey:@"top"] doubleValue],
                      [[rect valueForKey:@"width"] doubleValue],
                      [[rect valueForKey:@"height"] doubleValue]);
}




#pragma mark -- WkWebView Delegate
//为导航操作决定策略
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    id data = @{
                @"url" : navigationAction.request.URL.absoluteString,
                @"type" : @"shouldStart",
                @"navigationType" : [NSNumber numberWithInt: navigationAction.navigationType]
                };
    [channel invokeMethod:@"onState" arguments:data];
    
    if(navigationAction.navigationType == WKNavigationTypeBackForward){
        [channel invokeMethod: @"onBackPressed" arguments: nil];
    } else {
        id data = @{@"url" : navigationAction.request.URL.absoluteString};
        [channel invokeMethod:@"onUrlChanged" arguments:data];
    }
    
    if(_enableAppScheme ||
       ([webView.URL.scheme isEqualToString:@"http"] ||
        [webView.URL.scheme isEqualToString:@"https"] ||
        [webView.URL.scheme isEqualToString:@"about"])){
           decisionHandler(WKNavigationActionPolicyAllow);
       } else {
           decisionHandler(WKNavigationActionPolicyCancel);
       }
    
}

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.URL.absoluteString}];
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.URL.absoluteString}];
}

// 开始加载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}

// 为导航响应决定策略
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;
        [channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", response.statusCode], @"url": webView.URL.absoluteString}];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}


#pragma mark -- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //flutter 监听x轴变化值
    id xDirection = @{@"xDirection" : @(scrollView.contentOffset.x)};
    [channel invokeMethod:@"onScrollXChanged" arguments:xDirection];
    
    //flutter 监听y轴变化值
    id yDirection = @{@"yDirection" : @(scrollView.contentOffset.y)};
    [channel invokeMethod:@"onScrollYChanged" arguments:yDirection];
}

//捏合手势
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.pinchGestureRecognizer.isEnabled != _enableZoom) {
        scrollView.pinchGestureRecognizer.enabled = _enableZoom;
    }
}


@end
