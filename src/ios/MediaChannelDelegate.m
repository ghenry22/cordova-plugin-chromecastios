//
//  MediaChannelDelegate.m
//  HelloCordova
//
//  Created by Franz Wilding on 19.11.15.
//
//

#import <Foundation/Foundation.h>
#import "MediaChannelDelegate.h"
#import <GoogleCast/GoogleCast.h>

static NSString *const kMediaSessionID = @"mediaSessionID";
static NSString *const kPlayerState = @"playerState";
static NSString *const kIdleReason = @"idleReason";
static NSString *const kPlaybackRate = @"playbackRate";
static NSString *const kVolume = @"volume";
static NSString *const kIsMuted = @"isMuted";

@implementation MediaChannelDelegate


- (void)registerCallbackId:(NSString*)callbackToRegister {
  self.loadMediaCallbackId = callbackToRegister;
}

- (void)loadMedia:(GCKMediaInformation*)mediaInformation {
   /**self.loadMediaCallbackId = mediaInformation.customData;*/
   [self.channel loadMedia:mediaInformation];
}

- (void)play {
    [self.channel play];
}

- (void)pause {
    [self.channel pause];
}

- (void)stop {
    [self.channel stop];
}

//- (void)mute:(BOOL)mute {
//    [self.channel setStreamMuted:mute];
//}

//- (void)setVolume:(float)volume {
//    [self.channel setStreamVolume:volume];
//}

- (void)seek:(NSTimeInterval)time {
    [self.channel seekToTimeInterval:time];
}

- (float)position {
   float lastPosition = [self.channel approximateStreamPosition];
   return lastPosition;
}

- (NSInteger)status {
    NSInteger lastStatus = [self.channel requestStatus];
   return lastStatus;
}

- (NSDictionary *)mediaStatusAsDictionary {

    NSDictionary *result = @{kMediaSessionID:[NSNumber numberWithInteger:self.channel.mediaStatus.mediaSessionID],
                             kPlayerState:[NSNumber numberWithInteger:self.channel.mediaStatus.playerState],
                             kIdleReason:[NSNumber numberWithInteger:self.channel.mediaStatus.idleReason],
                             kPlaybackRate:[NSNumber numberWithFloat:self.channel.mediaStatus.playbackRate],
                             kVolume:[NSNumber numberWithFloat:self.channel.mediaStatus.volume],
                             kIsMuted:[NSNumber numberWithBool:self.channel.mediaStatus.isMuted]
                             };
    return result;
}

#pragma mark - GCKMediaControlChannelDelegate
/**
 * Called when a request to load media has completed.
 *
 * @param mediaControlChannel The channel.
 * @param sessionID The unique media session ID that has been assigned to this media item.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
didCompleteLoadWithSessionID:(NSInteger)sessionID {

    NSDictionary *mediaStatus = self.mediaStatusAsDictionary;

    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                 messageAsDictionary:mediaStatus];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loadMediaCallbackId];
}

/**
 * Called when a request to load media has failed.
 *
 * @param mediaControlChannel The channel.
 * @param error The load error.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
 didFailToLoadMediaWithError:(NSError *)error {
    
    NSString *errorDescription = error.localizedDescription;
    
    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION
                                     messageAsString:errorDescription];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.loadMediaCallbackId];
}

/**
 * Called when updated player status information is received.
 *
 * @param mediaControlChannel The channel.
 */
- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
   /** [self sendResponse:self.mediaStatusAsDictionary from:@"playerStatusUpdated" andKeepItAlive:YES]; */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"statusEvent" object:self];
}

/**
 * Called when updated queue status information is received.
 *
 * @param mediaControlChannel The channel.
 */
- (void)mediaControlChannelDidUpdateQueue:(GCKMediaControlChannel *)mediaControlChannel {
    
}

/**
 * Called when updated preload status is received.
 *
 * @param mediaControlChannel The channel.
 */
- (void)mediaControlChannelDidUpdatePreloadStatus:(GCKMediaControlChannel *)mediaControlChannel {
    
}

/**
 * Called when updated media metadata is received.
 *
 * @param mediaControlChannel The channel.
 */
- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel {
    
}

/**
 * Called when a request succeeds.
 *
 * @param mediaControlChannel The channel.
 * @param requestID The request ID that failed. This is the ID returned when the request was made.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
   requestDidCompleteWithID:(NSInteger)requestID {
  /**  NSLog(@"mediaControlChannel requestDidCompleteWithID"); */
}

/**
 * Called when a request is no longer being tracked because another request of the same type has
 * been issued by the application.
 *
 * @param mediaControlChannel The channel.
 * @param requestID The request ID that has been replaced. This is the ID returned when the request
 * was made.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didReplaceRequestWithID:(NSInteger)requestID {
    
}

/**
 * Called when a request is no longer being tracked because it has been explicitly cancelled.
 *
 * @param mediaControlChannel The channel.
 * @param requestID The request ID that has been cancelled. This is the ID returned when the request
 * was made.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
     didCancelRequestWithID:(NSInteger)requestID {
    
}

/**
 * Called when a request fails.
 *
 * @param mediaControlChannel The channel.
 * @param requestID The request ID that failed. This is the ID returned when the request was made.
 * @param error The error. If any custom data was associated with the error, it will be in the
 * error's userInfo dictionary with the key {@code kGCKErrorCustomDataKey}.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
       requestDidFailWithID:(NSInteger)requestID
                      error:(NSError *)error {
    
}
@end
