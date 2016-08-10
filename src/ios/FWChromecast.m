//
//  FWChromecast.m
//  HelloCordova
//
//  Created by Franz Wilding on 16.11.15.
//
//

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>
#import "FWChromecast.h"
#import "DeviceScannerDelegate.h"
#import "SelectDeviceDelegate.h"
#import "MediaChannelDelegate.h"

@implementation FWChromecast : CDVPlugin

- (void)pluginInitialize
{
    NSLog(@"chromecast-ios plugin initializing");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveStatusEvent:) name:@"statusEvent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDeviceEvent:) name:@"deviceEvent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDisconnectEvent:) name:@"disconnectEvent" object:nil];
}

- (void)receiveStatusEvent:(NSNotification *)notification {
    NSDictionary *currentStatus = [self.mediaChannelDelegate mediaStatusAsDictionary];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:currentStatus options: 0 error: nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsStatement = [NSString stringWithFormat:@"if(cordova.plugins.chromecastios)cordova.plugins.chromecastios.receiveStatusEvent(%@);", jsonString];

#ifdef __CORDOVA_4_0_0
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
#else
    [self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
#endif
}

- (void)receiveDeviceEvent:(NSNotification *)notification {
    NSDictionary *eventData = [notification userInfo];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventData options: 0 error: nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsStatement = [NSString stringWithFormat:@"if(cordova.plugins.chromecastios)cordova.plugins.chromecastios.receiveDeviceEvent(%@);", jsonString];

#ifdef __CORDOVA_4_0_0
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
#else
    [self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
#endif
}

- (void)receiveDisconnectEvent:(NSNotification *)notification {
    NSDictionary *data = [notification userInfo];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: 0 error: nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsStatement = [NSString stringWithFormat:@"if(cordova.plugins.chromecastios)cordova.plugins.chromecastios.receiveDeviceEvent(%@);", jsonString];

#ifdef __CORDOVA_4_0_0
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
#else
    [self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
#endif
}

- (void)getDefaultReceiverApplicationID:(CDVInvokedUrlCommand*)command 
{ 
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:kGCKMediaDefaultReceiverApplicationID]; 
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
} 

- (void)scanForDevices:(CDVInvokedUrlCommand*)command
{

    self.receiverAppId = [command.arguments objectAtIndex:0];
    self.deviceScannerDelegate = [[DeviceScannerDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                        andCallbackId:command.callbackId];
    [self.deviceScannerDelegate registerCallbackId:command.callbackId];
    [self.deviceScannerDelegate startScanningForAppId:self.receiverAppId];
}

- (void)stopScanForDevices:(CDVInvokedUrlCommand*)command
{
    if(self.deviceScannerDelegate == nil) {
    CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not scanning, nothing to stop"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.deviceScannerDelegate registerCallbackId:command.callbackId];
    [self.deviceScannerDelegate stopScanning];
}

- (void)enablePassiveScan:(CDVInvokedUrlCommand*)command
{
    bool enablePassive = [[command.arguments objectAtIndex:0] boolValue];
    if(self.deviceScannerDelegate == nil) {
    CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not scanning, cannot set passive"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.deviceScannerDelegate registerCallbackId:command.callbackId];
    [self.deviceScannerDelegate enablePassiveScan:enablePassive];
}

- (void)selectDevice:(CDVInvokedUrlCommand*)command
{
    NSString* deviceId = [command.arguments objectAtIndex:0];

    self.selectDeviceDelegate = [[SelectDeviceDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                      andCallbackId:command.callbackId];
    [self.selectDeviceDelegate registerCallbackId:command.callbackId];
    [self.selectDeviceDelegate selectDevice:[self.deviceScannerDelegate findDevice:deviceId]];
}
- (void)sendMessage:(NSString *)message {
    [self.selectDeviceDelegate sendMessage:message];
}

- (void)launchApplication:(CDVInvokedUrlCommand*)command
{
    if(self.selectDeviceDelegate == nil || self.receiverAppId == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to launch an application you need to select a device first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.selectDeviceDelegate registerCallbackId:command.callbackId];
    [self.selectDeviceDelegate launchApplication:self.receiverAppId];
}

- (void)joinApplication:(CDVInvokedUrlCommand*)command
{
    if(self.selectDeviceDelegate == nil || self.receiverAppId == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to join an application you need to select a device first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.selectDeviceDelegate registerCallbackId:command.callbackId];
    [self.selectDeviceDelegate joinApplication:self.receiverAppId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command
{
    if(self.selectDeviceDelegate == nil || self.receiverAppId == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Nothing to disconnect"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

    if(self.selectDeviceDelegate != nil) {
        [self.selectDeviceDelegate registerCallbackId:command.callbackId];
        [self.selectDeviceDelegate disconnect];
    }
}

- (void)startMediaChannel:(CDVInvokedUrlCommand*)command
{
    GCKMediaControlChannel *mediaChannel = [[GCKMediaControlChannel alloc] init];
    self.mediaChannelDelegate = [[MediaChannelDelegate alloc] initWithCommandDelegate:self.commandDelegate andCallbackId:command.callbackId];
    mediaChannel.delegate = self.mediaChannelDelegate;
    self.mediaChannelDelegate.channel = mediaChannel;
    [self.selectDeviceDelegate addChannel:mediaChannel];
}


- (void)loadMedia:(CDVInvokedUrlCommand*)command {

    if(self.mediaChannelDelegate == nil) {
        [self startMediaChannel:command];
    }
    if([self.mediaChannelDelegate status] == 0){
        NSLog(@"no media channel available, start media channel");
        [self startMediaChannel:command];
    }

    [self.mediaChannelDelegate registerCallbackId:command.callbackId];

    NSString *title = [command.arguments objectAtIndex:0];
    NSString *mediaUrl = [command.arguments objectAtIndex:1];
    NSString *contentType = [command.arguments objectAtIndex:2];
    NSString *subtitle = [command.arguments objectAtIndex:3];

    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
    [metadata setString:title forKey:kGCKMetadataKeyTitle];
    [metadata setString:subtitle forKey:kGCKMetadataKeySubtitle];

    [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                           initWithContentID:mediaUrl
                                           streamType:GCKMediaStreamTypeNone
                                           contentType:contentType
                                           metadata:metadata
                                           streamDuration:0
                                           customData:nil]];
}

- (void)playMedia:(CDVInvokedUrlCommand*)command {
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to play a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate play];
}

- (void)pauseMedia:(CDVInvokedUrlCommand*)command {
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to pause a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate pause];
}

- (void)stopMedia:(CDVInvokedUrlCommand*)command {
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to stop a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate stop];
}

- (void)muteMedia:(CDVInvokedUrlCommand*)command {
    bool mute = [[command.arguments objectAtIndex:0] boolValue];
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to mute a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate mute:mute];
}

- (void)setVolumeForMedia:(CDVInvokedUrlCommand*)command {
    float volume = [[command.arguments objectAtIndex:0] floatValue];
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to set the volume you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate setVolume:volume];
}

- (void)seekMedia:(CDVInvokedUrlCommand*)command {
    NSTimeInterval time = [[command.arguments objectAtIndex:0] doubleValue];
    if(self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to seek a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.mediaChannelDelegate seek:time];
}

- (void)getPosition:(CDVInvokedUrlCommand*)command {
   CDVPluginResult *pluginResult;
   if (self.mediaChannelDelegate == nil) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                       messageAsString:@"getPosition failed: No Media Loaded, loadMedia first"];
   } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                       messageAsDouble:[self.mediaChannelDelegate position]];
   }
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getChannelStatus:(CDVInvokedUrlCommand*)command {
   CDVPluginResult *pluginResult;
   if (self.mediaChannelDelegate == nil) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                       messageAsString:@"getChannelStatus failed: No Media Loaded, loadMedia first"];
   } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsNSInteger:[self.mediaChannelDelegate status]];
   }
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getMediaStatus:(CDVInvokedUrlCommand*)command {
   CDVPluginResult *pluginResult;
   if (self.mediaChannelDelegate == nil) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                       messageAsString:@"getMediaStatus failed: No Media Loaded, loadMedia first"];
   } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                       messageAsDictionary:[self.mediaChannelDelegate mediaStatusAsDictionary]];
   }
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"statusEvent" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceEvent" object:nil];
}

@end
