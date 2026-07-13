#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - 声明可能存在的私有类和方法 (声明为 @interface 让编译器不报错)

@interface CARSession : NSObject
- (double)currentSpeed;
- (BOOL)isVehicleMoving;
@end

@interface CARSessionStatus : NSObject
- (double)vehicleSpeed;
@end

@interface CARSessionConfiguration : NSObject
- (BOOL)allowsVideoPlayback;
@end

@interface CRVehicleAccessoryManager : NSObject
- (double)vehicleSpeed;
@end

#pragma mark - 速度绕过组

%group SpeedBypass

%hook CARSession
- (double)currentSpeed {
    return 0.0;
}
- (BOOL)isVehicleMoving {
    return NO;
}
%end

%hook CARSessionStatus
- (double)vehicleSpeed {
    return 0.0;
}
%end

%hook CRVehicleAccessoryManager
- (double)vehicleSpeed {
    return 0.0;
}
%end

%hook CLLocation
- (CLLocationSpeed)speed {
    return 0.0;
}
%end

%end

#pragma mark - 视频播放解锁组

%group VideoUnlock

%hook CARSession
- (BOOL)isSuspended {
    return NO;
}
%end

%hook CARSessionConfiguration
- (BOOL)allowsVideoPlayback {
    return YES;
}
%end

%end

#pragma mark - 构造函数

%ctor {
    %init(SpeedBypass);
    %init(VideoUnlock);

    NSLog(@"[CarPlayVideoEnabler] Loaded - Speed bypass & video unlock active");
}
