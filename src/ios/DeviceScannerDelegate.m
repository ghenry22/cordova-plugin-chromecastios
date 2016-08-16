//
//  DeviceDelegate.m
//  HelloCordova
//
//  Created by Franz Wilding on 18.11.15.
//
//

#import <Foundation/Foundation.h>
#import "DeviceScannerDelegate.h"
#import <GoogleCast/GoogleCast.h>

@interface DeviceScannerDelegate() <GCKDeviceScannerListener> {
}
@end

@implementation DeviceScannerDelegate

- (void)registerCallbackId:(NSString*)callbackToRegister {
  self.scanCallbackId = callbackToRegister;
}

- (void)startScanningForAppId:(NSString*) appId {
    
    // Establish filter criteria.
    GCKFilterCriteria *filterCriteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:appId];
    
    // Initialize device scanner only find devices supported by target appID
    self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];

    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
    self.scanStatus = @"started";

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                 messageAsString:self.scanStatus];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanCallbackId];
    self.scanCallbackId = @"";

}

- (void)stopScanning {
    
    [self.deviceScanner removeListener:self];
    [self.deviceScanner stopScan];
    self.scanStatus = @"stopped";

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                 messageAsString:self.scanStatus];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanCallbackId];
    self.scanCallbackId = @"";

}

- (void)enablePassiveScan:(BOOL)enablePassive {
        
    if(enablePassive){
        [self.deviceScanner setPassiveScan:true];
        self.scanStatus = @"passive";
    }
    if(!enablePassive){
        [self.deviceScanner setPassiveScan:false];
        self.scanStatus = @"started";
    }
        
    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                     messageAsBool:self.deviceScanner.passiveScan];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanCallbackId];
    self.scanCallbackId = @"";
}

- (GCKDevice*)findDevice:(NSString*)deviceId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deviceID == %@", deviceId];
    NSArray *filteredArray = [self.deviceScanner.devices filteredArrayUsingPredicate:predicate];
    if(filteredArray.count > 0) {
        return filteredArray.firstObject;
    } else {
        return nil;
    }
}

// [START device-scanner-listener]
#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"online", @"deviceEventType",
                          device.deviceID, @"id",
                          device.friendlyName, @"friendlyName",
                          device.ipAddress, @"ipAddress",
                          [[NSNumber alloc] initWithUnsignedInt:device.servicePort], @"servicePort", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceEvent" object:self userInfo:data];

}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"offline", @"deviceEventType",
                          device.deviceID, @"id",
                          device.friendlyName, @"friendlyName",
                          device.ipAddress, @"ipAddress",
                          [[NSNumber alloc] initWithUnsignedInt:device.servicePort], @"servicePort", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceEvent" object:self userInfo:data];
}

- (void)deviceDidChange:(GCKDevice *)device {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"change", @"deviceEventType",
                          device.deviceID, @"id",
                          device.friendlyName, @"friendlyName",
                          device.ipAddress, @"ipAddress",
                          [[NSNumber alloc] initWithUnsignedInt:device.servicePort], @"servicePort", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceEvent" object:self userInfo:data];
}
// [END device-scanner-listener]

@end