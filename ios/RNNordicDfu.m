#import "RNNordicDfu.h"
#import <CoreBluetooth/CoreBluetooth.h>
@import iOSDFULibrary;

static CBCentralManager * (^getCentralManager)(void);
static void (^onDFUComplete)(void);
static void (^onDFUError)(void);

@implementation RNNordicDfu

RCT_EXPORT_MODULE();

NSString * const DFUProgressEvent = @"DFUProgress";
NSString * const DFUStateChangedEvent = @"DFUStateChanged";

- (NSArray<NSString *> *)supportedEvents
{
  return @[DFUProgressEvent,
           DFUStateChangedEvent,];
}

- (NSString *)stateDescription:(enum DFUState)state
{
  switch (state)
  {
    case DFUStateAborted:
      return @"DFU_ABORTED";
    case DFUStateStarting:
      return @"DFU_PROCESS_STARTING";
    case DFUStateCompleted:
      return @"DFU_COMPLETED";
    case DFUStateUploading:
      return @"DFU_STATE_UPLOADING";
    case DFUStateConnecting:
      return @"CONNECTING";
    case DFUStateValidating:
      return @"FIRMWARE_VALIDATING";
    case DFUStateDisconnecting:
      return @"DEVICE_DISCONNECTING";
    case DFUStateEnablingDfuMode:
      return @"ENABLING_DFU_MODE";
    default:
      return @"UNKNOWN_STATE";
  }
}

- (NSString *)errorDescription:(enum DFUError)error
{
  switch(error)
  {
    case DFUErrorCrcError:
      return @"DFUErrorCrcError";
    case DFUErrorBytesLost:
      return @"DFUErrorBytesLost";
    case DFUErrorFileInvalid:
      return @"DFUErrorFileInvalid";
    case DFUErrorFailedToConnect:
      return @"DFUErrorFailedToConnect";
    case DFUErrorFileNotSpecified:
      return @"DFUErrorFileNotSpecified";
    case DFUErrorBluetoothDisabled:
      return @"DFUErrorBluetoothDisabled";
    case DFUErrorDeviceDisconnected:
      return @"DFUErrorDeviceDisconnected";
    case DFUErrorDeviceNotSupported:
      return @"DFUErrorDeviceNotSupported";
    case DFUErrorInitPacketRequired:
      return @"DFUErrorInitPacketRequired";
    case DFUErrorUnsupportedResponse:
      return @"DFUErrorUnsupportedResponse";
    case DFUErrorReadingVersionFailed:
      return @"DFUErrorReadingVersionFailed";
    case DFUErrorRemoteLegacyDFUSuccess:
      return @"DFUErrorRemoteLegacyDFUSuccess";
    case DFUErrorRemoteSecureDFUSuccess:
      return @"DFUErrorRemoteSecureDFUSuccess";
    case DFUErrorServiceDiscoveryFailed:
      return @"DFUErrorServiceDiscoveryFailed";
    case DFUErrorRemoteLegacyDFUCrcError:
      return @"DFUErrorRemoteLegacyDFUCrcError";
    case DFUErrorEnablingControlPointFailed:
      return @"DFUErrorEnablingControlPointFailed";
    case DFUErrorExtendedInitPacketRequired:
      return @"DFUErrorExtendedInitPacketRequired";
    case DFUErrorReceivingNotificationFailed:
      return @"DFUErrorReceivingNotificationFailed";
    case DFUErrorRemoteButtonlessDFUSuccess:
      return @"DFUErrorRemoteButtonlessDFUSuccess";
    case DFUErrorRemoteLegacyDFUInvalidState:
      return @"DFUErrorRemoteLegacyDFUInvalidState";
    case DFUErrorRemoteLegacyDFUNotSupported:
      return @"DFUErrorRemoteLegacyDFUNotSupported";
    case DFUErrorWritingCharacteristicFailed:
      return @"DFUErrorWritingCharacteristicFailed";
    case DFUErrorRemoteSecureDFUExtendedError:
      return @"DFUErrorRemoteSecureDFUExtendedError";
    case DFUErrorRemoteSecureDFUInvalidObject:
      return @"DFUErrorRemoteSecureDFUInvalidObject";
    case DFUErrorRemoteLegacyDFUOperationFailed:
      return @"DFUErrorRemoteLegacyDFUOperationFailed";
    case DFUErrorRemoteSecureDFUOperationFailed:
      return @"DFUErrorRemoteSecureDFUOperationFailed";
    case DFUErrorRemoteSecureDFUUnsupportedType:
      return @"DFUErrorRemoteSecureDFUUnsupportedType";
    case DFUErrorRemoteLegacyDFUDataExceedsLimit:
      return @"DFUErrorRemoteLegacyDFUDataExceedsLimit";
    case DFUErrorRemoteSecureDFUInvalidParameter:
      return @"DFUErrorRemoteSecureDFUInvalidParameter";
    case DFUErrorRemoteSecureDFUSignatureMismatch:
      return @"DFUErrorRemoteSecureDFUSignatureMismatch";
    case DFUErrorRemoteSecureDFUOpCodeNotSupported:
      return @"DFUErrorRemoteSecureDFUOpCodeNotSupported";
    case DFUErrorRemoteButtonlessDFUOperationFailed:
      return @"DFUErrorRemoteButtonlessDFUOperationFailed";
    case DFUErrorRemoteSecureDFUInsufficientResources:
      return @"DFUErrorRemoteSecureDFUInsufficientResources";
    case DFUErrorRemoteSecureDFUOperationNotPermitted:
      return @"DFUErrorRemoteSecureDFUOperationNotPermitted";
    case DFUErrorRemoteButtonlessDFUOpCodeNotSupported:
      return @"DFUErrorRemoteButtonlessDFUOpCodeNotSupported";
    case DFUErrorRemoteExperimentalButtonlessDFUSuccess:
      return @"DFUErrorRemoteExperimentalButtonlessDFUSuccess";
    case DFUErrorRemoteExperimentalButtonlessDFUOperationFailed:
      return @"DFUErrorRemoteExperimentalButtonlessDFUOperationFailed";
    case DFUErrorRemoteExperimentalButtonlessDFUOpCodeNotSupported:
      return @"DFUErrorRemoteExperimentalButtonlessDFUOpCodeNotSupported";
    default:
      return @"UNKNOWN_ERROR";
  }
}

