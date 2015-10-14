//
//  BPAppDelegate.m
//  BLEPeripheral
//  http://pastebin.com/PLcEA4dd based on https://github.com/sandeepmistry/osx-ble-peripheral
//  https://developer.apple.com/library/mac/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonPeripheralRoleTasks/PerformingCommonPeripheralRoleTasks.html
 
#import <objc/runtime.h>
#import <objc/message.h>
 
#import "BPAppDelegate.h"
 
@interface CBXpcConnection : NSObject //{
//    <CBXpcConnectionDelegate> *_delegate;
//    NSRecursiveLock *_delegateLock;
//    NSMutableDictionary *_options;
//    NSObject<OS_dispatch_queue> *_queue;
//    int _type;
//    NSObject<OS_xpc_object> *_xpcConnection;
//    NSObject<OS_dispatch_semaphore> *_xpcSendBarrier;
//}
//
//@property <CBXpcConnectionDelegate> * delegate;
 
 
- (id)allocXpcArrayWithNSArray:(id)arg1;
- (id)allocXpcDictionaryWithNSDictionary:(id)arg1;
- (id)allocXpcMsg:(int)arg1 args:(id)arg2;
- (id)allocXpcObjectWithNSObject:(id)arg1;
- (void)checkIn;
- (void)checkOut;
- (void)dealloc;
- (id)delegate;
- (void)disconnect;
- (void)handleConnectionEvent:(id)arg1;
- (void)handleInvalid;
- (void)handleMsg:(int)arg1 args:(id)arg2;
- (void)handleReset;
- (id)initWithDelegate:(id)arg1 queue:(id)arg2 options:(id)arg3 sessionType:(int)arg4;
- (BOOL)isMainQueue;
- (id)nsArrayWithXpcArray:(id)arg1;
- (id)nsDictionaryFromXpcDictionary:(id)arg1;
- (id)nsObjectWithXpcObject:(id)arg1;
- (void)sendAsyncMsg:(int)arg1 args:(id)arg2;
- (void)sendMsg:(int)arg1 args:(id)arg2;
- (id)sendSyncMsg:(int)arg1 args:(id)arg2;
- (void)setDelegate:(id)arg1;
 
@end
 
int ProtocolValue = 0;
char reportValue = 0x00;
 
@implementation CBXpcConnection (Swizzled)
 
- (void)sendMsg1:(int)arg1 args:(id)arg2
{
    NSLog(@"sendMsg: %d, %@", arg1, arg2);
   
    if ([self respondsToSelector:@selector(sendMsg1:args:)]) {
        [self sendMsg1:arg1 args:arg2];
    }
}
 
- (void)handleMsg1:(int)arg1 args:(id)arg2
{
    NSLog(@"handleMsg: %d, %@", arg1, arg2);
   
    if ([self respondsToSelector:@selector(handleMsg1:args:)]) {
        [self handleMsg1:arg1 args:arg2];
    }
}
 
@end
 
@interface BPAppDelegate ()
 
@property (weak) IBOutlet NSButton *btnReadConnections;
@property (weak) IBOutlet NSButton *btnReportValue;
 
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *service;
 
@end
 
 
@implementation BPAppDelegate
 
// BUTTONS
- (IBAction)readConnections:(NSButton *)sender {
    NSLog(@"Read connections");
    NSArray *devices = [IOBluetoothDevice recentDevices:5];
   
    for(IOBluetoothDevice *device in devices) {
        NSLog(@"* device: %@, status %hhd, address: %@",device.nameOrAddress,device.isConnected,device.addressString);
        if(device && [device isConnected]){
            // [device closeConnection];
            NSLog(@"* value: %@",device.nameOrAddress);
        }
    }
}
 
- (IBAction)changeReportValue:(NSButton *)sender {
    if (reportValue == 0x00) {
        reportValue = 0x40;
    } else {
        reportValue = 0x00;
    }
}
 
 
// #define XPC_SPY 1
 
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#ifdef XPC_SPY
    // Insert code here to initialize your application
    Class xpcConnectionClass = NSClassFromString(@"CBXpcConnection");
   
    Method origSendMethod = class_getInstanceMethod(xpcConnectionClass,  @selector(sendMsg:args:));
    Method newSendMethod = class_getInstanceMethod(xpcConnectionClass, @selector(sendMsg1:args:));
   
    method_exchangeImplementations(origSendMethod, newSendMethod);
   
    Method origHandleMethod = class_getInstanceMethod(xpcConnectionClass,  @selector(handleMsg:args:));
    Method newHandleMethod = class_getInstanceMethod(xpcConnectionClass, @selector(handleMsg1:args:));
   
    method_exchangeImplementations(origHandleMethod, newHandleMethod);
