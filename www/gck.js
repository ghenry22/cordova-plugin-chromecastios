/**
 * Used to catch errors we don't want to deal with
 * and log them to console in case we change our mind
 *
 */
exports.unhandledException = function (error) {
    console.log("FWChromecast ERROR: " + error);
};

/**
 * Receive session updates from the native iOS cast library
 * Add eventType and eventStatus to the event object
 * Emit events for the user app to consume
 */
exports.receiveSessionEvent = function(event) {
    var t = this;
    var _event = event;

    //Device has Changed
    if(_event.deviceEventType == "receiveMessage"){
        console.log("gck js session receivemessage");
    }
};


/**
 * Receive application level volume change events (includes mute change)
 * Add eventType and eventStatus to the event object
 * Emit events for the user app to consume
 */
exports.receiveVolumeEvent = function(event) {
    var t = this;
    var _event = event;

    if(t.volume.level != _event.volumeLevel){
        //Update volume level
        t.volume.level = _event.volumeLevel;

        //Broadcast volume event
        var ev = document.createEvent('HTMLEvents');
        ev.volumeEvent = _event;
        ev.eventType = "volumeChanged";
        ev.initEvent('chromecast-ios-volume', true, true, arguments);
        document.dispatchEvent(ev);
    }
    if(t.volume.isMuted && !_event.isMuted){
        //Update mute status
        t.volume.isMuted = _event.isMuted;

        //Broadcast mute enabled event
        var ev = document.createEvent('HTMLEvents');
        ev.volumeEvent = _event;
        ev.eventType = "volumeMuted";
        ev.initEvent('chromecast-ios-volume', true, true, arguments);
        document.dispatchEvent(ev);        
    }
    if(!t.volume.isMuted && _event.isMuted){
        //Update mute status
        t.volume.isMuted = _event.isMuted;

        //Broadcast muted disabled event
        var ev = document.createEvent('HTMLEvents');
        ev.volumeEvent = _event;
        ev.eventType = "volumeUnmuted";
        ev.initEvent('chromecast-ios-volume', true, true, arguments);
        document.dispatchEvent(ev);        
    }
};

/**
 * Receive device availability updates from the native iOS cast library
 * Add eventType and eventStatus to the event object
 * Emit events for the user app to consume
 */
exports.receiveDeviceEvent = function(event) {
    var t = this;
    var _event = event;

    //disconnect events don't pass a device object but needs one to avoid repeating code below
    if((_event.deviceEventType == "disconnect" || _event.deviceEventType == "appDisconnect" || _event.deviceEventType == "timeout") && t.connected){
        _event.friendlyName = t.connectedDevice.friendlyName;
        _event.id = t.connectedDevice.id;
        _event.ipAddress = t.connectedDevice.ipAddress;
        _event.servicePort = t.connectedDevice.servicePort;
    }

    var _device = {};
    _device.friendlyName = _event.friendlyName;
    _device.id = _event.id;
    _device.ipAddress = _event.ipAddress;
    _device.servicePort = _event.servicePort;

    //Connection timeout
    if(_event.deviceEventType == "timeout"){
        //action is only required if there is a current connection
        if(t.connected && t.appConnected){
            //Set status as disconnected
            t.appConnected = false;
            t.connectedApp = {};
            t.connected = false;
            t.connectedDevice = {};

            //Broadcast timeout event
            var ev = document.createEvent('HTMLEvents');
            ev.deviceEvent = _device;
            ev.eventType = "timeout";
            ev.initEvent('chromecast-ios-device', true, true, arguments);
            document.dispatchEvent(ev);
        }
    }
    //Disconnected from App
    if(_event.deviceEventType == "appDisconnect"){
        //Set status as App disconnected
        t.appConnected = false;
        t.connectedApp = {};

        //Broadcast appDisconnect event
        var ev = document.createEvent('HTMLEvents');
        ev.deviceEvent = _device;
        ev.eventType = "appDisconnect";
        ev.initEvent('chromecast-ios-device', true, true, arguments);
        document.dispatchEvent(ev);
    }
    //Disconnected from Device
    if(_event.deviceEventType == "disconnect"){
        //Set status as device disconnected
        t.connected = false;
        t.connectedDevice = {};
        t.appConnected = false;
        t.connectedApp = {};

        //Broadcast disconnect event
        var ev = document.createEvent('HTMLEvents');
        ev.deviceEvent = _device;
        ev.eventType = "disconnect";
        ev.initEvent('chromecast-ios-device', true, true, arguments);
        document.dispatchEvent(ev);
    }
    //Device Came Online
    if(_event.deviceEventType == "online"){
        //Add device to list
        t.devices.push(_device);

        //Broadcast online event
        var ev = document.createEvent('HTMLEvents');
        ev.deviceEvent = _device;
        ev.eventType = "online";
        ev.initEvent('chromecast-ios-device', true, true, arguments);
        document.dispatchEvent(ev);
    }
    //Device Went Offline
    if(_event.deviceEventType == "offline"){
        //Remove device from list
        t.devices.splice(t.devices.indexOf(_device),1);

        //Broadcast offline Event
        var ev = document.createEvent('HTMLEvents');
        ev.deviceEvent = _device;
        ev.eventType = "offline";
        ev.initEvent('chromecast-ios-device', true, true, arguments);
        document.dispatchEvent(ev);
    }
    //Device has Changed
    if(_event.deviceEventType == "changed"){
        for (var i=0;i<t.devices.length;i++){
            if(t.devices[i].id == _device.id){
                //Update device in list with new value
                t.devices.splice(i,1,_device);

                //Broadcast Change Event
                var ev = document.createEvent('HTMLEvents');
                ev.deviceEvent = _device;
                ev.eventType = "changed";
                ev.initEvent('chromecast-ios-device', true, true, arguments);
                document.dispatchEvent(ev);
            }
        }
    }
};

