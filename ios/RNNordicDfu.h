#import <CoreBluetooth/CoreBluetooth.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
@import iOSDFULibrary;

@interface RNNordicDfu : RCTEventEmitter<RCTBridgeModule, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate>

@property (strong, nonatomic) NSString *deviceAddress;
@property (nonatomic, copy) RCTPromiseResolveBlock resolve;
@property (nonatomic, copy) RCTPromiseRejectBlock reject;
@property (strong, nonatomic) DFUServiceController *controller;

+ (void)setCentralManagerGetter:(CBCentralManager * (^)(void))getter;
+ (void)setOnDFUComplete:(void (^)(void))onComplete;
+ (void)setOnDFUError:(void (^)(void))onError;

@end