#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
    
    FlutterViewController *controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel *batteryChannel = [FlutterMethodChannel methodChannelWithName:@"flutter_get_html" binaryMessenger:controller];
    [batteryChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        if([call.method isEqualToString:@"getLocalHtml"]){
//            NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
//            result([NSString stringWithFormat:@"file://%@/html/NotFindPage.html", bundlePath]);
//            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"NotFindPage" ofType:@"html"];
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"NotFindPage" ofType:@"html" inDirectory:@"html"];
            result([NSString stringWithFormat:@"%@", bundlePath]);
        }
    }];
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