/**
 * Receive player Status updates from native iOS cast library
 * Add eventType and eventStatus to the event object
 * Emit events for the user app to consume
 */
exports.receiveStatusEvent = function(event) {
    var t = this;
    var _oldStatus = JSON.stringify(t.lastMediaStatus);
    var _newStatus = JSON.stringify(event);

    if(_oldStatus == _newStatus){
    //No change since last update, do not emit duplicate events
    } else {
        if(event.volume != t.lastMediaStatus.volume){
            //Volume Changed
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "volumeChanged";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;
        }
        if(event.isMuted != t.lastMediaStatus.isMuted){
            //Mute Status Changed
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "muteChanged";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;
        }
        if(event.playerState == 1 && event.idleReason == 1){
            //Playback Finished
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "playbackFinished";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;            
        }
        if(event.playerState == 4){
            //Playing
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "playbackBuffering";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;
        }
        if(event.playerState == 2){
            //Playing
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "playbackPlaying";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;            
        }
        if(event.playerState == 3){
            //Paused
            var ev = document.createEvent('HTMLEvents');
            ev.statusEvent = event;
            ev.eventType = "playbackPaused";
            ev.initEvent('chromecast-ios-media', true, true, arguments);
            document.dispatchEvent(ev);
            t.lastMediaStatus = event;            
        }
    }
};

/**
 * Get the default receiver appID for iOS apps
 * Use this as your appID if you do not have a custom or styled media receiver
 * registered.
 * returns: string: appID
 */
exports.getDefaultReceiverApplicationID = function () {
    var t = this;
    return new Promise(function(resolve, reject){
        cordova.exec(function(response){
            var _defaultAppID = response;
            resolve(_defaultAppID);
        }, function(error){
            var _error = error;
            reject(error);
        }, "FWChromecast", "getDefaultReceiverApplicationID", []); 
    })

};

/**
 * Must be called before any other method
 * Configures variables used for status tracking
 * 
 * Called automatically by scanForDevices()
 */
exports.init = function (){
    var t = this;
    if(!this.initComplete){
        //create a place holder for lastMediaStatus
        t.lastMediaStatus = {};
        t.lastMediaStatus.isMuted = false;
        t.lastMediaStatus.volume = 1;
        //create a place holder for device list
        t.devices = [];
        //are we listening for devices yet
        t.startedListening = false;
        t.passiveScanning = false;
        //store details of the currently connected device
        t.connectedDevice = {};
        t.connected = false;
        t.appConnected = false;
        t.connectedApp = {};
        //track app volume and mute status
        t.volume = {}
        t.volume.level = 1;
        t.volume.isMuted = 0;
        //set initComplete to true
        t.initComplete = true;
        return true;
    } else {
        return false;
    }
};