- (void)dfuStateDidChangeTo:(enum DFUState)state
{
  NSDictionary * evtBody = @{@"deviceAddress": self.deviceAddress,
                             @"state": [self stateDescription:state],};

  [self sendEventWithName:DFUStateChangedEvent body:evtBody];

  if (state == DFUStateCompleted) {
    if (onDFUComplete) {
      onDFUComplete();
    }
    NSDictionary * resolveBody = @{@"deviceAddress": self.deviceAddress,};

    self.resolve(resolveBody);
    // Clean up
    self.resolve = nil;
    self.reject = nil;
    self.controller = nil;
  }
}

- (void)   dfuError:(enum DFUError)error
didOccurWithMessage:(NSString * _Nonnull)message
{
  if (onDFUError) {
    onDFUError();
  }

  NSDictionary * evtBody = @{@"deviceAddress": self.deviceAddress,
                             @"state": @"DFU_FAILED",};

  [self sendEventWithName:DFUStateChangedEvent body:evtBody];

  self.reject([self errorDescription:error], message, nil);
  // Clean up
  self.resolve = nil;
  self.reject = nil;
  self.controller = nil;
}

- (void)dfuProgressDidChangeFor:(NSInteger)part
                          outOf:(NSInteger)totalParts
                             to:(NSInteger)progress
     currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond
         avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond
{
  NSDictionary * evtBody = @{@"deviceAddress": self.deviceAddress,
                             @"currentPart": [NSNumber numberWithInteger:part],
                             @"partsTotal": [NSNumber numberWithInteger:totalParts],
                             @"percent": [NSNumber numberWithInteger:progress],
                             @"speed": [NSNumber numberWithDouble:currentSpeedBytesPerSecond],
                             @"avgSpeed": [NSNumber numberWithDouble:avgSpeedBytesPerSecond],};

  [self sendEventWithName:DFUProgressEvent body:evtBody];
}

- (void)logWith:(enum LogLevel)level message:(NSString * _Nonnull)message
{
  NSLog(@"logWith: %ld message: '%@'", (long)level, message);
}

