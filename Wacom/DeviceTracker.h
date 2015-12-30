/*----------------------------------------------------------------------------

FILE NAME

DeviceTracker.h - Header file for the DeviceTracker and Transducer classes.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/
#import <Cocoa/Cocoa.h>

@interface Transducer : NSObject {
   UInt16 ident;
   NSColor	*mColor;
}

-(Transducer *) initWithIdent:(UInt16)newIdent color:(NSColor *) newColor;
-(UInt16) ident;
-(NSColor *) color;
-(void) setColor:(NSColor *) newColor;

@end

@interface DeviceTracker : NSObject {
   Transducer *currentDevice;
   NSMutableArray *deviceList;
}

-(BOOL) setCurrentDeviceByID:(UInt16) deviceIdent;
-(Transducer *) currentDevice;
-(void) addDevice:(Transducer *) newDevice;
@end