/**
 * Scan the local wifi for chromecast devices. onDiscover get's called, when
 * devices where found.
 *
 * @param receiverAppId, the receiverAppId to filter devices
 */
exports.scanForDevices = function (receiverAppId) {
    var t = this;
    this.init();
    t.receiverAppId = receiverAppId;

    if (typeof (receiverAppId) == 'undefined') {
        Promise.reject("no AppId Specified");
    }

    return new Promise(function(resolve, reject){
        if(!t.startedListening){
            t.startedListening = true;
            t.passiveScanning = false;

            cordova.exec(function(response){
                resolve(response);
            }, function(error){
                reject(error);
            }, "FWChromecast", "scanForDevices", [receiverAppId]);
        } else {
            resolve("already listening");
        }
    })
};

/**
 * Stop scanning for devices
 *
 * Save resources when user is not actively looking to devices
 */
exports.stopScanForDevices = function() {
    var t = this;
    if(!t.startedListening){
        Promise.reject("no scan to stop");
    }
    return new Promise(function(resolve, reject){
        cordova.exec(function(response){
            t.startedListening = false;
            t.passiveScanning = false;
            t.devices = [];
            resolve(response);
        }, function(error){
            reject(error);
        }, "FWChromecast", "stopScanForDevices", [])
    })
}

/**
 * Enable passive scanning
 * Scans less frequently for updates
 * @param bool, true to enable, false to disable
 */
exports.passiveScanForDevices = function(bool) {
    var t = this;
    if(bool == "undefined"){
        Promise.reject("no argument provided");
    }
    if((bool && t.passiveScanning) || (!bool && !t.passiveScanning)){
        Promise.resolve("no change required");
    }
    return new Promise(function(resolve, reject){
        cordova.exec(function(response){
            t.passiveScanning = bool;
            resolve(response);
        }, function(error){
            reject(error);
        }, "FWChromecast", "enablePassiveScan", [bool]);
    })
}

/**
 * Select a device to use.
 *
 * @param device, the device identifier of the device to select.
 */
exports.selectDevice = function (device) {
    var t = this;

    if (typeof (device) == 'undefined') {
        return Promise.reject();
    }

    if (t.devices.indexOf(device) == -1) {
        return Promise.reject();
    }

    return new Promise(function (resolve, reject) {

        cordova.exec(function (response) {
            t.connected = true;
            t.connectedDevice.friendlyName = response.friendlyName;
            t.connectedDevice.ipAddress = response.ipAddress;
            t.connectedDevice.id = response.id;
            t.connectedDevice.servicePort = response.servicePort;
            resolve(response);
        }, function(error){
            reject(error);
        }, "FWChromecast", "selectDevice", [device.id]);
    });
};

/**
 * After selecting a device, we can start the application.
 *
 */
exports.launchApplication = function () {
    var t = this;

    //If we're not connected to a device, cannot launch an app
    if(!t.connected){
        Promise.reject("Connect to a device first");
    }

    return new Promise(function (resolve, reject) {

        cordova.exec(function(response){
            resolve(response);
            t.appConnected = true;
            t.connectedApp.applicationID = response.applicationID;
            t.connectedApp.applicationName = response.applicationName;
        }, function(error){
            reject(error);
            t.appConnected = false;
            t.connectedApp = {};
        }, "FWChromecast", "launchApplication", []);
    });
};

/**
 * After selecting a device, we can join the application if already
 * running, otherwise will launch the application
 *
 */
exports.joinApplication = function () {
    var t = this;

    if(!t.connected){
        Promise.reject("Connect to a device first");
    }

    return new Promise(function (resolve, reject) {

        cordova.exec(function(response){
            resolve(response);
            t.appConnected = true;
            t.connectedApp.applicationID = response.applicationID;
            t.connectedApp.applicationName = response.applicationName;
        }, function(error){
            reject(error);
            t.appConnected = false;
            t.connectedApp = {};
        }, "FWChromecast", "joinApplication", []);
    });
};

exports.sendMessage = function (message) {
    var t = this;
    cordova.exec(undefined, t.unhandledException, "FWChromecast", "sendMessage", [message]);
};

