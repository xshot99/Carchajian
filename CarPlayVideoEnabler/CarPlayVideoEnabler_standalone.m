#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define SWIZZLE_INSTANCE_METHOD(cls, sel, block) do { \
    Method m = class_getInstanceMethod(cls, sel); \
    if (!m) break; \
    IMP imp = imp_implementationWithBlock(block); \
    if (!imp) break; \
    method_setImplementation(m, imp); \
} while(0)

static void setupHooks(void) {
    Class CARSession = objc_getClass("CARSession");
    if (CARSession) {
        SWIZZLE_INSTANCE_METHOD(CARSession, @selector(currentSpeed),
            ^double(id _block, id self, SEL _cmd) { return 0.0; });
        SWIZZLE_INSTANCE_METHOD(CARSession, @selector(isVehicleMoving),
            ^BOOL(id _block, id self, SEL _cmd) { return NO; });
        SWIZZLE_INSTANCE_METHOD(CARSession, @selector(isSuspended),
            ^BOOL(id _block, id self, SEL _cmd) { return NO; });
        NSLog(@"[CPVE] CARSession hooked");
    }

    Class CARSessionStatus = objc_getClass("CARSessionStatus");
    if (CARSessionStatus) {
        SWIZZLE_INSTANCE_METHOD(CARSessionStatus, @selector(vehicleSpeed),
            ^double(id _block, id self, SEL _cmd) { return 0.0; });
        NSLog(@"[CPVE] CARSessionStatus hooked");
    }

    Class CARSessionConfiguration = objc_getClass("CARSessionConfiguration");
    if (CARSessionConfiguration) {
        SWIZZLE_INSTANCE_METHOD(CARSessionConfiguration, @selector(allowsVideoPlayback),
            ^BOOL(id _block, id self, SEL _cmd) { return YES; });
        NSLog(@"[CPVE] CARSessionConfiguration hooked");
    }

    Class CRVehicleAccessoryManager = objc_getClass("CRVehicleAccessoryManager");
    if (CRVehicleAccessoryManager) {
        SWIZZLE_INSTANCE_METHOD(CRVehicleAccessoryManager, @selector(vehicleSpeed),
            ^double(id _block, id self, SEL _cmd) { return 0.0; });
        NSLog(@"[CPVE] CRVehicleAccessoryManager hooked");
    }

    SWIZZLE_INSTANCE_METHOD([CLLocation class], @selector(speed),
        ^CLLocationSpeed(id _block, id self, SEL _cmd) { return 0.0; });
    NSLog(@"[CPVE] CLLocation.speed hooked");

    NSLog(@"[CPVE] 全部 hook 安装完成");
}

__attribute__((constructor))
static void CPVE_init(void) {
    @autoreleasepool {
        setupHooks();
    }
}
