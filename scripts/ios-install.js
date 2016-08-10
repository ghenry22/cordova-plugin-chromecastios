var exec = require('child_process').exec,
	path = require('path'),
	fs = require('fs'),
	request = require('request'),
	http = require('http'),
	https = require('https'),
	isMac = /^darwin/.test(process.platform),
	Q = require('q'),
	csdkDirectory;

if (!isMac) {
	console.log('iOS development is only supported on Mac OS X system, cowardly refusing to install the plugin');
} else {
	var commands = {
		rm: "rm",
		rmRF: "rm -rf",
		cp: "cp",
		mv: "mv",
		touch: "touch"
	};

	var paths = {
		"GoogleCastSDK_URL": "https://developers.google.com/cast/downloads/GoogleCastSDK-Public-3.1.1-Release-ios.zip",
		"GoogleCast_Framework": "./tmp/GoogleCastSDK-Public-3.1.1-Release/GoogleCast.framework"
	};

	function safePath(unsafePath) {
		return path.join(process.cwd(), "./platforms/ios/", unsafePath);
	}

	function iOSInstall() {}

	iOSInstall.prototype.steps = [
		"createTemporaryDirectory",
		"downloadGoogleCastSDK",
		"cleanup"
	];

	iOSInstall.prototype.start = function () {
		console.log("Starting cordova-plugin-chromecastios install, fetching castSDK");

		var self = this;

		self.executeStep(0);
	};

	iOSInstall.prototype.executeStep = function (step) {
		var self = this;
		if (step < this.steps.length) {
			var promise = this[this.steps[step]]();
			promise.then(function () {
				self.executeStep(step + 1);
			}, function (err) {
				console.log("Encountered an error, reverting install steps");
				console.error(err);
				self.revertStep(step);
			});
		} else {
			console.log("cordova-plugin-chromecastios iOS install finished");
		}
	};

	iOSInstall.prototype.revertStep = function (step) {
		var self = this;
		if (this.currentStep < this.steps.length) {
			var promise = this["revert_" + this.steps[step]]();
			promise.then(function () {
				self.revertStep(step - 1);
			}, function () {
				console.error("An error occured while reverting the install.");
			});
		} else {
			console.log("cordova-plugin-chromecastios iOS install reverted");
		}
	};

	iOSInstall.prototype.createTemporaryDirectory = function () {
		return Q.nfcall(fs.readdir, safePath("./"))
			.then(function (files) {
			for (var i = 0; i < files.length; i++) {
				if (files[i].indexOf('.xcodeproj') !== -1) {
					csdkDirectory = "./" + files[i].substring(0, files[i].indexOf('.xcodeproj')) + "/Plugins/cordova-plugin-chromecastios";
					console.log("created temp dir");
					return Q.nfcall(fs.mkdir, safePath('./tmp'));
				}
			}
			return Q.reject("Could not find cordova-plugin-chromecastios plugin directory");
		});
	};

	iOSInstall.prototype.revert_createTemporaryDirectory = function () {
		return Q.nfcall(exec, commands.rmRF + " " + safePath("./tmp"));
	};

	iOSInstall.prototype.downloadGoogleCastSDK = function () {
		var deferred = Q.defer();
		console.log("Downloading GoogleCast SDK");
		var file = fs.createWriteStream(safePath("./tmp/GoogleCastSDK.zip"));
		https.get(paths.GoogleCastSDK_URL, function(response) {
			response.pipe(file).on('close', function () {
				console.log('Extracting GoogleCast SDK');
				Q.nfcall(exec, "unzip -q " + safePath("./tmp/GoogleCastSDK.zip") + " -d " + safePath('./tmp'))
					.then(function () {
					return Q.nfcall(exec, commands.rm + " " + safePath(csdkDirectory + "/GoogleCast.framework"));
				})
					.then(function () {
					return Q.nfcall(exec, commands.mv + " " + safePath(paths.GoogleCast_Framework) + " " + safePath(csdkDirectory + "/GoogleCast.framework"));
				})
					.then(function () {
					deferred.resolve();
				})
					.catch(function (err) {
					deferred.reject(err);
				});
			});
		}).on('error', function (err) {
			deferred.reject(err);
		});

		return deferred.promise;
	};

	iOSInstall.prototype.revert_downloadGoogleCastSDK = function () {
		return Q.nfcall(exec, commands.rm + safePath(csdkDirectory + "/GoogleCast.framework"))
			.then(function () {
			return Q.nfcall(exec, commands.touch + safePath(csdkDirectory + "/GoogleCast.framework"));
		});
	};

	iOSInstall.prototype.cleanup = function () {
		console.log("Cleaning up");
		return this.revert_createTemporaryDirectory();
	};

	iOSInstall.prototype.revert_cleanup = function () {
		return Q.resolve();
	};

	new iOSInstall().start();
}