/**
 * Disconnect from application.
 */
exports.disconnect = function () {
    var t = this;

    if(!t.connected){
        Promise.reject("not currently connected");
    }

    return new Promise(function (resolve, reject) {

        cordova.exec(function(response){
            t.connected = false;
            t.appConnected = false;
            t.connectedDevice = {};
            t.connectedApp = {};
            resolve(response);
        }, function(error){
            //error code 0 is actually successful disconnect
            if(error.code == 0){
                t.connected = false;
                t.appConnected = false;
                t.connectedDevice = {};
                t.connectedApp = {};
                resolve(error);
            } else {
                reject(error);
            }
        }, "FWChromecast", "disconnect", []);
    });
};

/**
 * Start the default media channel.
 */
exports.startMediaChannel = function () {
    var t = this;
    return new Promise(function (resolve, reject) {

        cordova.exec(function (response) {
            resolve(response);
        }, function(error){
            reject(error);
        }, "FWChromecast", "startMediaChannel", []);
    });
};

/**
 *
 * DEPRECATED.  KEPT FOR REFERENCE.  SEE UPDATED LOADMEDIA BELOW
 *
 * Load a media item on the default media channel.
 *
 * @param title, title to display
 * @param mediaUrl, absolute url to the media item
 * @param mediaType, mediaType (e.g. "video/mp4")
 * @param subtitle to display
 */
// exports.loadMedia2 = function (title, mediaUrl, mediaType, subtitle) {
//     var t = this;
//     return new Promise(function(resolve, reject){

//         cordova.exec(function(response){
//             var _response = response;
//             resolve(_response);
//         }, function(error){
//             var _error = error;
//             reject(_error);
//         }, "FWChromecast", "loadMedia", [title, mediaUrl, mediaType, subtitle]);
//     })
// };

/**
 * Load a media item on the default media channel.
 *
 * @param mediaUrl, absolute url to the media item
 * @param mediaType, mediaType (e.g. "video/mp4")
 * @param metadataType, integer value where 0=generic, 1=movie, 2=tvshow, 3=musicTrack, 4=photo
 * @param metadata, object containing required metadata, metadata.title is required, others are optional
 * @param streamType, integer value where 0=none, 1=buffered, 2=live, 99=unknown. defaults to buffered
 *  change to live for live streams, otherwise buffered should be sufficient
 *
 * note: releaseDate should be submitted as a String YYYYMMDD.  If month and day are not relevant set them to 01.
 *
 */
