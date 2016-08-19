
# Cordova Chromecast Plugin (ios)

This project started as a fork of the work originally created by https://github.com/franzwilding, without which this plugin would not exist.

This plugin provides an interface to cast media from within cordova apps on iOS to chromecast devices

Supports all media metadata type supported by chromecast as of v1.0.4

For most events where we care about the device response the plugin implements Promises so you don't have to deal with callbacks.

This plugin is now feature complete for using a chromecast from ios cordova app.

## Install

    //Latest from github master
    cordova plugin add https://github.com/ghenry22/cordova-plugin-chromecastios.git
    
    //latest published release from npm
    cordova plugin add cordova-plugin-chromecastios

## Usage

### Metadata Object Values

Chromecast devices support multiple types of pre-defined media, for which different metadata can be supplied and displayed / played on the device.  The loadMedia method requires you to choose the metadataType for your media and that you provide a metadata object with values to be used.  The only required value is title.  TO create an appropriate metadata object follow this guide:

    var metadata = {};

Generic media metadata:

    metadata.title: (string) Title of media
    metadata.subtitle: (string); Subtitle of media
    metadata.image: (string) url to image

Movie Media metadata:

    metadata.title: (string) Title of media
    metadata.subtitle: (string); Subtitle of media
    metadata.image: (string) url to image
    metadata.releaseDate: (string) either YYYYMMDD or YYYY
    metadata.studio: (string) name of the studio

TV Show media metadata:

    metadata.title: (string) Title of TV Episode
    metadata.seriestitle: (string); Title of the TV Series
    metadata.image: (string) url to image
    metadata.releaseDate: (string) either YYYYMMDD or YYYY
    metadata.episodeNumber: (int) number of the episode
    metadata.seasonNumber: (int) number of the season

Music track media metadata:

    metadata.title: (string) Title of track
    metadata.albumtitle: (string); Title of the album
    metadata.image: (string) url to image
    metadata.artist: (string) Name of the artist
    metadata.albumArtist: (string) name of the album artist (ie "various artists" or just = artist)
    metadata.trackNumber: (int) track number on the album

Photo media metadata:

    metadata.title: (string) Title of the image
    metadata.locationName: (string) location shown in the image or where taken
    metadata.artist: (string) name of the photographer or author


### Device Discovery & Control Functions

Get the default cast receiver application ID
    
    cordova.plugins.chromecastios.getDefaultApplicationID().then(function(response){
        var defaultAppId = response;
        //do something
    });

Scan for Chromecast devices

    cordova.plugins.chromecastios.scanForDevices(receiverAppId).then(function(response){
        //successfully started scanning for devices
        //response is simply a string value "started";
    }).catch(function(error){
        //failed to start scanning for devices
        //see error for details
    });;
    
Select Device to Connect to

    //Get the list of available devices
    var devices = cordova.plugins.chromecastios.devices;
    
    //select the device you want from the list and use the device object as the input param for select
    cordova.plugins.chromecastios.selectDevice(devices[0]).then(function(response){
        //successfully selected device
        //returns an object with the selected device details
    }).catch(function(error){
        //an error occurred selecting the device
        //returns an error code
    });

Launch Application on Device

    //Once connected to a device you can launch your application on the device
    //the application is as defined by the ApplicationID in specified when scanning
    cordova.plugins.chromecastios.launchApplication().then(function(response){
        //successfully launched application on chromecast device
        //returns an object with the application ID and application name
    }).catch(function(error){
        //an error occurred launching the application (perhaps connection to device timed out?)
        //returns an error code
    });

Load Media on Device

    //Start playing media on the device
    //supports video, audio & photo media
    //supports chromecast media types, generic, movie, tvshow, musictrack, photo
    
    //@param mediaUrl, absolute url to the media item
    //@param mediaType, mediaType (e.g. "video/mp4")
    //@param metadataType, integer value where 0=generic, 1=movie, 2=tvshow, 3=musicTrack, 4=photo
    //@param metadata, object containing required metadata, metadata.title is required, others are optional
    //@param streamType, integer value where 0=none, 1=buffered, 2=live, 99=unknown. defaults to buffered
    //change to live for live streams, if not specified will default to bufferered
 
    //note: see metadata object structure notes for valid options
    
    cordova.plugins.chromecastios.loadMedia(mediaUrl, mediaType, metadataType, metadata, streamType).then(function(response){
        //successfully loaded media on the device
        //returns a media Status object on success
    }).catch(function(error){
        //there was an error loading the media
        //most likely cause is a disconnection, network issue or time out of the device
    });