#endif
   
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}
 
 
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %d", (int)peripheral.state);
   
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
   
        char value[23] = {0x57,0x01,0x00,0xD5,0xF6,0xC6,0x19,0x17,0x1A,0x4B,0x50,0xAE,0x0F,0xF0,0x2C,0xD5,0x5C,0x02,0x88,0x10,0x5E,0xAB,0xC0};
        NSData *manufacturerDataKey = [[NSData alloc] initWithBytes:value length:sizeof(value)];
       
        [peripheral startAdvertising:@{
                                       CBAdvertisementDataLocalNameKey: @"XiaoYi_RC",
                                       CBAdvertisementDataManufacturerDataKey: manufacturerDataKey,
                                       CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:@"00001800-0000-1000-8000-00805f9b34fb"]]
                                       }];
       
 
        // Device Information Service
        // https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.device_information.xml
        //    Firmware Revision String
        NSData *valFirmwareRevision = [@"v20_0.1.8_s915" dataUsingEncoding:NSUTF8StringEncoding];
        CBMutableCharacteristic *characteristicFirmwareRevision = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a26-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valFirmwareRevision permissions:CBAttributePermissionsReadable];
       
        //    Software Revision String
        NSData *valSoftwareRevision = [@"v20_0.1.8_s915" dataUsingEncoding:NSUTF8StringEncoding];
        CBMutableCharacteristic *characteristicSoftwareRevision = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a28-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valSoftwareRevision permissions:CBAttributePermissionsReadable];
 
        //    System ID
        NSData *valSystemID = nil;
        CBMutableCharacteristic *characteristicSystemID = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a23-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valSystemID permissions:CBAttributePermissionsReadable];
 
        //    PNP IP
        NSData *valPNPID = nil;
        CBMutableCharacteristic *characteristicPNPID = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a50-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valPNPID permissions:CBAttributePermissionsReadable];
       
        CBMutableService *serviceDeviceInformation = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"0000180a-0000-1000-8000-00805f9b34fb"] primary:YES];
        serviceDeviceInformation.characteristics = @[characteristicFirmwareRevision, characteristicSoftwareRevision, characteristicSystemID, characteristicPNPID];
       
        // Generic Access Service
        // https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.generic_access.xml
        //     Peripheral Privacy Flag
        NSData *valPeripheralPrivacyFlag = nil;
        CBMutableCharacteristic *characteristicPeripheralPrivacyFlag = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a02-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valPeripheralPrivacyFlag permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
 
        //     Peripheral Connect Paras
        NSData *valPeripheralConnectParas = nil;
        CBMutableCharacteristic *characteristicPeripheralConnectParas = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a04-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valPeripheralConnectParas permissions:CBAttributePermissionsReadable];
       
        CBMutableService *serviceGenericAccess = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"00001800-0000-1000-8000-00805f9b34fb"] primary:YES];
        serviceGenericAccess.characteristics = @[characteristicPeripheralPrivacyFlag, characteristicPeripheralConnectParas];
       
        // Human Interface Device
        // https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.human_interface_device.xml
        //    HID Information
        NSData *valHIDInformation = nil;
        CBMutableCharacteristic *characteristicHIDInformation = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4a-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valHIDInformation permissions:CBAttributePermissionsReadable];
       
        //    HID Control Point
        NSData *valHIDControlPoint = nil;
        CBMutableCharacteristic *characteristicHIDControlPoint = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4c-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyWriteWithoutResponse value:valHIDControlPoint permissions:CBAttributePermissionsReadable];
       
        //    Report Map
        NSData *valReportMap = nil;
        CBMutableCharacteristic *characteristicReportMap = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4b-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead value:valReportMap permissions:CBAttributePermissionsReadable];
       
        //    Protocol Mode
        NSData *valProtocolMode = nil;
        CBMutableCharacteristic *characteristicProtocolMode = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4e-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead+CBCharacteristicPropertyWriteWithoutResponse value:valProtocolMode permissions:CBAttributePermissionsReadable];
       
        //    Boot Keyboard Input Report
        NSData *valBootKeyboardInputReport = nil;
        CBMutableCharacteristic *characteristicBootKeyboardInputReport = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a22-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyNotify+CBCharacteristicPropertyRead+CBCharacteristicPropertyWrite value:valBootKeyboardInputReport permissions:CBAttributePermissionsReadable];
       
        //    Boot Keyboard Output Report
        NSData *valBootKeyboardOutputReport = nil;
        CBMutableCharacteristic *characteristicBootKeyboardOutputReport = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a32-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead+CBCharacteristicPropertyWrite+CBCharacteristicPropertyWriteWithoutResponse value:valBootKeyboardOutputReport permissions:CBAttributePermissionsReadable];
       
        //    Report
        NSData *valReport1 = nil;
        CBMutableCharacteristic *characteristicReport1 = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4d-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead+CBCharacteristicPropertyWrite+CBCharacteristicPropertyNotify value:valReport1 permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
 