exports.loadMedia = function (mediaUrl, mediaType, metadataType, metadata, streamType) {
    var t = this;
    var _args = [];
    var _streamType = 1;
    var _iso8601ReleaseDate = "";

    if(mediaUrl == undefined || mediaType == undefined || metadataType == undefined || metadata == undefined){
        Promise.reject("missing parameters");
    }

    if(streamType != undefined){
        _streamType = streamType;
    }

    //check if a releaseDate has been provided
    if(metadata.releaseDate != undefined){
        var _inputLength = metadata.releaseDate.length;

        //ignore incomplete release date
        if(_inputLength < 4){
            _iso8601ReleaseDate = undefined;
        }else{
            //handle a full releaseDate
            if(_inputLength == 8){
                var _year = metadata.releaseDate.substring(0,4);
                var _month = metadata.releaseDate.substring(4,6);
                var _day = metadata.releaseDate.substring(6,8);
                var _date = new Date(_year, _month, _day, "00");
                _iso8601ReleaseDate = _date.toISOString();
            //handle year only release date
            } else if(_inputLength == 4){
                var _year = metadata.releaseDate.substring(0,4);
                var _date = new Date(_year, "00", "00", "00");
                _iso8601ReleaseDate = _date.toISOString();
            //handle any other scenario of incorrect or incomplete data
            } else {
                _iso8601ReleaseDate = undefined;
            }
        }
    }

    //Assign common values
    _args[0] = mediaUrl;
    _args[1] = mediaType;
    _args[2] = metadataType;
    _args[3] = _streamType;

    //generic metadata
    if(metadataType == 0){
        console.log("gck generic type");
        //reject if metadata missing
        if(metadata.title == undefined){
            Promise.reject("metadata title is required for generic media");
        }
        //assign metadata to args
        _args[4] = metadata.title;
        _args[5] = metadata.subtitle;
        _args[6] = metadata.image;
    }

    //movie metadata
    if(metadataType == 1){

        //reject if metadata missing
        if(metadata.title == undefined){
            Promise.reject("metadata title is required for movie media");
        }
        //assign metadata to args
        _args[4] = metadata.title;
        _args[5] = metadata.subtitle;
        _args[6] = metadata.image;
        _args[7] = _iso8601ReleaseDate;
        _args[8] = metadata.studio;
    }
    //tv show metadata
    if(metadataType == 2){

        //reject if metadata missing
        if(metadata.title == undefined){
            Promise.reject("metadata title is required for tv show media");
        }
        //assign metadata to args
        _args[4] = metadata.title;
        _args[5] = metadata.seriesTitle;
        _args[6] = metadata.image;
        _args[7] = _iso8601ReleaseDate;
        _args[8] = metadata.episodeNumber;
        _args[9] = metadata.seasonNumber;
    }
    //musictrack metadata
    if(metadataType == 3){

        //reject if metadata missing
        if(metadata.title == undefined){
            Promise.reject("metadata title is required for music track media");
        }
        //assign metadata to args
        _args[4] = metadata.title;
        _args[5] = metadata.albumTitle;
        _args[6] = metadata.image;
        _args[7] = metadata.artist;
        _args[8] = metadata.albumArtist;
        _args[9] = metadata.trackNumber;
    }
    //photo metadata
    if(metadataType == 4){

        //reject if metadata missing
        if(metadata.title == undefined){
            Promise.reject("metadata title is required for photo media");
        }
        //assign metadata to args
        _args[4] = metadata.title;
        _args[5] = metadata.locationName;
        _args[6] = metadata.artist;
    }

    return new Promise(function(resolve, reject){

        cordova.exec(function(response){
            var _response = response;
            resolve(_response);
        }, function(error){
            var _error = error;
            reject(_error);
        }, "FWChromecast", "loadMedia", _args);
    })
};

/**
 * Play the current media item on the default media channel.
 */
exports.playMedia = function () {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "playMedia", []);
    return this;
};

/**
 * Pause the current media item on the default media channel.
 */
exports.pauseMedia = function () {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "pauseMedia", []);
    return this;
};

/**
 * Stop the current media item on the default media channel.
 */
exports.stopMedia = function () {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "stopMedia", []);
    return this;
};

/**
 * Mute (or unmute) the current media item on the default media channel.
 *
 * @param mute, to mute or not to mute the media item
 */
exports.muteMedia = function (mute) {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "muteMedia", [mute]);
    return this;
};

/**
 * Seek the current media item on the default media channel to a time-position.
 *
 * @param seektime, the time to seek to
 */
exports.seekMedia = function (seektime) {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "seekMedia", [seektime]);
    return this;
};

/**
 * Set the volume for the current media item on the default media channel.
 *
 * @param volume, audo volume between 0 and 1 (e.g. 0.35)
 */
exports.setVolumeForMedia = function (volume) {
    cordova.exec(undefined, this.unhandledException, "FWChromecast", "setVolumeForMedia", [volume]);
    return this;
};

/**
 * Get the playback position of the current media
 */
exports.getPosition = function () {
    var t = this;

    return new Promise(function(resolve, reject) {
        cordova.exec(function (response) {
            var _position = response;
            resolve(_position);
        }, function(error){
            reject(error);
        }, "FWChromecast", "getPosition", []);
    })
};

/**
 * Get the current status of the channel
 * 0 = no channel connected
 * any positive int = channel connected (increments each change)
 */
exports.getChannelStatus = function () {
    var t = this;

    return new Promise(function(resolve, reject) {
        cordova.exec(function (response) {
            var _channelStatus = response;
            resolve(_channelStatus);
        }, function(error){
            reject(error);
        }, "FWChromecast", "getChannelStatus", []);
    })
};

/**
 * Get the current status of the media
 */
exports.getMediaStatus = function () {
    var t = this;

    return new Promise(function(resolve, reject) {
        cordova.exec(function (response) {
            var _mediaStatus = response;
            resolve(_mediaStatus);
        }, function(error){
            reject(error);
        }, "FWChromecast", "getMediaStatus", []);
    })
};
