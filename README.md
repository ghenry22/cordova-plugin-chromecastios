
# Cordova Chromecast Plugin (ios)

This project started as a fork of the work originally created by https://github.com/franzwilding, without which this plugin would not exist.

This plugin provides an interface to cast media from within cordova apps on iOS to chromecast devices

Currently only accomodates specifying generic media metadata but otherwise is fully functional

## Install

    cordova plugin add https://github.com/ghenry22/cordova-plugin-chromecastios.git

## Usage

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
    //currently supports video or audio
    //currently only supports generic metadata type on the chromecast
    
    //@param (string): title - title to display for the media item
    //@param (string): mediaUrl - url to access the media
    //@param (string): mediaType - mime time for the media item (ie audio/mpeg for mp3)
    //@param (string): subtitle - a subtitle that displays in smaller font under the title
    
    cordova.plugins.chromecastios.loadMedia(title, mediaUrl, mediaType, subtitle).then(function(response){
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

### Media Control Functions

### Properties

### Events
