/*
 * CarPlayVideoEnabler - 独立注入版本 (不依赖 Substrate)
 *
 * 编译方法:
 *   SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
 *   clang -arch arm64 -isysroot "$SDK_PATH" \
 *     -miphoneos-version-min=14.0 -dynamiclib -fobjc-arc \
 *     -framework Foundation -framework UIKit -framework CoreLocation \
 *     -o CarPlayVideoEnabler.dylib \
 *     CarPlayVideoEnabler_standalone.m
 *
 *   然后用 ldid 签名:
 *   ldid -S CarPlayVideoEnabler.dylib
 *
 * 使用方式:
 *   TrollFools 注入到目标 App (YouTube, Netflix, Safari 等)
 *   或通过 E-Sign/Feather 注入 IPA 后签名安装
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - 方法替换工具宏

#define SWIZZLE_INSTANCE_METHOD(cls, sel, block) do { \
    Method m = class_getInstanceMethod(cls, sel); \
    if (!m) break; \
    IMP newImp = imp_implementationWithBlock(block); \
    if (!newImp) break; \
    method_setImplementation(m, newImp); \
} while(0)

#define SWIZZLE_CLASS_METHOD(cls, sel, block) do { \
    Method m = class_getClassMethod(cls, sel); \
    if (!m) break; \
    IMP newImp = imp_implementationWithBlock(block); \
    if (!newImp) break; \
    method_setImplementation(m, newImp); \
} while(0)

#pragma mark - Hook 实现

static void setupHooks(void) {
    // ---- CARSession 速度绕过 ----
    Class clsCARSession = objc_getClass("CARSession");
    if (clsCARSession) {
        SWIZZLE_INSTANCE_METHOD(clsCARSession, @selector(currentSpeed), ^double(id self) {
            return 0.0;
        });
        SWIZZLE_INSTANCE_METHOD(clsCARSession, @selector(isVehicleMoving), ^BOOL(id self) {
            return NO;
        });
        SWIZZLE_INSTANCE_METHOD(clsCARSession, @selector(isSuspended), ^BOOL(id self) {
            return NO;
        });
        NSLog(@"[CarPlayVideoEnabler] CARSession hooked");
    }

    // ---- CARSessionStatus 速度绕过 ----
    Class clsCARSessionStatus = objc_getClass("CARSessionStatus");
    if (clsCARSessionStatus) {
        SWIZZLE_INSTANCE_METHOD(clsCARSessionStatus, @selector(vehicleSpeed), ^double(id self) {
            return 0.0;
        });
        NSLog(@"[CarPlayVideoEnabler] CARSessionStatus hooked");
    }

    // ---- CARSessionConfiguration 视频解锁 ----
    Class clsCARSessionConfig = objc_getClass("CARSessionConfiguration");
    if (clsCARSessionConfig) {
        SWIZZLE_INSTANCE_METHOD(clsCARSessionConfig, @selector(allowsVideoPlayback), ^BOOL(id self) {
            return YES;
        });
        NSLog(@"[CarPlayVideoEnabler] CARSessionConfiguration hooked");
    }

    // ---- CRVehicleAccessoryManager 速度绕过 ----
    Class clsCRVehicle = objc_getClass("CRVehicleAccessoryManager");
    if (clsCRVehicle) {
        SWIZZLE_INSTANCE_METHOD(clsCRVehicle, @selector(vehicleSpeed), ^double(id self) {
            return 0.0;
        });
        NSLog(@"[CarPlayVideoEnabler] CRVehicleAccessoryManager hooked");
    }

    // ---- CLLocation 速度绕过 (兜底策略) ----
    SWIZZLE_INSTANCE_METHOD([CLLocation class], @selector(speed), ^CLLocationSpeed(id self) {
        return 0.0;
    });
    NSLog(@"[CarPlayVideoEnabler] CLLocation.speed hooked");

    NSLog(@"[CarPlayVideoEnabler] All hooks installed successfully");
}

#pragma mark - 自动初始化

__attribute__((constructor))
static void carPlayVideoEnabler_init(void) {
    @autoreleasepool {
        setupHooks();
    }
}
