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
#import "DeviceTextChannel.h"
#import <GoogleCast/GoogleCast.h>


@interface SelectDeviceDelegate : CommandDelegate

- (void)registerCallbackId:(NSString*)callbackToRegister;
- (void)selectDevice:(GCKDevice*) device;
- (void)launchApplication:(NSString*)receiverAppId;
- (void)joinApplication:(NSString*)receiverAppId;
- (void)sendMessage:(NSString*)message;
- (void)addChannel:(GCKCastChannel*)channel;
- (void)disconnect;
- (void)setVolume:(float)volume;
- (void)mute:(BOOL)mute;

@property(nonatomic, strong) GCKDeviceManager* deviceManager;
@property(nonatomic, strong) DeviceTextChannel* textChannel;
@property(nonatomic, strong) GCKDevice *device;
@property(nonatomic, strong) NSString* selectCallbackId;

@end
