#import "AjFlutterWebviewPlugin.h"
#import "FlutterWebView.h"

@implementation AjFlutterWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    AJWebViewFactory *webviewFactory = [[AJWebViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:webviewFactory withId:@"aj_flutter_webview"];
}
@end