RCT_EXPORT_METHOD(startDFU:(NSString *)deviceAddress
                  deviceName:(NSString *)deviceName
                  filePath:(NSString *)filePath
                  alternativeAdvertisingNameEnabled:(BOOL)alternativeAdvertisingNameEnabled
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  self.deviceAddress = deviceAddress;
  self.resolve = resolve;
  self.reject = reject;

  // 1. Проверка существования файла
  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    reject(@"FILE_NOT_FOUND", @"DFU file not found", nil);
    self.resolve = nil;
    self.reject = nil;
    return;
  }

  if (!getCentralManager) {
    reject(@"nil_central_manager_getter", @"Attempted to start DFU without central manager getter", nil);
    self.resolve = nil;
    self.reject = nil;
    return;
  }

  CBCentralManager * centralManager = getCentralManager();

  if (!centralManager) {
    reject(@"nil_central_manager", @"Call to getCentralManager returned nil", nil);
    self.resolve = nil;
    self.reject = nil;
    return;
  }

  if (!deviceAddress) {
    reject(@"nil_device_address", @"Attempted to start DFU with nil deviceAddress", nil);
    self.resolve = nil;
    self.reject = nil;
    return;
  }

  if (!filePath) {
    reject(@"nil_file_path", @"Attempted to start DFU with nil filePath", nil);
    self.resolve = nil;
    self.reject = nil;
    return;
  }

  @try {
    NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:deviceAddress];

    if (!uuid) {
      reject(@"invalid_device_address", @"Invalid device address format", nil);
      self.resolve = nil;
      self.reject = nil;
      return;
    }

    NSArray<CBPeripheral *> * peripherals = [centralManager retrievePeripheralsWithIdentifiers:@[uuid]];

    if ([peripherals count] != 1) {
      reject(@"unable_to_find_device", @"Could not find device with deviceAddress", nil);
      self.resolve = nil;
      self.reject = nil;
      return;
    }

    CBPeripheral * peripheral = [peripherals objectAtIndex:0];
    
    // Используем fileURLWithPath вместо URLWithString для корректного создания file URL
    NSURL * url = [NSURL fileURLWithPath:filePath];

    // 2. Обработка ошибок при создании firmware
    DFUFirmware * firmware;
    @try {
      firmware = [[DFUFirmware alloc] initWithUrlToZipFile:url];
    } @catch (NSException *exception) {
      reject(@"FIRMWARE_CREATION_FAILED", [NSString stringWithFormat:@"Failed to create firmware: %@", exception.reason], nil);
      self.resolve = nil;
      self.reject = nil;
      return;
    }

    if (!firmware) {
      reject(@"FIRMWARE_CREATION_FAILED", @"Failed to create firmware object", nil);
      self.resolve = nil;
      self.reject = nil;
      return;
    }

    DFUServiceInitiator * initiator = [[[DFUServiceInitiator alloc]
                                        initWithCentralManager:centralManager
                                        target:peripheral]
                                       withFirmware:firmware];

    initiator.logger = self;
    initiator.delegate = self;
    initiator.progressDelegate = self;
    initiator.alternativeAdvertisingNameEnabled = alternativeAdvertisingNameEnabled;

    // 3. Проверка успешного запуска DFU
    DFUServiceController * controller = [initiator start];
    
    if (controller) {
      self.controller = controller; // Сохраняем контроллер для возможной отмены
      // Не резолвим промис здесь - он резолвится когда DFU завершится
      NSLog(@"DFU service started successfully for device: %@", deviceAddress);
    } else {
      reject(@"START_FAILED", @"Failed to start DFU service - controller is nil", nil);
      self.resolve = nil;
      self.reject = nil;
    }

  } @catch (NSException *exception) {
    reject(@"DFU_START_ERROR", [NSString stringWithFormat:@"Failed to start DFU: %@", exception.reason], nil);
    self.resolve = nil;
    self.reject = nil;
  }
}

RCT_EXPORT_METHOD(abortDFU:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (self.controller) {
    [self.controller abort];
    resolve(@(YES));
  } else {
    resolve(@(NO));
  }
}

+ (void)setCentralManagerGetter:(CBCentralManager * (^)(void))getter
{
  getCentralManager = getter;
}

+ (void)setOnDFUComplete:(void (^)(void))onComplete
{
  onDFUComplete = onComplete;
}

+ (void)setOnDFUError:(void (^)(void))onError
{
  onDFUError = onError;
}

@end