Disconnect from Device

    //disconnect from a device & application when finished
    cordova.plugins.chromecastios.disconnect().then(function(response){
        //successfully disconnected
        //returns confirmation of successful disconnection
    }).catch(function(error){
        //disconnect request failed
        //returns an error code
    });
    
Enable Passive Scanning Mode (scans less aggressively to save power)

    //bool is a boolean stating whether to enable or disable
    cordova.plugins.chromecastios.passiveScanForDevices(bool).then(function(reponse){
        //successfully enabled passive scanning mode
        //returns a boolean value representing the native frameworks current passive
        //scanning state
    }).catch(function(error){
        //an error occurred with the request
    });

### Media Control Functions

Play

    cordova.plugins.chromecastios.play();

Pause

    cordova.plugins.chromecastios.pause();

Stop

    //note stop also disconnects the media session, only use it when you are done
    //otherwise pause and seek back to 0
    cordova.plugins.chromecastios.stop();

Seek

    //specify the time in the current media file to seek to in seconds
    cordova.plugins.chromecastios.seek(seekTime);

getPosition

    //get the current position of the playing media in seconds
    cordova.plugins.chromecastios.getPosition().then(function(response){
        var position = response
        //do something with the position value
    }).catch(function(error){
        //an error occured getting the position
        //usually when the session has timed out or no media is loaded
    });

SetVolumeForMedia

    //set the volume on the remote device for the current media
    //value should be between 0 & 1
    cordova.plugins.chromecastios.setVolumeForMedia(0.5);    

muteMedia

    //Mute the current media
    //bool is a boolean true or false
    cordova.plugins.chromecastios.muteMedia(bool);

### Properties

cordova.plugins.chromecastios has several properties to provide you with information
    
    appConnected: has an app been successfully launched and is it available
    connected: has a device been successfully found and selected
    connectedApp: details of the currently connected application
    connectedDevice: details of the currently connected device
    devices: array list of available devices on the local network
    initComplete: has the plugin been initialised.  Should always be true
    lastMediaStatus: the last media status update received by the plugin
    passiveScanning: is passive scanning mode enabled
    receiverAppId: the appID of the currently running receiver application
    startedListening: is the app actively scanning
    volume.level: the current app volume level (value between 0 & 1)
    volume.isMuted: the mute status of the app volume (0 = not muted, 1 = muted);

### Events

cordova.plugins.chromecastios emits 3 types of events, device events, media status events, volume events

Every event returns an event object which will have:

event.eventType: to differentiate different event actions, included with all events

event.statusEvent: included with media status events, contains media status at time of the event

event.deviceEvent: included with device events, contains the device object for the affected device

event.volumeEvent: included with volume events, contains the latest vales for volume level & mute status

    
Media Status Events

    document.addEventListener("chromecast-ios-media", function(event) {
        if(event.eventType == "playbackFinished"){
          console.log("playback finished event");
          //do something
        }
        if(event.eventType == "playbackBuffering"){
          console.log("playback paused event")
          //do something
        }
        if(event.eventType == "playbackPlaying"){
          console.log("playback playing event");
          //do something
        }
        if(event.eventType == "playbackPaused"){
          console.log("playback paused event")
          //do something
          }
    });

Device Status Events
    
    document.addEventListener("chromecast-ios-device", function(event) {
        if(event.eventType == "online"){
          console.log("device online");
          //do something
        }
        if(event.eventType == "offline"){
          console.log("device offline")
          //do something
        }
        if(event.eventType == "changed"){
          console.log("device updated");
          //do something
        }
        if(event.eventType == "disconnect"){
          console.log("device disconnected");
          //do something
        }
    });

Volume Events

    document.addEventListener("chromecast-ios-volume", function(event) {
        if(event.eventType == "volumeChanged"){
          console.log("volume changed");
          //do something
        }
        if(event.eventType == "volumeMuted"){
          console.log("mute enabled")
          //do something
        }
        if(event.eventType == "volumeUnmuted"){
          console.log("mute disabled");
          //do something
        }
    })
