
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


@interface MediaChannelDelegate : CommandDelegate <GCKMediaControlChannelDelegate>

- (void)registerCallbackId:(NSString*)callbackToRegister;
- (void)loadMedia:(GCKMediaInformation*)mediaInformation;
- (void)play;
- (void)pause;
- (void)stop;
// - (void)mute:(BOOL)mute;
// - (void)setVolume:(float)volume;
- (void)seek:(NSTimeInterval)time;
- (float)position;
- (NSInteger)status;
- (NSDictionary *)mediaStatusAsDictionary;

@property(nonatomic, strong) GCKMediaControlChannel *channel;
@property(nonatomic, strong) NSString* loadMediaCallbackId;
@end
