//
//  DeviceDelegate.m
//  HelloCordova
//
//  Created by Franz Wilding on 18.11.15.
//
//

#import <Foundation/Foundation.h>
#import "SelectDeviceDelegate.h"
#import <GoogleCast/GoogleCast.h>

@interface SelectDeviceDelegate() <GCKDeviceManagerDelegate> {
}
@end

@implementation SelectDeviceDelegate

- (void)registerCallbackId:(NSString*)callbackToRegister {
  self.selectCallbackId = callbackToRegister;
}

- (void)selectDevice:(GCKDevice*) device {
    self.device = device;
    self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:self.device clientPackageName:[NSBundle mainBundle].bundleIdentifier];
    self.deviceManager.delegate = self;
    [self.deviceManager connect];
}

- (void)launchApplication:(NSString *)receiverAppId {
    //Launch the application, relaunch if already running so app is always in clean state
    [self.deviceManager launchApplication:receiverAppId withLaunchOptions:[[GCKLaunchOptions alloc] initWithRelaunchIfRunning:YES]];
}

- (void)joinApplication:(NSString *)receiverAppId {
    //check if the currently running app is actually what we want to join
    //if it is, join it, if it is not then launch the desired app with relaunch
    if(receiverAppId == self.deviceManager.applicationMetadata.applicationID){
        [self.deviceManager joinApplication:receiverAppId];
    } else {
        [self.deviceManager launchApplication:receiverAppId withLaunchOptions:[[GCKLaunchOptions alloc] initWithRelaunchIfRunning:YES]];
    }
}
- (void)sendMessage:(NSString *)message {
    [self.textChannel sendTextMessage:message error:nil];
}

- (void)disconnect {
    [self.deviceManager leaveApplication];
    [self.deviceManager disconnect];
}

- (void)addChannel:(GCKCastChannel*)channel {
    [self.deviceManager addChannel:channel];
}

- (void)mute:(BOOL)mute {
    [self.deviceManager setMuted:mute];
}

- (void)setVolume:(float)volume {
    [self.deviceManager setVolume:volume];
}

#pragma mark - GCKDeviceManagerDelegate

// [START select device]
- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          self.device.deviceID, @"id",
                          self.device.friendlyName, @"friendlyName",
                          self.device.ipAddress, @"ipAddress",
                          [[NSNumber alloc] initWithUnsignedInt:self.device.servicePort], @"servicePort", nil];

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                 messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.selectCallbackId];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectWithError:(GCKError *)error {

    NSDictionary *errorData = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [[NSNumber alloc] initWithLong:error.code], @"code",
                               error.description, @"description", nil];

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                     messageAsDictionary:errorData];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.selectCallbackId];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didDisconnectWithError:(GCKError *)error {

    NSDictionary *errorData = [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"disconnect", @"deviceEventType",
                              [[NSNumber alloc] initWithLong:error.code], @"code",
                              error.description, @"description", nil];

    if(self.selectCallbackId != nil){
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                     messageAsDictionary:errorData];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.selectCallbackId];
        self.selectCallbackId = nil;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disconnectEvent" object:self userInfo:errorData];
    }
}
// [END select device]

// [START launch application]
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          applicationMetadata.applicationID, @"applicationID",
                          applicationMetadata.applicationName, @"applicationName",
                          applicationMetadata.senderAppIdentifier, @"senderAppIdentifier",
                          launchedApplication, @"launchedApplication",
                          applicationMetadata.senderAppLaunchURL, @"senderAppLaunchURL", nil];
	
	   self.textChannel = [[DeviceTextChannel alloc] initWithNamespace:@"urn:x-cast:com.connectsdk"];
    [self.deviceManager addChannel:self.textChannel];

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                 messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.selectCallbackId];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectToApplicationWithError:(NSError *)error {

    NSDictionary *errorData = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [[NSNumber alloc] initWithLong:error.code], @"code",
                               error.description, @"description", nil];

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                     messageAsDictionary:errorData];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.selectCallbackId];
}

- (void)deviceManage:(GCKDeviceManager *)deviceManager
didDisconnectFromApplicationWithError:(NSError *)error {
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                                @"appDisconnect", @"deviceEventType",
                               [[NSNumber alloc] initWithLong:error.code], @"code",
                               error.description, @"description", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceEvent" object:self userInfo:data];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveApplicationMetadata:(GCKApplicationMetadata *)applicationMetadata {
    
    if(applicationMetadata.applicationID == (id)[NSNull null] || applicationMetadata.applicationID == 0){
        //NSLog(@"NATIVE RECEIVE NULL METADATAEVENT");
        NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"timeout", @"deviceEventType",
                              applicationMetadata.applicationID, @"applicationID",
                              applicationMetadata.applicationName, @"applicationName",
                              applicationMetadata.senderAppIdentifier, @"senderAppIdentifier",
                              applicationMetadata.senderAppLaunchURL, @"senderAppLaunchURL", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deviceEvent" object:self userInfo:data];
    } else {
        //NSLog(@"NATIVE RECEIVE METADATAEVENT WITH DATA");
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveApplicationStatusText:(NSString *)applicationStatusText {
    //NSLog(@"NATIVE DID RECEIVE APPLICATION STATUS TEXT: %@", applicationStatusText);
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
volumeDidChangeToLevel:(float)volumeLevel isMuted:(BOOL)isMuted {

    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"volumeChanged", @"statusEventType",
                          [[NSNumber alloc] initWithFloat:volumeLevel], @"volumeLevel",
                          [[NSNumber alloc] initWithInt:isMuted], @"isMuted", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"volumeEvent" object:self userInfo:data];
}
// [END select device]
@end