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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveVolumeEvent:) name:@"volumeEvent" object:nil];
}

- (void)receiveVolumeEvent:(NSNotification *)notification {   
    NSDictionary *eventData = [notification userInfo];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventData options: 0 error: nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsStatement = [NSString stringWithFormat:@"if(cordova.plugins.chromecastios)cordova.plugins.chromecastios.receiveVolumeEvent(%@);", jsonString];
    
#ifdef __CORDOVA_4_0_0
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
#else
    [self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
#endif
  
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
    BOOL enablePassive = [[command.arguments objectAtIndex:0] boolValue];
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

    //check that there is a valid media channel
    if(self.mediaChannelDelegate == nil) {
        NSLog(@"no media channel available, start media channel");
        [self startMediaChannel:command];
    }
    //check that the channel is connected
    if([self.mediaChannelDelegate status] == 0){
        NSLog(@"no media channel available, start media channel");
        [self startMediaChannel:command];
    }
    //register callbackID with the delegate
    [self.mediaChannelDelegate registerCallbackId:command.callbackId];

    //capture args passed from javascript
    NSString *mediaUrl = [command.arguments objectAtIndex:0];
    NSString *contentType = [command.arguments objectAtIndex:1];
    NSInteger metadataType = [(NSNumber *)[command.arguments objectAtIndex:2] integerValue];
    NSInteger streamType = [(NSNumber *)[command.arguments objectAtIndex:3] integerValue];
    
    //default the streamtype to buffered
    GCKMediaStreamType gckStreamType = GCKMediaStreamTypeBuffered;
    
    //update the streamtype if user specified otherwise
    if(streamType == 0){
        gckStreamType = GCKMediaStreamTypeNone;
    }
    if(streamType == 2){
        gckStreamType = GCKMediaStreamTypeLive;
    }
    if(streamType == 99){
        gckStreamType = GCKMediaStreamTypeUnknown;
    }
        
    //handle generic media metadata
    if(metadataType == 0){
        //NSLog(@"generic metadata type");

        //init a metadata object with type generic
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];

        //Title is a required parameter so no need to test for null
        [metadata setString:[command.arguments objectAtIndex:4] forKey:kGCKMetadataKeyTitle];
        
        //If subtitle is not null add to metadata
        if([command.arguments objectAtIndex:5] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:5] forKey:kGCKMetadataKeySubtitle];
        }
        //If image is not null add to metadata
        if([command.arguments objectAtIndex:6] != (id)[NSNull null]){
            NSURL *imageUrl = [NSURL URLWithString:[command.arguments objectAtIndex:6]];
            GCKImage *image = [[GCKImage alloc] initWithURL:imageUrl width:500 height:500];
            [metadata addImage:image];
        }
        //load the media with metadata
        [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                               initWithContentID:mediaUrl
                                               streamType:gckStreamType
                                               contentType:contentType
                                               metadata:metadata
                                               streamDuration:0
                                               customData:nil]];
    }
    //handle movie media metadata
    if(metadataType == 1){
        //NSLog(@"movie metadata type");

        //init a metadata object with type movie
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
        
        //Title is a required parameter so no need to test for null
        [metadata setString:[command.arguments objectAtIndex:4] forKey:kGCKMetadataKeyTitle];
        
        //If subtitle is not null add to metadata
        if([command.arguments objectAtIndex:5] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:5] forKey:kGCKMetadataKeySubtitle];
        }
        //If image is not null add to metadata
        if([command.arguments objectAtIndex:6] != (id)[NSNull null]){
            NSURL *imageUrl = [NSURL URLWithString:[command.arguments objectAtIndex:6]];
            GCKImage *image = [[GCKImage alloc] initWithURL:imageUrl width:500 height:500];
            [metadata addImage:image];
        }
        //If releaseDate is not null add to metadata
        if([command.arguments objectAtIndex:7] != (id)[NSNull null]){
            //store the argument as a string
            NSString *inputDate = [command.arguments objectAtIndex:7];
            
            //setup a date formatter to handle the input from javascript
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"]; //iso 8601 format
            
            //generate an nsdate object from the javascript string
            NSDate *output = [dateFormat dateFromString:inputDate];

            //set the date metadata
            [metadata setDate:output forKey:kGCKMetadataKeyReleaseDate];
        }
        //If Studio is not null add to metadata
        if([command.arguments objectAtIndex:8] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:8] forKey:kGCKMetadataKeyStudio];
        }
        //load the media with metadata
        [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                               initWithContentID:mediaUrl
                                               streamType:gckStreamType
                                               contentType:contentType
                                               metadata:metadata
                                               streamDuration:0
                                               customData:nil]];
    }
    //handle tv show media metadata
    if(metadataType == 2){
        //NSLog(@"tvshow metadata type");

        //init a metadata object with type movie
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeTVShow];
        
        //Title is a required parameter so no need to test for null
        [metadata setString:[command.arguments objectAtIndex:4] forKey:kGCKMetadataKeyTitle];
        
        //If seriesTitle is not null add to metadata
        if([command.arguments objectAtIndex:5] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:5] forKey:kGCKMetadataKeySeriesTitle];
        }
        //If image is not null add to metadata
        if([command.arguments objectAtIndex:6] != (id)[NSNull null]){
            NSURL *imageUrl = [NSURL URLWithString:[command.arguments objectAtIndex:6]];
            GCKImage *image = [[GCKImage alloc] initWithURL:imageUrl width:500 height:500];
            [metadata addImage:image];
        }
        //If releaseDate is not null add to metadata
        if([command.arguments objectAtIndex:7] != (id)[NSNull null]){
            //cast the argument to a string
            NSString *inputDate = [command.arguments objectAtIndex:7];
            
            //setup a date formatter to handle the input from javascript
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"]; //iso 8601 format
            
            //generate an nsdate object from the javascript string
            NSDate *output = [dateFormat dateFromString:inputDate];

            //set the date metadata
            [metadata setDate:output forKey:kGCKMetadataKeyReleaseDate];
        }
        //If episodeNumber is not null add to metadata
        if([command.arguments objectAtIndex:8] != (id)[NSNull null]){
            [metadata setInteger:[(NSNumber *)[command.arguments objectAtIndex:8] integerValue] forKey:kGCKMetadataKeyEpisodeNumber];
        }
        //If seasonNumber is not null add to metadata
        if([command.arguments objectAtIndex:9] != (id)[NSNull null]){
            [metadata setInteger:[(NSNumber *)[command.arguments objectAtIndex:9] integerValue] forKey:kGCKMetadataKeySeasonNumber];
        }
        //load the media with metadata
        [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                               initWithContentID:mediaUrl
                                               streamType:gckStreamType
                                               contentType:contentType
                                               metadata:metadata
                                               streamDuration:0
                                               customData:nil]];
    }
    //handle music track media metadata
    if(metadataType == 3){
        //NSLog(@"musicTrack metadata type");

        //init a metadata object with type movie
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMusicTrack];
        
        //Title is a required parameter so no need to test for null
        [metadata setString:[command.arguments objectAtIndex:4] forKey:kGCKMetadataKeyTitle];
        
        //If albumTitle is not null add to metadata
        if([command.arguments objectAtIndex:5] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:5] forKey:kGCKMetadataKeyAlbumTitle];
        }
        //If image is not null add to metadata
        if([command.arguments objectAtIndex:6] != (id)[NSNull null]){
            NSURL *imageUrl = [NSURL URLWithString:[command.arguments objectAtIndex:6]];
            //TODO test out some different image sizes to see the effects and either make dynamic or document
            GCKImage *image = [[GCKImage alloc] initWithURL:imageUrl width:500 height:500];
            [metadata addImage:image];
        }
        //If artist is not null add to metadata
        if([command.arguments objectAtIndex:7] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:7] forKey:kGCKMetadataKeyArtist];
        }
        //If albumArtist is not null add to metadata
        if([command.arguments objectAtIndex:8] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:8] forKey:kGCKMetadataKeyAlbumArtist];
        }
        //If trackNumber is not null add to metadata
        if([command.arguments objectAtIndex:9] != (id)[NSNull null]){
            [metadata setInteger:[(NSNumber *)[command.arguments objectAtIndex:9] integerValue] forKey:kGCKMetadataKeyTrackNumber];
        }
        //load the media with metadata
        [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                               initWithContentID:mediaUrl
                                               streamType:gckStreamType
                                               contentType:contentType
                                               metadata:metadata
                                               streamDuration:0
                                               customData:nil]];
    }
    //handle photo media metadata
    if(metadataType == 4){
        //NSLog(@"photo metadata type");

        //init a metadata object with type movie
        GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypePhoto];
        
        //Title is a required parameter so no need to test for null
        [metadata setString:[command.arguments objectAtIndex:4] forKey:kGCKMetadataKeyTitle];
        
        //If albumTitle is not null add to metadata
        if([command.arguments objectAtIndex:5] != (id)[NSNull null]){
            [metadata setString:[command.arguments objectAtIndex:5] forKey:kGCKMetadataKeyLocationName];
        }
        //If artist is not null add to metadata
        if([command.arguments objectAtIndex:6] != (id)[NSNull null]){
           [metadata setString:[command.arguments objectAtIndex:6] forKey:kGCKMetadataKeyArtist];
        }
        //load the media with metadata
        [self.mediaChannelDelegate loadMedia: [[GCKMediaInformation alloc]
                                               initWithContentID:mediaUrl
                                               streamType:gckStreamType
                                               contentType:contentType
                                               metadata:metadata
                                               streamDuration:0
                                               customData:nil]];
    }
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
    if(self.selectDeviceDelegate == nil || self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to mute a media item you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.selectDeviceDelegate mute:mute];
}

- (void)setVolumeForMedia:(CDVInvokedUrlCommand*)command {
    float volume = [[command.arguments objectAtIndex:0] floatValue];
    if(self.selectDeviceDelegate == nil || self.mediaChannelDelegate == nil) {
        CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"In order to set the volume for media you need to load it first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    [self.selectDeviceDelegate setVolume:volume];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"disconnectEvent" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"volumeEvent" object:nil];
}

@end
