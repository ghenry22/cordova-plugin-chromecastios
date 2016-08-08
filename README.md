
# Cordova Chromecast Plugin (ios)

This project started as a fork of the work originally created by https://github.com/franzwilding, without which this plugin would not exist.

This plugin provides an interface to cast media from within cordova apps on iOS to chromecast devices

Currently only accomodates specifying generic media metadata but otherwise is fully functional

## Install

    cordova plugin add https://github.com/ghenry22/cordova-plugin-chromecastios.git

## Usage

### Discovery functions

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

Launch Application on Device

Load Media on Device

Disconnect from Device

### Media Control Functions

### Properties

### Events
