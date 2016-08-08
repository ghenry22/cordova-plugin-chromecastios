//
//  NSObject_DeviceDelegate.h
//  HelloCordova
//
//  Created by Franz Wilding on 18.11.15.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import "CommandDelegate.h"
#import <GoogleCast/GoogleCast.h>


@interface DeviceScannerDelegate : CommandDelegate

- (void)registerCallbackId:(NSString*)callbackToRegister;
- (void)startScanningForAppId:(NSString*) appId;
- (void)stopScanning;
- (void)enablePassiveScan:(BOOL)enablePassive;
- (GCKDevice*)findDevice:(NSString*)deviceId;

@property(nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property(nonatomic, strong) NSString* scanCallbackId;
@property(nonatomic, strong) NSString* scanStatus;

@end
