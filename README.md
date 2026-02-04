# react-native-nordic-dfu (Fork)

This is a community-maintained fork of the original `react-native-nordic-dfu` library.

> ⚠️ **Warning!** The original library is no longer actively maintained. This fork aims to provide ongoing support and updates.

This library allows you to perform a Device Firmware Update (DFU) of your nRF51 or nRF52 chip from Nordic Semiconductor. It works for both iOS and Android.

For more info about the DFU process, see: [Resources](#resources)

## Installation

Install the NPM package per usual with:

```bash
npm install --save @ner7yn/react-native-nordic-dfu
```

If you are using React Native version below 0.60, you might need to link the package:

```bash
react-native link react-native-nordic-dfu
```

### Minimum requirements

This project has been verified to work with the following dependencies, though other versions may work as well. Please refer to the `package.json` and other configuration files in this repository for the most up-to-date requirements.

| Dependency   | Version |
| ------------ | ------- |
| React Native | 0.59.4  |
| XCode        | 10.2    |
| Swift        | 5.0     |
| CocoaPods    | 1.6.1   |
| Gradle       | 5.3.1   |

### iOS

The iOS version of this library has native dependencies that need to be installed via `CocoaPods`, which is currently the only supported method for installing this library.

On your project directory;

```bash
cd ios && pod install
```

If your React Native version is below 0.60 or any problem occurs on pod command, you can try these steps;

Add the following to your `Podfile`:

```ruby
target "YourApp" do
  # ...
  pod "react-native-nordic-dfu", path: "../node_modules/react-native-nordic-dfu"
  # ...
end
```

and in the same folder as the `Podfile` run:

```bash
pod install
```

Since there's native Swift dependencies you need to set which Swift version your project complies with. If you haven't already done this, open up your project with XCode and add a User-Defined setting under Build Settings: `SWIFT_VERSION = <your-swift-version>`.

If your React Native version is higher than 0.60, probably it's already there.

#### Bluetooth integration

This library needs access to an instance of `CBCentralManager`, which you most likely will have instantiated already if you're using Bluetooth for other purposes than DFU in your project.

To integrate with your existing Bluetooth setup, call `[RNNordicDfu setCentralManagerGetter:<...>]` with a block argument that returns your `CBCentralManager` instance.

If you want control over the `CBCentralManager` instance after the DFU process is done you might need to provide the `onDFUComplete` and `onDFUError` callbacks to transfer back delegate control.

Example code:

```objective-c
// ...
// ...
#import "RNNordicDfu.h"
#import "BleManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
  // ...
  // ...

    [RNNordicDfu setCentralManagerGetter:^() {
    return [BleManager getCentralManager];
  }];

  // Reset manager delegate since the Nordic DFU lib "steals" control over it
  [RNNordicDfu setOnDFUComplete:^() {
    NSLog(@"onDFUComplete");
    CBCentralManager * manager = [BleManager getCentralManager];
    manager.delegate = [BleManager getInstance];
  }];

  [RNNordicDfu setOnDFUError:^() {\
    NSLog(@"onDFUError");
    CBCentralManager * manager = [BleManager getCentralManager];
    manager.delegate = [BleManager getInstance];
  }];

  return YES;
}
```

You can find them also in example project.

On iOS side this library requires the `BleManager` module, which `react-native-ble-manager` provides.

It is required because:

*   You need `BleManager.h` module on `AppDelegate` file for integration.
*   You should call `BleManager.start()` (for once) before triggering a DFU process on iOS, or you will get an error like [this issue](https://github.com/Pilloxa/react-native-nordic-dfu/issues/82).

### Android

Android requires that you have `FOREGROUND_SERVICE` permissions. You will need the following in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## API

### startDFU

Starts the DFU process

**Observe:** The peripheral must have been discovered by the native BLE side so that the bluetooth stack knows about it. This library will not do a scan but only the actual connect and then the transfer. See the example project to see how it can be done in React Native.

**Parameters**

*   `obj` **[Object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/Object)**
    *   `obj.deviceAddress` **[string](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/String)** The ```identifier```\* of the device that should be updated
    *   `obj.deviceName` **[string](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/String)** The name of the device in the update notification (optional, default `null`)
    *   `obj.filePath` **[string](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/String)** The file system path to the zip-file used for updating
    *   `obj.alternativeAdvertisingNameEnabled` **[boolean](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/Boolean)** Send unique name to device before it is switched into bootloader mode (iOS only) - defaults to `true`

\* `identifier` — MAC address (Android) / UUID (iOS)

**Examples**

```javascript
import { RNNordicDFU, DFUEmitter } from "react-native-nordic-dfu";

RNNordicDFU.startDFU(
  deviceAddress,
  deviceName,
  filePath,
)
  .then((res) => console.log("Transfer done:", res))
  .catch(console.log);
```

Returns **[Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global%5FObjects/Promise)** A promise that resolves or rejects with the `deviceAddress` in the return value

### DFUEmitter

Event emitter for DFU state and progress events

**Examples**

```javascript
import { RNNordicDFU, DFUEmitter } from "react-native-nordic-dfu";

DFUEmitter.addListener(
  "DFUProgress",
  ({ percent, currentPart, partsTotal, avgSpeed, speed }) => {
    console.log("DFU progress: " + percent + "%");
  }
);

DFUEmitter.addListener("DFUStateChanged", ({ state }) => {
  console.log("DFU State:", state);
});
```

## Selecting firmware file from local storage

If your user will select the firmware file from local storage you should keep in mind some issues;

You can use [react-native-document-picker](https://github.com/Elyx0/react-native-document-picker) library for file selecting process.

### On iOS

You should select file type as `public.archive` or you will get null type error as like [this issue](https://github.com/Pilloxa/react-native-nordic-dfu/issues/100)

```javascript
DocumentPicker.pick({ type: "public.archive" });
```

If your device is getting disconnected after enabling DFU, you should set `false` value to `alternativeAdvertisingNameEnabled` prop while starting DFU.

```javascript
RNNordicDFU.startDFU(
  deviceAddress = "XXXXXXXX-XXXX-XXXX-XXXX-XX",
  filePath = firmwareFile.uri,
  alternativeAdvertisingNameEnabled = false,
);
```

### On Android

Some Android versions directly selecting files may cause errors. If you get any file error, you should copy it to your local storage. Like cache directory.

You can use [react-native-fs](https://github.com/itinance/react-native-fs) for copying file.

```javascript
const firmwareFile = await DocumentPicker.pick({ type: DocumentPicker.types.zip });
const destination = RNFS.CachesDirectoryPath + "/firmwareFile.zip";

await RNFS.copyFile(formatFile.uri, destination);

RNNordicDFU.startDFU( deviceAddress = "XX:XX:XX:XX:XX:XX", filePath = destination);
```

If you get a disconnect error sometimes while starting the DFU process, you should connect to the device before starting it.

## Example project

Navigate to `example/` and run

```bash
npm install
```

Run the iOS project with

```bash
react-native run-ios
```

and the Android project with

```bash
react-native run-android
```

## Development

PR's are always welcome!

## Resources

*   [DFU Introduction](http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v11.0.0/examples%5Fble%5Fdfu.html?cp=6%5F0%5F0%5F4%5F3%5F1 "BLE Bootloader/DFU")
*   [Secure DFU Introduction](http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v12.0.0/ble%5Fsdk%5Fapp%5Fdfu%5Fbootloader.html?cp=4%5F0%5F0%5F4%5F3%5F1 "BLE Secure DFU Bootloader")
*   [How to create init packet](https://github.com/NordicSemiconductor/Android-nRF-Connect/tree/master/init%20packet%20handling "Init packet handling")
*   [nRF51 Development Kit (DK)](http://www.nordicsemi.com/eng/Products/nRF51-DK "nRF51 DK") (compatible with Arduino Uno Revision 3)
*   [nRF52 Development Kit (DK)](http://www.nordicsemi.com/eng/Products/Bluetooth-Smart-Bluetooth-low-energy/nRF52-DK "nRF52 DK") (compatible with Arduino Uno Revision 3)

## Sponsored by

Original library sponsored by Pilloxa:

[![pilloxa](https://camo.githubusercontent.com/3050e296c05f12295290b8db5a2afb266b8bfadf645eaa06f9713ca1459f076d/68747470733a2f2f70696c6c6f78612e636f6d2f696d616765732f70696c6c6f78612d726f756e642d6c6f676f2e737667)](https://pilloxa.com/)
