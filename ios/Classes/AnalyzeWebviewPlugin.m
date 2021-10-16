#import "AnalyzeWebviewPlugin.h"
#if __has_include(<analyze_webview/analyze_webview-Swift.h>)
#import <analyze_webview/analyze_webview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "analyze_webview-Swift.h"
#endif

@implementation AnalyzeWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAnalyzeWebviewPlugin registerWithRegistrar:registrar];
}
@end


@interface WKWebView(handlesURLScheme)


@end

@implementation WKWebView(handlesURLScheme)


+ (BOOL)handlesURLScheme:(NSString *)urlScheme
{
    return NO;
}

@end