//        NSData *valReport2 = nil;
//        CBMutableCharacteristic *characteristicReport2 = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4d-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead+CBCharacteristicPropertyWrite+CBCharacteristicPropertyWriteWithoutResponse value:valReport2 permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
 
//        NSData *valReport3 = nil;
//        CBMutableCharacteristic *characteristicReport3 = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00002a4d-0000-1000-8000-00805f9b34fb"] properties:CBCharacteristicPropertyRead+CBCharacteristicPropertyWrite+CBCharacteristicPropertyNotify value:valReport3 permissions:CBAttributePermissionsReadable |CBAttributePermissionsWriteable];
       
       
        CBMutableService *serviceHumanInterfaceDevice = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"00001812-0000-1000-8000-00805f9b34fb"] primary:YES];
        serviceHumanInterfaceDevice.characteristics = @[characteristicHIDInformation, characteristicHIDControlPoint, characteristicReportMap, characteristicProtocolMode, characteristicBootKeyboardInputReport, characteristicBootKeyboardOutputReport, characteristicReport1];
       
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"00001800-0000-1000-8000-00805f9b34fb"] primary:YES];
        self.service.includedServices = @[serviceGenericAccess, serviceDeviceInformation, serviceHumanInterfaceDevice];
       
        [self.peripheralManager addService:serviceGenericAccess];
        [self.peripheralManager addService:serviceDeviceInformation];
        [self.peripheralManager addService:serviceHumanInterfaceDevice];
        [self.peripheralManager addService:self.service];
 
 
    } else {
        [peripheral stopAdvertising];
        [peripheral removeAllServices];
    }
}
 
 
 
 
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
   
    NSLog(@"* peripheralManager:didReceiveWriteRequests:");
   
    for(CBATTRequest *request in requests){
        NSLog(@"* UUID: %@",request.characteristic.UUID);
        NSLog(@"* value: %@",request.value);
       
    }
   
}
 
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
   
    NSLog(@"Central subscribed to characteristic %@", characteristic);
   
}
 
 
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"- peripheralManager:didReceiveReadRequest:");
    NSLog(@"- UUID: %@",request.characteristic.UUID);
   
    if ([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:@"00002a4e-0000-1000-8000-00805f9b34fb"]]) { // Protocol Mode
        char value[1] = {0x01};
        NSData *valueSample = [[NSData alloc] initWithBytes:value length:1];
        request.value = valueSample;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else if ([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:@"00002a4a-0000-1000-8000-00805f9b34fb"]]) { // HID Information
        char value[4] = {0x00,0x01,0x00,0x00};
        NSData *valueSample = [[NSData alloc] initWithBytes:value length:4];
        request.value = valueSample;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else if ([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:@"00002a4d-0000-1000-8000-00805f9b34fb"]]) { // Report
        char value[3] = {reportValue,0x00,0x00};
        NSData *valueSample = [[NSData alloc] initWithBytes:value length:1];
        request.value = valueSample;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
   
}
 
 
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising: %@", error);
}
 
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"peripheralManagerDidAddService: %@ %@", service, error);
}
 
 
@end